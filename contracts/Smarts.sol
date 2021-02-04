pragma solidity 0.6.4;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/utils/Address.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Smarts is Ownable, IERC20 {

    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _addressesWithFee;
    address public _feescollector;
    address public _emptyWallet = address(0);
    uint256 public _fee;
    uint256 public _feeToDistribute;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;

    event Issue(address recepient, uint amount);

    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private _elasticSupply = MAX_UINT256;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1000000 * uint(10)**_decimals;
    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 private _gonsPerFragment;

    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    constructor () public {
        _name = "Smarts Finance";
        _symbol = "SMAT";
        _feescollector = msg.sender;
        _fee = 100; // 1%
        _feeToDistribute = 400; // 40% from the 1%
        _issue(msg.sender, INITIAL_FRAGMENTS_SUPPLY);
        _elasticSupply = _totalSupply;
        _gonsPerFragment = TOTAL_GONS.div(_elasticSupply);

        _balances[msg.sender] = INITIAL_FRAGMENTS_SUPPLY.mul(_gonsPerFragment);

    }

    /** 
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account].div(_gonsPerFragment);
    }

    function setFee(uint256 amount) external onlyOwner() {
        _fee = amount;
    }

    function setFeeToDistribute(uint256 amount) external onlyOwner() {
        _feeToDistribute = amount;
    }

    function changeFeeCollector(address addr) external onlyOwner() {
        _feescollector = addr;
    }

    function addAddressForFee(address addr) external onlyOwner() {
        _addressesWithFee[addr] = true;
    }

    function removeAddressForFee(address addr) external onlyOwner() {
        _addressesWithFee[addr] = false;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

	/**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }


    function _issue(address _recepient, uint256 _amount) internal {
        _balances[_recepient] = _balances[_recepient].add(_amount);
        _totalSupply = _totalSupply.add(_amount);
        emit Issue(_recepient, _amount);
        emit Transfer(address(0), _recepient, _amount);
    }

    function _transfer(address sender, address recipient, uint256 _amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 amount = _amount.mul(_gonsPerFragment);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");

        if (_fee != 0 && (_addressesWithFee[sender] || _addressesWithFee[recipient])) {
            // Let's a pply a fee to this tx
            uint256 feeamount = _amount.mul(_fee).div(10000);

            // Original remaining amount
            uint256 remamountOrg = _amount.sub(feeamount);

            // Value of remaining amount
            uint256 remamount = remamountOrg.mul(_gonsPerFragment);
            _balances[recipient] = _balances[recipient].add(remamount);
            emit Transfer(sender, recipient, remamountOrg);

            // Now let's distribute the fee
            uint256 feeamountToPool = feeamount.mul(_feeToDistribute).div(10000);

            // Original amount for the pool
            uint256 remamountToPoolOrg = feeamount.sub(feeamountToPool);
            // Value amount for the pool
            uint256 remamountToPool = remamountToPoolOrg.mul(_gonsPerFragment);

            _balances[_feescollector] = _balances[_feescollector].add(remamountToPool);
            emit Transfer(sender, _feescollector, remamountToPoolOrg);

            // Now, for the final fragment of the fee let's distribute among all holders
            uint256 finalFeeAmount = feeamountToPool.mul(_gonsPerFragment);

            // Send amount to the empty wallet
            _balances[_emptyWallet] = _balances[_emptyWallet].add(finalFeeAmount);
            emit Transfer(sender, _emptyWallet, feeamountToPool);
            
            // Adjuts amount of all holders
            adjust(feeamountToPool);
        } else {
            // Simple transfer without fee
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, _amount);
        }
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount.mul(_gonsPerFragment), "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function adjust(uint256 feeamount)
        internal
    {
        _elasticSupply = _elasticSupply.add(feeamount);
        _gonsPerFragment = TOTAL_GONS.div(_elasticSupply);
    }
}