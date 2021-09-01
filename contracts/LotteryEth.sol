// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract LotteryEth is Ownable, VRFConsumerBase {

    enum State {
        LOCKED,
        UNLOCKED
    }

    bytes32 private s_keyHash;
    uint256 private s_fee;
    State public state;

    struct Record {
        uint256 amount;
        address user;
        uint32 date;
    }

    uint256 public ticketValue;
    Record[] public records;

    mapping(address => uint256) private rewards;
    mapping(address => uint256) public ticketsForStaker;
    uint256 public totalPool;
    address[] private tickets;

    address[] public stakers;
    mapping(address => bool) private hasStaked;

    event Winner(uint256 indexed indexRandom, address indexed result);

    constructor(address vrfCoordinator, address link, bytes32 keyHash, uint256 fee) VRFConsumerBase(vrfCoordinator, link) {
        ticketValue = 0.01 ether;
        s_keyHash = keyHash;
        s_fee = fee;
        state = State.UNLOCKED;
    }

    modifier onlyUser() {
        require(msg.sender != owner(), "LotteryEth: does not have permissions");
        _;
    }

    modifier contractUnlocked() {
        require(state == State.UNLOCKED, "LotteryEth: blocked contract");
        _;
    }

    function stake(uint256 amount) external payable onlyUser contractUnlocked {
        require(amount != 0, "LotteryEth: can not get zero ticket");
        require(msg.value >= amount * ticketValue, "LotteryEth: amount can not be 0");
        totalPool += msg.value;
        for (uint256 i; i < amount; i++) {
            ticketsForStaker[msg.sender]++;
            tickets.push(msg.sender);
        }
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
            hasStaked[msg.sender] = true;
        }
    }

    function harvest() external onlyUser {
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "LotteryEth: it has no amount");
        rewards[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function lookingForAWinner() external onlyOwner contractUnlocked returns (bytes32 requestId) { 
        require(LINK.balanceOf(address(this)) >= s_fee, "LotteryEth: not enough LINK - fill contract with faucet");
        require(tickets.length > 0, "LotteryEth: the number of tickets is zero");
        state = State.LOCKED;
        return requestRandomness(s_keyHash, s_fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint indexRandom = randomness % tickets.length;
        rewards[tickets[indexRandom]] += totalPool;
        records.push(Record(totalPool, tickets[indexRandom], uint32(block.timestamp)));
        emit Winner(indexRandom, tickets[indexRandom]);
    }

    function reset() public onlyOwner{
        require(state == State.LOCKED, "LotteryEth: the contract must be blocked");
        totalPool = 0;
        for (uint256 i; i < stakers.length; i++) {
            delete ticketsForStaker[stakers[i]];
            delete hasStaked[stakers[i]];
        }
        delete tickets;
        delete stakers;
        state = State.UNLOCKED;
    }

    function setTicketValue(uint256 value) external onlyOwner() {
        ticketValue = value;
    }

    function getTicketsForStaker() external view onlyUser returns (uint256) {
        return ticketsForStaker[msg.sender];
    }

    function getReward() public view onlyUser returns (uint256) {
        return rewards[msg.sender];
    }

    function getNumberOfTickets() external view onlyUser returns (uint256) {
        return tickets.length;
    }

    function getNumberOfStakers() external view onlyUser returns (uint256) {
        return stakers.length;
    }

    function getNumberOfRecord() external view onlyUser returns (uint256) {
        return records.length;
    }

    function getStakers() external view onlyUser returns (address[] memory) {
        return stakers;
    }
}