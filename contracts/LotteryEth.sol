// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "hardhat/console.sol";

contract LotteryEth is Ownable, Pausable, VRFConsumerBase {
    bytes32 private s_keyHash;
    uint256 private s_fee;

    struct Record {
        uint256 amount;
        address user;
        uint32 date;
    }

    // HISTORICAL
    Record[] public records;

    // LOTTERY
    mapping(address => uint256) public ticketsForUser;
    uint256 public totalPool;
    address[] private tickets;

    // USERS
    uint256 public ticketValue;
    address[] public users;
    mapping(address => bool) private hasTickets;
    mapping(address => uint256) private rewards;

    event Winner(uint256 indexed indexRandom, address indexed result);

    // MODIFIER
    modifier onlyUser() {
        require(msg.sender != owner(), "LotteryEth: does not have permissions");
        _;
    }

    // INIT
    constructor(
        address vrfCoordinator,
        address link,
        bytes32 keyHash,
        uint256 fee
    ) VRFConsumerBase(vrfCoordinator, link) {
        ticketValue = 0.01 ether;
        s_keyHash = keyHash;
        s_fee = fee;
    }

    // USERS
    function buyTicket(uint256 amount) external payable onlyUser whenNotPaused {
        require(amount != 0, "LotteryEth: can not get zero ticket");
        require(msg.value >= amount * ticketValue, "LotteryEth: amount can not be 0");
        totalPool += msg.value;
        for (uint256 i; i < amount; i++) {
            ticketsForUser[msg.sender]++;
            tickets.push(msg.sender);
        }
        if (!hasTickets[msg.sender]) {
            users.push(msg.sender);
            hasTickets[msg.sender] = true;
        }
    }

    function withdraw() external onlyUser whenNotPaused {
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "LotteryEth: it has no amount");
        rewards[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // OWNER
    function lookingForAWinner() external onlyOwner whenNotPaused returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= s_fee, "LotteryEth: not enough LINK - fill contract with faucet");
        require(tickets.length > 0, "LotteryEth: the number of tickets is zero");
        _pause();
        return requestRandomness(s_keyHash, s_fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 indexRandom = randomness % tickets.length;
        rewards[tickets[indexRandom]] += totalPool;
        records.push(Record(totalPool, tickets[indexRandom], uint32(block.timestamp)));
        emit Winner(indexRandom, tickets[indexRandom]);
    }

    function reset() public onlyOwner whenPaused {
        totalPool = 0;
        for (uint256 i; i < users.length; i++) {
            delete ticketsForUser[users[i]];
            delete hasTickets[users[i]];
        }
        delete tickets;
        delete users;
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // SETTERS
    function setTicketValue(uint256 value) external onlyOwner() {
        ticketValue = value;
    }

    // GETTERS
    function getReward() public view returns (uint256) {
        return rewards[msg.sender];
    }

    function getNumberOfUsers() external view returns (uint256) {
        return users.length;
    }

    function getUsers() external view returns (address[] memory) {
        return users;
    }

    function getTicketsForUser() external view onlyUser returns (uint256) {
        return ticketsForUser[msg.sender];
    }

    function getNumberOfTickets() external view returns (uint256) {
        return tickets.length;
    }

    function getNumberOfRecord() external view returns (uint256) {
        return records.length;
    }
}