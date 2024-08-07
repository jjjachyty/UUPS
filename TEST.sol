// Sources flattened with hardhat v2.22.2 https://hardhat.org

// SPDX-License-Identifier: MIT

// File backup/bscerc314.sol

// Sources flattened with hardhat v2.22.2 https://hardhat.org

// Original license: SPDX_License_Identifier: MIT

// File backup/bscerc314.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ERC314
 * @dev Implementation of the ERC314 interface.
 * ERC314 is a derivative of ERC20 which aims to integrate a liquidity pool on the token in order to enable native swaps, notably to reduce gas consumption.
 */

// Events interface for ERC314
interface IEERC314 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event AddLiquidity(uint32 _blockToUnlockLiquidity, uint256 value);
    event RemoveLiquidity(uint256 value);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out
    );
}

contract TEST  is IEERC314 {
    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;
    uint256 private _bnbTotalSupply;
    uint256 public _maxWallet;
    uint256 public _maxSellAmount;
    uint256 public _fireStopAmount;

    string private _name;
    string private _symbol;

    address public owner;
    address public liquidityProvider;

    bool public maxWalletEnable;
    address public marketAddress;
    address public ecoAddress;
    address public feeAddress;
    address[] public nodeAddress;
    address[] public communityAddress;
    uint256 public communityBonus;
    uint256 public _nodeLimitAmount;
    mapping(address => address) public relation;
    mapping(address => uint256) public communityCount;
    uint256 public lastRewardAt;

    // uint256 presaleAmount;

    bool public presaleEnable = false;

    mapping(address => uint32) private lastTransaction;

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyLiquidityProvider() {
        require(
            msg.sender == liquidityProvider,
            "You are not the liquidity provider"
        );
        _;
    }
 

    constructor(){
        _name = "TEST";
        _symbol = "TEST";
        _totalSupply =  990000000 * 10**8; //3.1亿
        _bnbTotalSupply = 300 * 10**18;
        _fireStopAmount = 10000000 * 10**8;
        _maxWallet = 500000 * 10**8; //50w
        _nodeLimitAmount = 500000 * 10**8; //50w node
        _maxSellAmount = 50000 * 10**8; //最多
        owner = msg.sender;
        ecoAddress = 0x98A8790028C6476b740BE640627a62496E5d616b;
        maxWalletEnable = true;
        _balances[address(this)] = 110000000 * 10**8;
        _balances[ecoAddress] = 880000000 * 10**8;
        marketAddress = 0x7a6CA6A66B7CA223ecD10ef837895F7a32e902d4;
        feeAddress = 0xBEddDAE2062F0b573ec72562F88da141A67b70B2;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */

    function decimals() public view virtual returns (uint8) {
        return 8;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function removeNodeAddress(uint256 index) public {
        // Move the last element into the place to delete
        nodeAddress[index] = nodeAddress[nodeAddress.length - 1];
        // Remove the last element
        nodeAddress.pop();
    }

    function _nodeHandler(uint256 amount) internal {
        uint256 _nodeAmount = (amount * 15) / 1000;
        if (nodeAddress.length == 0) {
             _transfer(address(this), feeAddress, _nodeAmount);
            return;
        }
        uint256 eachBouns =  _nodeAmount / nodeAddress.length;
        for (uint256 i = 0; i < nodeAddress.length; i++) {
            if (nodeAddress[i] == address(0)) {
                continue;
            }

            if (_balances[nodeAddress[i]] >= _nodeLimitAmount) {
                 _transfer(address(this), nodeAddress[i], eachBouns);
            } else {
                removeNodeAddress(i);
            }
        }
    }

    function _nodeAdd(address _addr) internal {
        if (_balances[_addr] >= _nodeLimitAmount) {
            nodeAddress.push(_addr);
        }
    }

    function _marketHandler(uint256 bnbAmount) internal {
        payable(marketAddress).transfer((bnbAmount * 15) / 1000);
    }

    function _bindRelation(address from, address to) internal {
        if (
            relation[to] == address(0x0) && from != to &&
            to != address(this) &&
            to != marketAddress &&
            to != ecoAddress &&
            to != feeAddress
        ) {
            relation[to] = from;
        }
    }

    // function _communityAdd(address _addr, uint256 _bnbAmount) internal {
    //     address _parentAddress = relation[_addr];
    //     if (_bnbAmount >= 5 * 10**17) {
    //         //0.5bnb
    //         communityCount[_parentAddress]++;
    //     }
    //     if (communityCount[_parentAddress] == 10) {
    //         communityAddress.push(_parentAddress);
    //     }
    // }

    function _relationHandler(address from, uint256 amount) internal {
        address parentAddress = relation[from];
        if (parentAddress == address(0x0)) {
            parentAddress = feeAddress;
        }
         _transfer(address(this), parentAddress, (amount * 10) /1000);
    }

    function _fireHandler(uint256 amount) internal {
        uint256 _fireAmount = (amount * 10) / 1000;
        if (_totalSupply - _fireAmount < _fireStopAmount) {
            _fireAmount = _totalSupply - _fireStopAmount;
        }
        if (_fireAmount > 0 && _balances[address(this)] > _fireAmount) {
            _transfer(address(this), address(0x0), _fireAmount);
        }
    }

    // function _communityHandler(uint256 _token) internal {
    //     communityBonus += (_token * 10) / 1000;
    //     if ((block.timestamp - lastRewardAt) > 0 && communityAddress.length > 0) {
    //         uint256 _eachAmount = communityBonus / communityAddress.length;

    //         for (uint256 i = 0; i < communityAddress.length; i++) {
    //             _balances[communityAddress[i]] += _eachAmount;
    //             emit Transfer(address(this), communityAddress[i], _eachAmount);
    //         }

    //         communityBonus = 0;
    //         lastRewardAt = block.timestamp;
    //     }
    // }

    function _tradeFee(uint256 amount) internal {
        uint256 _ecoAmount = (amount * 5) / 100;
         _transfer(address(this), ecoAddress, _ecoAmount);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `value`.
     * - if the receiver is the contract, the caller must send the amount of tokens to sell
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        // sell or transfer
        if (to == address(this)) {
            sell(value);
        } else {
            uint256 _minLeftAmount = 1 * 10**(decimals() - 6);
            if (value == _balances[msg.sender]) {
                if (_balances[msg.sender] > _minLeftAmount) {
                    value = _balances[msg.sender] - _minLeftAmount;
                } else {
                    return true;
                }
            }
            _transfer(msg.sender, to, value);
            _nodeAdd(to);
            _bindRelation(msg.sender,to);
        }
        return true;
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively burns if `to` is the zero address.
     * All customizations to transfers and burns should be done by overriding this function.
     * This function includes MEV protection, which prevents the same address from making two transactions in the same block.(lastTransaction)
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        require(
            _balances[from] >= value,
            "ERC20: transfer amount exceeds balance"
        );

        unchecked {
            _balances[from] = _balances[from] - value;
        }

        if (to == address(0)) {
            unchecked {
                _totalSupply -= value;
            }
        } else {
            unchecked {
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Returns the amount of BNB and tokens in the contract, used for trading.
     */
    function getReserves() public view returns (uint256, uint256) {
        return (_bnbTotalSupply, _balances[address(this)]);
    }

    /**
     * @dev Enables or disables the max wallet.
     * @param _maxWalletEnable: true to enable max wallet, false to disable max wallet.
     * onlyOwner modifier
     */
    function enableMaxWallet(bool _maxWalletEnable) external onlyOwner {
        maxWalletEnable = _maxWalletEnable;
    }

    /**
     * @dev Sets the max wallet.
     * @param _maxWallet_: the new max wallet.
     * onlyOwner modifier
     */
    function setMaxWallet(uint256 _maxWallet_) external onlyOwner {
        _maxWallet = _maxWallet_;
    }

    /**
     * @dev Transfers the ownership of the contract to zero address
     * onlyOwner modifier
     */
    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

    /**
     * @dev Estimates the amount of tokens or BNB to receive when buying or selling.
     * @param value: the amount of BNB or tokens to swap.
     * @param _buy: true if buying, false if selling.
     */
    function getAmountOut(uint256 value, bool _buy)
        public
        view
        returns (uint256)
    {
        (uint256 reservebnb, uint256 reserveToken) = getReserves();

        if (_buy) {
            return (value * reserveToken) / (reservebnb + value);
        } else {
            return (value * reservebnb) / (reserveToken + value);
        }
    }

    /**
     * @dev Buys tokens with BNB.
     * internal function
     */
    function buy() internal {
        require(
            lastTransaction[msg.sender] != block.number,
            "You can't make two transactions in the same block"
        );

        lastTransaction[msg.sender] = uint32(block.number);

        uint256 bnbAmount = msg.value;
        uint256 token_amount = (bnbAmount * _balances[address(this)]) /
            (_bnbTotalSupply+bnbAmount);

        if (maxWalletEnable) {
            require(
                token_amount + _balances[msg.sender] <= _maxWallet,
                "Max wallet exceeded"
            );
        }

        _transfer(address(this), msg.sender, (token_amount * 95) / 100);
        _bnbTotalSupply += ((bnbAmount * 985) / 1000);

        _marketHandler(msg.value);
        _nodeHandler(token_amount);
        _relationHandler(msg.sender, token_amount);
        _tradeFee(token_amount);
        _nodeAdd(msg.sender);
        // _communityAdd(msg.sender,msg.value);
        // _communityHandler(token_amount);
        _fireHandler(token_amount);
        emit Swap(msg.sender, msg.value, 0, 0, token_amount);
    }

    /**
     * @dev Sells tokens for BNB.
     * internal function
     */

    // Execute the operation that consumes gas
    // ...

    function sell(uint256 sell_amount) internal  {
        require(
            lastTransaction[msg.sender] != block.number,
            "You can't make two transactions in the same block"
        );

        lastTransaction[msg.sender] = uint32(block.number);
        // uint256 gasStart = gasleft();
        require(sell_amount <= _maxSellAmount, "Max Limit Sell");
        uint256 bnbAmount = (sell_amount * _bnbTotalSupply) /
            (_balances[address(this)] + sell_amount);

        require(bnbAmount > 0, "Sell amount too low");
        require(_bnbTotalSupply >= bnbAmount, "Insufficient BNB in reserves");
        _transfer(msg.sender, address(this), sell_amount);

        payable(msg.sender).transfer((bnbAmount * 95) / 100);
        _bnbTotalSupply -= (bnbAmount*965/1000) ;
        _marketHandler(bnbAmount);
        _nodeHandler(sell_amount);
        _relationHandler(msg.sender, sell_amount);
        _tradeFee(sell_amount);
        // _communityHandler(sell_amount);
        _fireHandler(sell_amount);
        // uint256 gasSpent = gasStart - gasleft();
        // payable(msg.sender).transfer(gasSpent * tx.gasprice);
        emit Swap(msg.sender, 0, sell_amount, bnbAmount, 0);
    }

    /**
     * @dev Fallback function to buy tokens with BNB.
     */
    receive() external payable {
        buy();
    }
}
