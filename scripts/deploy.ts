import { ethers } from 'hardhat'

async function main() {
  const factory = await ethers.getContractFactory('LotteryEth')

  // If we had constructor arguments, they would be passed into deploy()
  const contract = await factory.deploy("0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9", "0xa36085F69e2889c224210F603D836748e7dC0088",
  "0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4", "100000000000000000")

  // The address the Contract WILL have once mined
  console.log(contract.address)

  // The transaction that was sent to the network to deploy the Contract
  console.log(contract.deployTransaction.hash)

  // The contract is NOT deployed yet; we must wait until it is mined
  await contract.deployed()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
