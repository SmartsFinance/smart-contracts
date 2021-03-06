pragma solidity 0.6.4;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import '../node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "./Smarts.sol";

contract SecondSale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    // Crowdsale participants
    mapping(address => uint256) participants;

    // SMATS per ETH price
    uint256 buyPrice;
    uint256 minimalGoal;
    uint256 hardCap;

    Smarts crowdsaleToken;

    uint256 tokenUnit = (10 ** 18);

    event SellToken(address recepient, uint tokensSold, uint value);

    address payable fundingAddress;
    uint256 startTimestamp;
    uint256 endTimestamp;
    bool started;
    bool stopped;
    uint256 totalCollected;
    uint256 totalSold;


    /**
    Max Supply - 1,000,000 SMATS
    Token Sale 
    159,000 for Presale      (1ETH = 125 SMATS)  (8000000000000000 wei) (0,008 eth)
    */

    constructor(
        Smarts _token
    ) public {
        minimalGoal = 500000000000000000000;
        hardCap = 1272000000000000000000;
        buyPrice = 8000000000000000;
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

    receive() external payable {
        require(msg.value >= 200000000000000000, "Min 0.2 eth");
        require(msg.value <= 20000000000000000000, "Max 20 eth");
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

        // token amount as per price
        uint256 tokensSold = (_value).div(buyPrice).mul(tokenUnit);


        // transfer tokens for this buyer
        require(crowdsaleToken.transfer(_recepient, tokensSold), "Error transfering");

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
    external
    nonReentrant
    onlyOwner() // project's owner
    hasntStopped()  // crowdsale wasn't cancelled
    whenCrowdsaleSuccessful() // crowdsale completed successfully
    {
        require(_amount <= address(this).balance, "Not enough funds");
        fundingAddress.transfer(_amount);
    }

    function burnUnsold()
    external
    nonReentrant
    onlyOwner() // project's owner
    hasntStopped()  // crowdsale wasn't cancelled
    whenCrowdsaleSuccessful() // crowdsale completed successfully
    {
        crowdsaleToken.burn(crowdsaleToken.balanceOf(address(this)));
    }

    // backers refund their ETH if the crowdsale was cancelled or has failed
    function refund()
    external
    nonReentrant
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