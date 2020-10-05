pragma solidity >=0.4.25 <0.7.0;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import '../node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "./Smarts.sol";

contract Sale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    // Crowdsale participants
    mapping(address => uint256) participants;

    // SMARTS per ETH price
    uint256 buyPrice;
    uint256 buyPriceBonus;
    uint256 buyPriceBonusSecond;
    uint256 minimalGoal;
    uint256 hardCap;

    Smarts crowdsaleToken;

    uint256 tokenUnit = (10 ** 18);
    /**
    // For testing purposes
    uint256 firstBonus = (7 * (10 ** 18));
    uint256 secondBonus = ((8 + 7) * (10 ** 18));
    */

    uint256 firstBonus = (710 * (10 ** 18));
    uint256 secondBonus = ((800 + 710) * (10 ** 18));

    mapping (bytes4 => bool) inUse;

    event SellToken(address recepient, uint tokensSold, uint value);

    address payable fundingAddress;
    uint256 startTimestamp;
    uint256 endTimestamp;
    bool started;
    bool stopped;
    uint256 totalCollected;
    uint256 totalSold;

    /**
    Max Supply - 1,000,000 SMARTS
    Token Sale 
    42,600 for Private sale (1ETH = 60 SMARTS) (1,666666667E16)
    40,000 for Presale (1ETH = 50 SMARTS)      (2E16) (0,747)
    27,400 for Public Sale (1ETH = 45 SMARTS)  (2,222222222E16)
     */
    constructor(
        Smarts _token
    ) public {
        minimalGoal = 200000000000000000000;
        hardCap = 700000000000000000000;
        buyPrice = 22222222222222222;
        buyPriceBonus = 16666666666666666;
        buyPriceBonusSecond = 20000000000000000;
        crowdsaleToken = _token;
    }

    // returns address of the erc20 smarts token
    function getToken()
    public
    view
    returns(address)
    {
        return address(crowdsaleToken);
    }

    // transfers crowdsale token from mintable to transferrable state
    function releaseTokens()
    public
    onlyOwner()             // manager is CrowdsaleController instance
    hasntStopped()            // crowdsale wasn't cancelled
    whenCrowdsaleSuccessful() // crowdsale was successful
    {
        crowdsaleToken.release();
    }

    receive() external payable {
        require(msg.value > 0, "Empty value");
        sellTokens(msg.sender, msg.value);
    }

    // sels the project's token to buyers
    function sellTokens(address payable _recepient, uint256 _value) internal
        nonReentrant
        hasBeenStarted()     // crowdsale started
        hasntStopped()       // wasn't cancelled by owner
        whenCrowdsaleAlive() // in active state
    {
        uint256 newTotalCollected = totalCollected.add(_value);

        if (hardCap < newTotalCollected) {
            // don't sell anything above the hard cap

            uint256 refund = newTotalCollected.sub(hardCap);
            uint256 diff = _value.sub(refund);

            // send the ETH part which exceeds the hard cap back to the buyer
            _recepient.transfer(refund);
            _value = diff;
            newTotalCollected = totalCollected.add(_value);
        }

        // Apply Sale bonuses
        uint256 price = buyPrice;
        if (totalCollected < firstBonus) {
          require(newTotalCollected <= firstBonus, "Max tokens allowed");
          price = buyPriceBonus;
        } else if (totalCollected < secondBonus) {
          require(newTotalCollected <= secondBonus, "Max tokens allowed");
          price = buyPriceBonusSecond;
        }

        // token amount as per price
        uint256 tokensSold = (_value).div(price).mul(tokenUnit);


        // create new tokens for this buyer
        crowdsaleToken.issue(_recepient, tokensSold);

        emit SellToken(_recepient, tokensSold, _value);

        // remember the buyer so he/she/it may refund its ETH if crowdsale failed
        participants[_recepient] = participants[_recepient].add(_value);

        // update total ETH collected
        totalCollected = totalCollected.add(_value);

        // update total tokens sold
        totalSold = totalSold.add(tokensSold);
    }

    // project's owner withdraws ETH funds to the funding address upon successful crowdsale
    function withdraw(
        uint256 _amount // can be done partially
    )
    public
    onlyOwner() // project's owner
    hasntStopped()  // crowdsale wasn't cancelled
    whenCrowdsaleSuccessful() // crowdsale completed successfully
    {
        require(_amount <= address(this).balance, "Not enough funds");
        fundingAddress.transfer(_amount);
    }

    // backers refund their ETH if the crowdsale was cancelled or has failed
    function refund()
    public
    {
        // either cancelled or failed
        require(stopped || isFailed(), "Not cancelled or failed");

        uint256 amount = participants[msg.sender];

        // prevent from doing it twice
        require(amount > 0, "Only once");
        participants[msg.sender] = 0;

        msg.sender.transfer(amount);
    }

// cancels crowdsale
  function stop() public onlyOwner() hasntStopped()  {
    // we can stop only not started and not completed crowdsale
    if (started) {
      require(!isFailed());
      require(!isSuccessful());
    }
    stopped = true;
  }

  // called by CrowdsaleController to setup start and end time of crowdfunding process
  // as well as funding address (where to transfer ETH upon successful crowdsale)
  function start(
    uint256 _startTimestamp,
    uint256 _endTimestamp,
    address payable _fundingAddress
  )
    public
    onlyOwner()   // manager is CrowdsaleController instance
    hasntStarted()  // not yet started
    hasntStopped()  // crowdsale wasn't cancelled
  {
    require(_fundingAddress != address(0));

    // range must be sane
    require(_endTimestamp > _startTimestamp);

    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
    fundingAddress = _fundingAddress;

    // now crowdsale is considered started, even if the current time is before startTimestamp
    started = true;
  }

  // must return true if crowdsale is over, but it failed
  function isFailed()
    public
    view
    returns(bool)
  {
    return (
      // it was started
      started &&

      // crowdsale period has finished
      block.timestamp >= endTimestamp &&

      // but collected ETH is below the required minimum
      totalCollected < minimalGoal
    );
  }

  // must return true if crowdsale is active (i.e. the token can be bought)
  function isActive()
    public
    view
    returns(bool)
  {
    return (
      // it was started
      started &&

      // hard cap wasn't reached yet
      totalCollected < hardCap &&

      // and current time is within the crowdfunding period
      block.timestamp >= startTimestamp &&
      block.timestamp < endTimestamp
    );
  }

  // must return true if crowdsale completed successfully
  function isSuccessful()
    public
    view
    returns(bool)
  {
    return (
      // either the hard cap is collected
      totalCollected >= hardCap ||

      // ...or the crowdfunding period is over, but the minimum has been reached
      (block.timestamp >= endTimestamp && totalCollected >= minimalGoal)
    );
  }

  modifier whenCrowdsaleAlive() {
    require(isActive());
    _;
  }

  modifier whenCrowdsaleFailed() {
    require(isFailed());
    _;
  }

  modifier whenCrowdsaleSuccessful() {
    require(isSuccessful());
    _;
  }

  modifier hasntStopped() {
    require(!stopped);
    _;
  }

  modifier hasBeenStopped() {
    require(stopped);
    _;
  }

  modifier hasntStarted() {
    require(!started);
    _;
  }

  modifier hasBeenStarted() {
    require(started);
    _;
  }
}