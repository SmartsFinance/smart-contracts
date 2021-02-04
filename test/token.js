const { BN } = require('@openzeppelin/test-helpers');

const Smarts = artifacts.require("Smarts");

contract('Smarts', (accounts) => {
  // Transfer
  it('should put 10000 Smarts in the first account', async () => {
    const smartsInstance = await Smarts.new({from: accounts[0]});

    const newBalance = await smartsInstance.balanceOf(accounts[0]);

    
    assert.equal((await smartsInstance.totalSupply()).valueOf(), 1000000000000000000000000, "1M wasn't the supply");
    assert.equal(newBalance.valueOf(), 1000000000000000000000000, "1M wasn't in the first account");
    assert.equal((await smartsInstance.name()), "Smarts Finance", "Incorrect value");
    assert.equal((await smartsInstance.symbol()), "SMAT", "Incorrect value");
    assert.equal((await smartsInstance.decimals()).valueOf(), 18, "Incorrect value");

  });

  it('should burn', async () => {
    const smartsInstance = await Smarts.new({from: accounts[0]});

    await smartsInstance.addAddressForFee(accounts[1], {from: accounts[0]});
    await smartsInstance.changeFeeCollector(accounts[4], {from: accounts[0]});
    await smartsInstance.setFee(100, { from: accounts[0] });
    await smartsInstance.setFeeToDistribute(400, { from: accounts[0] });

    await smartsInstance.burn(new BN('500000000000000000000000'), { from: accounts[0] });
                                                                        
    assert.equal(await smartsInstance.balanceOf(accounts[0]).valueOf(), "500000000000000000000000", "500k wasn't in the account");
    assert.equal((await smartsInstance.totalSupply()).valueOf(), "500000000000000000000000", "500k wasn't the supply");

  });

  it('should apply fee', async () => {
    const smartsInstance = await Smarts.new({from: accounts[0]});

    await smartsInstance.addAddressForFee(accounts[1], {from: accounts[0]});
    await smartsInstance.changeFeeCollector(accounts[4], {from: accounts[0]});
    await smartsInstance.setFee(100, { from: accounts[0] });
    await smartsInstance.setFeeToDistribute(400, { from: accounts[0] });

    await smartsInstance.transfer(accounts[1], new BN('1000000000000000000000000'), { from: accounts[0] });
                                                                        
    assert.equal(await smartsInstance.balanceOf(accounts[0]).valueOf(), 0, "0 wasn't in the account");
    assert.equal(await smartsInstance.balanceOf(accounts[1]).valueOf(), 990396000000000000000000, "995019 wasn't in the account");
    assert.equal(await smartsInstance.balanceOf(accounts[4]).valueOf(), 9603840000000000000000, "4980 wasn't in the account");
  });

  it('should apply fee if address is selected', async () => {
    const smartsInstance = await Smarts.new({from: accounts[0]});

    await smartsInstance.addAddressForFee(accounts[2], {from: accounts[0]});
    await smartsInstance.changeFeeCollector(accounts[4], {from: accounts[0]});
    await smartsInstance.transfer(accounts[1], new BN('100000000000000000000'), { from: accounts[0] });

    assert.equal(await smartsInstance.balanceOf(accounts[1]).valueOf(), 100000000000000000000, "100 wasn't in the account");
    await smartsInstance.transfer(accounts[2], new BN('100000000000000000000'), { from: accounts[0] });
    assert.equal(await smartsInstance.balanceOf(accounts[1]).valueOf(), 100000004000000000000, "100 wasn't in the account");
    assert.equal(await smartsInstance.balanceOf(accounts[2]).valueOf(), 99000003960000000000, "995 wasn't in the account");
  });

  // Transfer from

  it('should apply fee with transfer from', async () => {
    const smartsInstance = await Smarts.new({from: accounts[0]});

    await smartsInstance.addAddressForFee(accounts[1], {from: accounts[0]});
    await smartsInstance.changeFeeCollector(accounts[4], {from: accounts[0]});
    await smartsInstance.approve(accounts[1], new BN('1000000000000000000000000'), { from: accounts[0] });
    await smartsInstance.transferFrom(accounts[0], accounts[1], new BN('1000000000000000000000000'), { from: accounts[1] });
                                                                        
    assert.equal(await smartsInstance.balanceOf(accounts[0]).valueOf(), 0, "0 wasn't in the account");
    assert.equal(await smartsInstance.balanceOf(accounts[1]).valueOf(), 990396000000000000000000, "995019 wasn't in the account");
    assert.equal(await smartsInstance.balanceOf(accounts[4]).valueOf(), 9603840000000000000000, "4980 wasn't in the account");
  });

  it('should apply fee if address is selected with transfer from', async () => {
    const smartsInstance = await Smarts.new({from: accounts[0]});

    await smartsInstance.addAddressForFee(accounts[2], {from: accounts[0]});
    await smartsInstance.changeFeeCollector(accounts[4], {from: accounts[0]});
    await smartsInstance.approve(accounts[1], new BN('1000000000000000000000000'), { from: accounts[0] });
    await smartsInstance.transferFrom(accounts[0], accounts[1], new BN('100000000000000000000'), { from: accounts[1] });

    assert.equal(await smartsInstance.balanceOf(accounts[1]).valueOf(), 100000000000000000000, "100 wasn't in the account");
    await smartsInstance.approve(accounts[1], new BN('1000000000000000000000000'), { from: accounts[0] });

    await smartsInstance.transferFrom(accounts[0], accounts[2], new BN('100000000000000000000'), { from: accounts[1] });
    assert.equal(await smartsInstance.balanceOf(accounts[1]).valueOf(), 100000004000000000000, "100 wasn't in the account");
    assert.equal(await smartsInstance.balanceOf(accounts[2]).valueOf(), 99000003960000000000, "995 wasn't in the account");
  });
});
