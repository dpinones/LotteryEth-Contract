import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Signer, utils } from 'ethers'
import '@nomiclabs/hardhat-ethers'

import { LotteryEth__factory, LotteryEth } from '../build/types'

const { getContractFactory, getSigners } = ethers

describe('LotteryEth', () => {
  let lotteryEth: LotteryEth
  let deployer, userA, userB, userToTeam
  let ether1, ether2, ether3

  beforeEach(async () => {
    const signers = await getSigners()

    deployer = signers[0]
    userA = signers[1]
    userB = signers[2]
    userToTeam = signers[3]

    ether1 = { value: ethers.utils.parseEther('10.0') }
    ether2 = { value: ethers.utils.parseEther('20.0') }
    ether3 = { value: ethers.utils.parseEther('30.0') }

    const counterFactory = (await getContractFactory('LotteryEth', signers[0])) as LotteryEth__factory
    lotteryEth = await counterFactory.deploy("0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9", "0xa36085F69e2889c224210F603D836748e7dC0088",
    "0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4", "100000000000000000")
    await lotteryEth.deployed()
  })

  describe('Deploy', async () => {
    it('check deployer', async () => {
      expect(await lotteryEth.owner()).to.eq(deployer.address)
    })

    it('totalPool is 0', async () => {
      expect(await lotteryEth.totalPool()).to.eq(0)
    })

    it('number of users is zero', async () => {
      expect(await lotteryEth.getNumberOfUsers()).to.eq(0)
    })

    it('number of tickets is zero', async () => {
      expect(await lotteryEth.getNumberOfTickets()).to.eq(0)
    })

    it('number of record is zero', async () => {
      expect(await lotteryEth.getNumberOfRecord()).to.eq(0)
    })

  })

  describe('Deployer', async () => {
    it('not have permissions', async () => {
      await expect(lotteryEth.buyTicket(1)).to.be.revertedWith('LotteryEth: does not have permissions')
      await expect(lotteryEth.withdraw()).to.be.revertedWith('LotteryEth: does not have permissions')
    })
  })

  describe('User', async () => {
    it('not have permissions', async () => {
      await expect(lotteryEth.connect(userA).lookingForAWinner()).to.be.revertedWith('Ownable: caller is not the owner')
      await expect(lotteryEth.connect(userA).reset()).to.be.revertedWith('Ownable: caller is not the owner')
      await expect(lotteryEth.connect(userA).setTicketValue(ethers.utils.parseEther('0.05'))).to.be.revertedWith('Ownable: caller is not the owner')
    })

    it('buy zero tickets', async () => {
      await expect(lotteryEth.connect(userA).buyTicket(0, { value: ethers.utils.parseEther('0.1') })).to.be.revertedWith('LotteryEth: can not get zero ticket')
    })

    it('insufficient amount', async () => {
      await expect(lotteryEth.connect(userA).buyTicket(10, { value: ethers.utils.parseEther('0.09') })).to.be.revertedWith('LotteryEth: insufficient amount')
    })

    it('set ticket value', async () => {
      expect(await lotteryEth.ticketValue()).to.eq(ethers.utils.parseEther('0.01'))
      await lotteryEth.setTicketValue(ethers.utils.parseEther('0.1'));
      expect(await lotteryEth.ticketValue()).to.eq(ethers.utils.parseEther('0.1'))
    })

    it('buy tickets a user', async () => {
      expect(await lotteryEth.connect(userA).getNumberOfTickets()).to.eq(0)
      expect(await lotteryEth.connect(userA).getTicketsForUser()).to.eq(0)
      await lotteryEth.connect(userA).buyTicket(10, { value: ethers.utils.parseEther('0.1') });
      expect(await lotteryEth.connect(userA).getTicketsForUser()).to.eq(10)
      expect(await lotteryEth.connect(userA).getNumberOfTickets()).to.eq(10)
    })
    
    it('multiple users buy tickets', async () => {
      expect(await lotteryEth.connect(userA).getNumberOfTickets()).to.eq(0)
      expect(await lotteryEth.connect(userA).getTicketsForUser()).to.eq(0)
      
      await lotteryEth.connect(userA).buyTicket(10, { value: ethers.utils.parseEther('0.1') });
      
      expect(await lotteryEth.connect(userA).getTicketsForUser()).to.eq(10)
      expect(await lotteryEth.connect(userA).getNumberOfTickets()).to.eq(10)

      await lotteryEth.connect(userB).buyTicket(15, { value: ethers.utils.parseEther('0.15') });

      expect(await lotteryEth.connect(userA).getTicketsForUser()).to.eq(10)
      expect(await lotteryEth.connect(userB).getTicketsForUser()).to.eq(15)
      expect(await lotteryEth.connect(userB).getNumberOfTickets()).to.eq(25)
    })

  })
})
