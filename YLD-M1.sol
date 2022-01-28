pragma solidity 0.8.0;

/**
* @dev Interface of the ERC20 standard as defined in the EIP.
*/
interface IERC20 {
	/**
	* @dev Returns the amount of tokens in existence.
	*/
	function totalSupply() external view returns (uint256);
	
	/**
	* @dev Returns the name of the token.
	*/
	function name() external view returns (string memory);

	/**
	* @dev Returns the symbol of the token.
	*/
	function symbol() external view returns (string memory);

	/**
	* @dev Returns the decimals places of the token.
	*/
	function decimals() external view returns (uint8);
	
	/**
	* @dev Returns the bep token owner.
	*/
	function getOwner() external view returns (address);

	/**
	* @dev Returns the amount of tokens owned by `account`.
	*/
	function balanceOf(address account) external view returns (uint256);

	/**
	* @dev Moves `amount` tokens from the caller's account to `recipient`.
	*
	* Returns a boolean value indicating whether the operation succeeded.
	*
	* Emits a {Transfer} event.
	*/
	function transfer(address recipient, uint256 amount) external returns (bool);

	/**
	* @dev Returns the remaining number of tokens that `spender` will be
	* allowed to spend on behalf of `owner` through {transferFrom}. This is
	* zero by default.
	*
	* This value changes when {approve} or {transferFrom} are called.
	*/
	function allowance(address owner, address spender) external view returns (uint256);

	/**
	* @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
	*
	* Returns a boolean value indicating whether the operation succeeded.
	*
	* IMPORTANT: Beware that changing an allowance with this method brings the risk
	* that someone may use both the old and the new allowance by unfortunate
	* transaction ordering. One possible solution to mitigate this race
	* condition is to first reduce the spender's allowance to 0 and set the
	* desired value afterwards:
	* https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	*
	* Emits an {Approval} event.
	*/
	function approve(address spender, uint256 amount) external returns (bool);

	/**
	* @dev Moves `amount` tokens from `sender` to `recipient` using the
	* allowance mechanism. `amount` is then deducted from the caller's
	* allowance.
	*
	* Returns a boolean value indicating whether the operation succeeded.
	*
	* Emits a {Transfer} event.
	*/
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

	/**
	* @dev Emitted when `value` tokens are moved from one account (`from`) to
	* another (`to`).
	*
	* Note that `value` may be zero.
	*/
	event Transfer(address indexed from, address indexed to, uint256 value);

