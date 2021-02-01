const { BN } = require('@openzeppelin/test-helpers');

const Smarts = artifacts.require("Smarts");

contract('Smarts', (accounts) => {
  it('should put 10000 Smarts in the first account', async () => {
    const smartsInstance = await Smarts.new({from: accounts[0]});

    const newBalance = await smartsInstance.balanceOf(accounts[0]);

    
    assert.equal((await smartsInstance.totalSupply()).valueOf(), 1000000000000000000000000, "1M wasn't the supply");

    assert.equal(newBalance.valueOf(), 1000000000000000000000000, "1M wasn't in the first account");

  });


  it('should apply fee', async () => {
    const smartsInstance = await Smarts.new({from: accounts[0]});

    await smartsInstance.addAddressForFee(accounts[1], {from: accounts[0]});
    await smartsInstance.changeFeeCollector(accounts[4], {from: accounts[0]});
    await smartsInstance.transfer(accounts[1], new BN('1000000000000000000000000'), { from: accounts[0] });
                                                                        
    assert.equal(await smartsInstance.balanceOf(accounts[0]).valueOf(), 0, "0 wasn't in the account");
    assert.equal(await smartsInstance.balanceOf(accounts[1]).valueOf(), 995019900000000000000000, "995019 wasn't in the account");
    assert.equal(await smartsInstance.balanceOf(accounts[4]).valueOf(), 4980099600000000000000, "4980 wasn't in the account");

    await smartsInstance.transfer(accounts[2], new BN('995019900000000000000000'), { from: accounts[1] });
  });

  it('should apply fee if address is selected', async () => {
    const smartsInstance = await Smarts.new({from: accounts[0]});

    await smartsInstance.addAddressForFee(accounts[2], {from: accounts[0]});
    await smartsInstance.changeFeeCollector(accounts[4], {from: accounts[0]});
    await smartsInstance.transfer(accounts[1], new BN('100000000000000000000'), { from: accounts[0] });

    console.log(web3.utils.fromWei(await smartsInstance.balanceOf(accounts[4]).valueOf(), "ether" ));

    assert.equal(await smartsInstance.balanceOf(accounts[1]).valueOf(), 100000000000000000000, "100 wasn't in the account");
    await smartsInstance.transfer(accounts[2], new BN('100000000000000000000'), { from: accounts[0] });
    console.log(web3.utils.fromWei((await smartsInstance._gonsPerFragment.call()).valueOf(), "ether" ));
    console.log(web3.utils.fromWei((await smartsInstance._elasticSupply.call()).valueOf(), "ether" ));
    console.log(web3.utils.fromWei(await smartsInstance.balanceOf(accounts[1]).valueOf(), "ether" ));
    console.log(web3.utils.fromWei(await smartsInstance.balanceOf(accounts[4]).valueOf(), "ether" ));
    assert.equal(await smartsInstance.balanceOf(accounts[1]).valueOf(), 100000000200000000000, "100 wasn't in the account");
    assert.equal(await smartsInstance.balanceOf(accounts[2]).valueOf(), 99500000199000000000, "995 wasn't in the account");
  });
});
