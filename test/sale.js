const { BN } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const Smarts = artifacts.require("Smarts");
const Sale = artifacts.require("Sale");


contract('Smarts Sale', (accounts) => {
  let erc20;
  let contract;
  beforeEach(async function () {    
    erc20 = await Smarts.new({from: accounts[0]});
    contract = await Sale.new(
        erc20.address,
        {from: accounts[0]}
    );
    console.log('contacts');
    erc20.transferOwnership(contract.address, {from: accounts[0]});
    const date = new Date();
    await contract.start(parseInt((date.getTime() / 1000)-10000), parseInt((date.getTime() / 1000)+10000), accounts[3], {from: accounts[0]});
  });

  it('should buy with discount', async () => {
    await contract.sendTransaction({from:accounts[0], value:1000000000000000000})
    assert.equal((await erc20.balanceOf(accounts[0])).valueOf(), 60000000000000000000, "60 wasn't in the first account");

  });


  it('should buy with 2 discount', async () => {
    await contract.sendTransaction({from:accounts[0], value:7000000000000000000});
    await contract.sendTransaction({from:accounts[1], value:1000000000000000000});
    assert.equal((await erc20.balanceOf(accounts[1])).valueOf(), 50000000000000000000, "50 wasn't in the first account");
    await contract.sendTransaction({from:accounts[1], value:7000000000000000000});
    await contract.sendTransaction({from:accounts[2], value:1000000000000000000});
    assert.equal((await erc20.balanceOf(accounts[2])).valueOf(), 45000000000000000000, "45 wasn't in the first account");

  });
});