	/**
	* @dev Emitted when the allowance of a `spender` for an `owner` is set by
	* a call to {approve}. `value` is the new allowance.
	*/
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
* @dev Provides information about the current execution context, including the
* sender of the transaction and its data. While these are generally available
* via msg.sender and msg.data, they should not be accessed in such a direct
* manner, since when dealing with meta-transactions the account sending and
* paying for execution may not be the actual sender (as far as an application
* is concerned).
*
* This contract is only required for intermediate, library-like contracts.
*/
abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

/**
* @dev Contract module which provides a manager access control mechanism, where
* there is owner and manager, that can be granted exclusive access to
* specific functions.
*
* Both owner and manager accounts need to be specified when deploying the contract. This
* can later be changed with {setOwner} and {setManager}.
*
* This module is used through inheritance. Modifiers `onlyOwner` and `ownerOrManager`
* will be available, which can be applied to your functions to restrict their use.
*/
abstract contract Managed is Context
{
	event OwnershipTransfered(address indexed previousOwner, address indexed newOwner);
	event ManagementTransferred(address indexed previousManager, address indexed newManager);
	
	address private _owner;
	address private _manager;

	/**
	* @dev Initializes the contract, setting owner and manager.
	*/
	constructor(address owner_, address manager_)
	{
		require(owner_ != address(0), "Owner address can't be a zero address");
		require(manager_ != address(0), "Manager address can't be a zero address");
		
		_setOwner(owner_); 
		_setManager(manager_);
	}

	/**
	* @dev Returns the address of the current owner.
	*/
	function owner() public view returns (address)
	{ return _owner; }

	/**
	* @dev Returns the address of the current manager.
	*/
	function manager() public view returns (address)
	{ return _manager; }

	/**
	* @dev Transfers owner permissions to a new account (`newOwner`).
	* Can only be called by owner.
	*/
	function setOwner(address newOwner) public onlyOwner
	{
		require(newOwner != address(0), "Managed: new owner can't be zero address");
		_setOwner(newOwner);
	}

	/**
	* @dev Transfers manager permissions to a new account (`newManager`).
	* Can only be called by owner.
	*/
	function setManager(address newManager) public onlyOwner
	{
		require(newManager != address(0), "Managed: new manager can't be zero address");
		_setManager(newManager);
	}

	/**
	* @dev Throws if called by any account other than the owner.
	*/
	modifier onlyOwner()
	{
		require(_msgSender() == _owner, "Managed: caller is not the owner");
		_;
	}

	/**
	* @dev Throws if called by any account other than owner or manager.
	*/
	modifier ownerOrManager()
	{
		require(_msgSender() == _owner || _msgSender() == _manager, "Managed: caller is not the owner or manager");
		_;
	}

	/**
	* @dev Transfers owner permissions to a new account (`newOwner`).
	* Internal function without access restriction.
	*/
	function _setOwner(address newOwner) internal
	{
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransfered(oldOwner, newOwner);
	}

	/**
	* @dev Transfers manager permissions to a new account (`newManager`).
	* Internal function without access restriction.
	*/
	function _setManager(address newManager) internal
	{
		address oldManager = _manager;
		_manager = newManager;
		emit ManagementTransferred(oldManager, newManager);
	}
}

/**
* @dev Contract module which provides a locking mechanism that allows
* a total token lock, or lock of a specific address.
*
* This module is used through inheritance. Modifier `isUnlocked`
* will be available, which can be applied to your functions to restrict their use.
*/
abstract contract Lockable is Managed
{
	event AddressLockChanged(address indexed addr, bool newLock);
	event TokenLockChanged(bool newLock);
	
	mapping(address => bool) private _addressLocks;
	bool private _locked;
	
	/**
	* @dev Completely locks any transfers of the token.
	* Can only be called by owner.
	*/
	function lockToken() public onlyOwner
	{
		_locked = true;
		emit TokenLockChanged(true);
	}
	
	/**
	* @dev Completely unlocks any transfers of the token.
	* Can only be called by owner.
	*/
	function unlockToken() public onlyOwner
	{
		_locked = false;
		emit TokenLockChanged(false);
	}
	
	/**
	* @dev Return whether the token is currently locked.
	*/
	function isLocked() public view returns (bool)
	{ return _locked; }
	
	/**
	* @dev Throws if a function is called while the token is locked.
	*/
	modifier isUnlocked()
	{
		require(!_locked, "All token transfers are currently locked");
		_;
	}
	
	/**
	* @dev Completely locks sending and receiving of token for a specific address.
	* Can only be called by owner or manager
	*/
	function lockAddress(address addr) public ownerOrManager
	{
		_addressLocks[addr] = true;
		emit AddressLockChanged(addr, true);
	}
	
	/**
	* @dev Completely unlocks sending and receiving of token for a specific address.
	* Can only be called by owner or manager
	*/
	function unlockAddress(address addr) public ownerOrManager
	{
		_addressLocks[addr] = false;
		emit AddressLockChanged(addr, false);
	}
	
	/**
	* @dev Returns whether the account (`addr`) is currently locked.
	*/
	function isAddressLocked(address addr) public view returns (bool)
	{ return _addressLocks[addr]; }
}

/**
* @dev Implementation of the {IERC20} interface.
*
* This implementation is agnostic to the way tokens are created. This means
* that a supply mechanism has to be added in a derived contract using {_mint}.
* For a generic mechanism see {ERC20PresetMinterPauser}.
*
* TIP: For a detailed writeup see our guide
* https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
* to implement supply mechanisms].
*
* We have followed general OpenZeppelin Contracts guidelines: functions revert
* instead returning `false` on failure. This behavior is nonetheless
* conventional and does not conflict with the expectations of ERC20
* applications.
*
* Additionally, an {Approval} event is emitted on calls to {transferFrom}.
* This allows applications to reconstruct the allowance for all accounts just
* by listening to said events. Other implementations of the EIP may not emit
* these events, as it isn't required by the specification.
*
* Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
* functions have been added to mitigate the well-known issues around setting
* allowances. See {IERC20-approve}.
*/
contract ERC20 is Context, IERC20, Managed, Lockable
{
	event Stake(address indexed addr, uint256 amount, uint256 expiry);
	event StakeRemoved(address indexed addr, uint256 amount, uint256 expiry);
	event Burn(address indexed from, uint256 amount);
	
	mapping(address => uint256) private _balances;

	mapping(address => mapping(address => uint256)) private _allowances;
	
	struct StakeData
	{
		uint256 amount;
		uint256 expiry;
	}
	
	mapping(address => StakeData[]) _stakes;

	uint256 private _totalSupply;
	string private _name;
	string private _symbol;
	uint8 private _decimals;
	
	/**
	* @dev Sets the values for {name}, {symbol}, {decimals}, {totalSupply} {owner}, {manager} and {depositAddress}.
	*
	* All values for token parameters are immutable: they can only be set once during
	* construction.
	*/
	constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_, address owner_, address manager_, address depositAddress) Managed(owner_, manager_)
	{
		require(depositAddress != address(0), "Initial deposit address can't be a zero address");
		
		_name = name_;
		_symbol = symbol_;
		_decimals = decimals_;
		
		_totalSupply = totalSupply_ * uint256(10**_decimals);
		_balances[depositAddress] = _totalSupply;
		
		emit Transfer(address(0), depositAddress, _totalSupply);
	}

