const Smarts = artifacts.require("Smarts");

contract('Smarts', (accounts) => {
  it('should put 10000 Smarts in the first account', async () => {
    const smartsInstance = await Smarts.deployed();

    const balance = await smartsInstance.balanceOf(accounts[0]);
    assert.equal(balance.valueOf(), 0, "0 wasn't in the first account");

    await smartsInstance.issue(accounts[0], 10000, { from: accounts[0] });

    const newBalance = await smartsInstance.balanceOf(accounts[0]);

    assert.equal(newBalance.valueOf(), 10000, "10000 wasn't in the first account");

  });
});
