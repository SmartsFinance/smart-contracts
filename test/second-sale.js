const { expectRevert } = require('@openzeppelin/test-helpers');
const { expect, assert } = require('chai');

const Smarts = artifacts.require("Smarts");
const Sale = artifacts.require("SecondSale");


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
    erc20.issue(contract.address, '159000000000000000000000', {from: accounts[0]});
    erc20.release();
    const date = new Date();
    await contract.start(parseInt((date.getTime() / 1000)-10000), parseInt((date.getTime() / 1000)+10000), accounts[3], {from: accounts[0]});
  });


  it('should buy ', async () => {
    // NOTE! To run this test you have to change the hardcap to 700000000000000000000
    await contract.sendTransaction({from:accounts[1], value:1000000000000000000});
    assert.equal((await erc20.balanceOf(accounts[1])).valueOf(), 125000000000000000000, "125 wasn't in the first account");
    await contract.sendTransaction({from:accounts[1], value:7000000000000000000});
    await contract.sendTransaction({from:accounts[2], value:1000000000000000000});
    assert.equal((await erc20.balanceOf(accounts[2])).valueOf(), 125000000000000000000, "125 wasn't in the second account");
    for (let i = 0; i < 9; i++) {
      await contract.sendTransaction({from:accounts[1], value:10000000000000000000});
      await contract.sendTransaction({from:accounts[2], value:10000000000000000000});
    }
    for (let i = 0; i < 10; i++) {
      await contract.sendTransaction({from:accounts[3], value:10000000000000000000});
      await contract.sendTransaction({from:accounts[4], value:10000000000000000000});
      await contract.sendTransaction({from:accounts[5], value:10000000000000000000});
      await contract.sendTransaction({from:accounts[6], value:10000000000000000000});
      if (await contract.isSuccessful()) {
        break;
      }

      await contract.sendTransaction({from:accounts[7], value:10000000000000000000});
      await contract.sendTransaction({from:accounts[8], value:10000000000000000000});
    }
    assert.equal(await erc20.totalSupply(), '159000000000000000000000', 'Incorrect total supply');
    await contract.burnUnsold({from: accounts[0]});
  });

  it('should fail if value is less than 0.2 eth', async function () {
    await expectRevert(
      contract.sendTransaction({from:accounts[1], value:100000000000000000}),
        'Min 0.2 eth'
    );
  });

  it('should fail if value is more than 20 eth', async function () {
    await expectRevert(
      contract.sendTransaction({from:accounts[1], value:20100000000000000000}),
        'Max 20 eth'
    );
  });
});