	/**
	* @dev Returns the name of the token.
	*/
	function name() public view virtual override returns (string memory) {
		return _name;
	}

	/**
	* @dev Returns the symbol of the token, usually a shorter version of the
	* name.
	*/
	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	/**
	* @dev Returns the number of decimals used to get its user representation.
	* For example, if `decimals` equals `2`, a balance of `505` tokens should
	* be displayed to a user as `5.05` (`505 / 10 ** 2`).
	*
	* Tokens usually opt for a value of 18, imitating the relationship between
	* Ether and Wei. This is the value {ERC20} uses, unless this function is
	* overridden;
	*
	* NOTE: This information is only used for _display_ purposes: it in
	* no way affects any of the arithmetic of the contract, including
	* {IERC20-balanceOf} and {IERC20-transfer}.
	*/
	function decimals() public view virtual override returns (uint8) {
		return _decimals;
	}
	
	/**
	* @dev See {IERC20-getOwner}.
	*/
	function getOwner() public view virtual override returns (address)
	{ return owner(); }

	/**
	* @dev See {IERC20-totalSupply}.
	*/
	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply;
	}

	/**
	* @dev See {IERC20-balanceOf}.
	*/
	function balanceOf(address account) public view virtual override returns (uint256) {
		return _balances[account];
	}

	/**
	* @dev See {IERC20-transfer}.
	*
	* Requirements:
	*
	* - the caller must have an available balance of at least `amount`.
	*/
	function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
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
	function approve(address spender, uint256 amount) external virtual override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	/**
	* @dev See {IERC20-transferFrom}.
	*
	* Emits an {Approval} event indicating the updated allowance. This is not
	* required by the EIP. See the note at the beginning of {ERC20}.
	*
	* Requirements:
	*
	* - `sender` and `recipient` cannot be the zero address.
	* - `sender` must have a balance of at least `amount`.
	* - the caller must have allowance for ``sender``'s tokens of at least
	* `amount`.
	*/
	function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
		_transfer(sender, recipient, amount);

		uint256 currentAllowance = _allowances[sender][_msgSender()];
		require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
		unchecked {
			_approve(sender, _msgSender(), currentAllowance - amount);
		}

		return true;
	}
	
	/**
	* @dev Destroys `amount` tokens from the caller.
	*
	* See {ERC20-_burn}.
	*/
	function burn(uint256 amount) external virtual
	{ _burn(_msgSender(), amount); }

	/**
	* @dev Destroys `amount` tokens from `account`, deducting from the caller's
	* allowance.
	*
	* See {ERC20-_burn} and {ERC20-allowance}.
	*
	* Requirements:
	*
	* - the caller must have allowance for `accounts`'s tokens of at least
	* `amount`.
	*/
	function burnFrom(address account, uint256 amount) external virtual
	{
		uint256 currentAllowance = allowance(account, _msgSender());
		require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
		unchecked {
			_approve(account, _msgSender(), currentAllowance - amount);
		}
		_burn(account, amount);
	}

	/**
	* @dev Atomically increases the allowance granted to `spender` by the caller.
	*
	* This is an alternative to {approve} that can be used as a mitigation for
	* problems described in {IERC20-approve}.
	*
	* Emits an {Approval} event indicating the updated allowance.
	*
	* Requirements:
	*
	* - `spender` cannot be the zero address.
	*/
	function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
		return true;
	}

	/**
	* @dev Atomically decreases the allowance granted to `spender` by the caller.
	*
	* This is an alternative to {approve} that can be used as a mitigation for
	* problems described in {IERC20-approve}.
	*
	* Emits an {Approval} event indicating the updated allowance.
	*
	* Requirements:
	*
	* - `spender` cannot be the zero address.
	* - `spender` must have allowance for the caller of at least
	* `subtractedValue`.
	*/
	function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
		uint256 currentAllowance = _allowances[_msgSender()][spender];
		require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
		unchecked {
			_approve(_msgSender(), spender, currentAllowance - subtractedValue);
		}

		return true;
	}
	
	/**
	* @dev Returns the spendable balance of `addr` (minus current stakes).
	*/
	function getAvailableBalance(address addr) public view returns (uint256)
	{
		uint256 available = _balances[addr];
		for (uint i = 0; i < _stakes[addr].length; i++)
		{
			if (_stakes[addr][i].expiry > block.timestamp)
				available -= _stakes[addr][i].amount;
		}
		
		return available;
	}
	
	/**
	* @dev Returns all the stakes of `addr`.
	*/
	function getStakesOnAddress(address addr) external view returns (StakeData[] memory)
	{ return _stakes[addr]; }
	
	/**
	* @dev Creates a new stake for caller with specific amount
	* and expiry date.
	*
	* See {ERC20-_stake}.
	*/
	function stake(uint256 amount, uint256 expiry) external returns (uint256, uint256)
	{ return _stake(_msgSender(), amount, expiry); }
	
	/**
	* @dev Creates a new stake for an `addr` with specific amount
	* and expiry date. Can be only called by owner or manager.
	*
	* See {ERC20-_stake}.
	*/
	function stakeOnAddress(address addr, uint256 amount, uint256 expiry) external ownerOrManager returns (uint256, uint256)
	{ return _stake(addr, amount, expiry); }
	
	/**
	* @dev Removes a stake on `addr` with specific parameters.
	* Throws if no such stake has been found.
	* Can be only called by owner or manager.
	* 
	* Emits a {StakeRemoved} event with stake parameters.
	*/
	function removeStake(address addr, uint256 amount, uint256 expiry) external ownerOrManager
	{
		bool found;
		uint loc;
		
		for (loc = 0; loc < _stakes[addr].length; loc++)
		{
			if (_stakes[addr][loc].amount == amount && _stakes[addr][loc].expiry == expiry)
			{
				found = true;
				break;
			}
		}
		
		require(found, "Could not find a stake with specified parameters");
		
		StakeData memory _removedStake = _stakes[addr][loc];
		
		if (loc != _stakes[addr].length-1)
			_stakes[addr][loc] = _stakes[addr][_stakes[addr].length-1];
		
		_stakes[addr].pop();
		emit StakeRemoved(addr, _removedStake.amount, _removedStake.expiry);
	}
	
	/**
	* @dev Cleans up all the expired stakes on `addr`
	* from a list, freeing up memory and lowering
	* future gas amount when creating a new stake
	* or calculating available balance.
	* 
	* Emites a {StakeRemoved} for every removed stake
	* with it's parameters.
	*/
	function cleanupStakes(address addr) internal
	{
		StakeData memory _removedStake;
		
		for (uint i = 0; i < _stakes[addr].length;)
		{
			if (_stakes[addr][i].expiry > block.timestamp)
			{
				i++;
				continue;
			}
			
			_removedStake = _stakes[addr][i];
			
			if (i != _stakes[addr].length-1)
				_stakes[addr][i] = _stakes[addr][_stakes[addr].length-1];
			
			_stakes[addr].pop();
			emit StakeRemoved(addr, _removedStake.amount, _removedStake.expiry);
		}
	}

	/**
	* @dev Moves `amount` of tokens from `sender` to `recipient`.
	*
	* This internal function is equivalent to {transfer}, and can be used to
	* e.g. implement automatic token fees, slashing mechanisms, etc.
	* 
	* If the `recipient` address is zero address, calls {_burn} instead.
	*
	* Emits a {Transfer} event.
	*
	* Requirements:
	*
	* - `sender` cannot be the zero address.
	* - `sender` must have an available balance of at least `amount`.
	*/
	function _transfer(address sender, address recipient, uint256 amount) internal isUnlocked virtual
	{
		require(recipient != address(0), "ERC20: transfer to zero address");
		require(sender != address(0), "ERC20: transfer from the zero address");
		
		require(!isAddressLocked(sender), "Sender address is currently locked and can't send funds");
		require(!isAddressLocked(recipient), "Recipient address is currently locked and can't receive funds");

		uint256 availableBalance = getAvailableBalance(sender);
		require(availableBalance >= amount, "ERC20: transfer amount exceeds available balance");
		
		_balances[sender] -= amount;
		_balances[recipient] += amount;

		emit Transfer(sender, recipient, amount);
	}

	/**
	* @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
	*
	* This internal function is equivalent to `approve`, and can be used to
	* e.g. set automatic allowances for certain subsystems, etc.
	*
	* Emits an {Approval} event.
	*
	* Requirements:
	*
	* - `owner` cannot be the zero address.
	* - `spender` cannot be the zero address.
	*/
	function _approve(address owner, address spender, uint256 amount) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}
	
	/**
	* @dev Destroys `amount` tokens from `account`, reducing the
	* total supply.
	*
	* Emits a {Transfer} event with `to` set to the zero address.
	* Emits a {Burn} event with `amount` burned.
	*
	* Requirements:
	*
	* - `account` cannot be the zero address.
	* - `account` must have at least `amount` tokens.
	* - `account` can't be locked.
	*/
	function _burn(address account, uint256 amount) internal isUnlocked virtual
	{
		require(account != address(0), "ERC20: burn from the zero address");
		
		require(!isAddressLocked(account), "Sender address is currently locked and can't burn funds");

		uint256 availableBalance = getAvailableBalance(account);
		require(availableBalance >= amount, "ERC20: burn amount exceeds available balance");
		
		_balances[account] -= amount;
		_totalSupply -= amount;

		emit Transfer(account, address(0), amount);
		emit Burn(account, amount);
	}
	
	/**
	* @dev Creates a new stake on `addr` with specific
	* amount and expiry date
	*
	* Emits a {Stake} event indicating stake parameters.
	*
	* Requirements:
	*
	* - `addr` cannot be the zero address.
	* - `addr` must have at least `amount` tokens.
	* - `addr` can't be locked.
	* - `expiry` date can't be set in the past.
	* - token can't be locked
	* - `addr` can't be locked
	*/
	function _stake(address addr, uint256 amount, uint256 expiry) internal isUnlocked returns (uint256, uint256)
	{
		require(addr != address(0), "Stake: can't stake on zero address");
		require(!isAddressLocked(addr), "Specified address is currently locked and can't stake funds");
		
		require(expiry > block.timestamp, "Stake would expiry in the past");
		
		uint256 available = getAvailableBalance(addr);
		require(available >= amount, "There's not enough funds on address to stake the specific amount");
		
		cleanupStakes(addr);
		
		_stakes[addr].push(StakeData({amount:amount, expiry:expiry}));
		
		emit Stake(addr, amount, expiry);
		
		available -= amount;
		return (available, _balances[addr] - available);
	}
}