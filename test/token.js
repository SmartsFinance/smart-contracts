const { BN } = require('@openzeppelin/test-helpers');

const Smarts = artifacts.require("Smarts");

contract('Smarts', (accounts) => {
  it('should put 10000 Smarts in the first account', async () => {
    const smartsInstance = await Smarts.deployed();

    const balance = await smartsInstance.balanceOf(accounts[0]);
    assert.equal(balance.valueOf(), 0, "0 wasn't in the first account");

    await smartsInstance.issue(accounts[0], 60000, { from: accounts[0] });

    const newBalance = await smartsInstance.balanceOf(accounts[0]);

    assert.equal(newBalance.valueOf(), 60000, "60000 wasn't in the first account");

  });

  it('should apply fee if address is selected', async () => {
    const smartsInstance = await Smarts.deployed();

    await smartsInstance.issue(accounts[0], new BN('1000000000000000000000'), { from: accounts[0] });

    await smartsInstance.release({ from: accounts[0] });
    await smartsInstance.addAddressForFee(accounts[2], {from: accounts[0]})
    await smartsInstance.transfer(accounts[1], new BN('100000000000000000000'), { from: accounts[0] });

    assert.equal(await smartsInstance.balanceOf(accounts[1]).valueOf(), 100000000000000000000, "100 wasn't in the account");
    await smartsInstance.transfer(accounts[2], new BN('100000000000000000000'), { from: accounts[0] });
    assert.equal(await smartsInstance.balanceOf(accounts[2]).valueOf(), 99500000000000000000, "950 wasn't in the account");
  });
});
