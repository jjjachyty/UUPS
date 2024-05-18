// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @title ERC314
 * @dev Implementation of the ERC314 interface.
 * ERC314 is a derivative of ERC20 which aims to integrate a liquidity pool on the token in order to enable native swaps, notably to reduce gas consumption.
 */

// Events interface for ERC314
interface IEERC314 {
    event AddLiquidity(uint32 _blockToUnlockLiquidity, uint256 value);
    event RemoveLiquidity(uint256 value);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out
    );
    event Pledge(address indexed sender, uint256 value);
    event RemovePledge(address indexed sender, uint256 value);
}

contract BT2 is
    IEERC314,
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    uint256 private _totalSupply;
    uint256 private _bnbTotalSupply;
    uint256 public _maxBuyAmount;
    uint256 public _maxSellAmount;
    uint256 public _fireStopAmount;

    string private _name;
    string private _symbol;

    address public liquidityProvider;

    bool public maxWalletEnable;
    address public marketAddress;
    address public ecoAddress;
    address public feeAddress;
    address[] public nodeAddress;
    mapping(address => uint256) public nodeAddressRelation;
    address[] public communityAddress;
    uint256 public communityBonus;
    uint256 public _nodeLimitAmount;
    uint256 public tradeFeeAmount;
    mapping(address => address) public relation;
    mapping(address => uint256) public communityCount;
    mapping(address => uint256) public pledgeReceiptRelation;
     uint256 public lastRewardAt;
    ERC20Upgradeable zToken;
    uint256 openTradeAt;

    // uint256 presaleAmount;
    mapping(address => uint32) private lastTransaction;
 

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("BT2", "BT2");
        _totalSupply = 990000000 * 10 ** decimals(); //3.1亿
        _bnbTotalSupply = 1200 * 10 ** decimals();
        _fireStopAmount = 10000000 * 10 ** decimals();
        _nodeLimitAmount = 500000 * 10 ** decimals(); //50w node
        _maxSellAmount = 50000 * 10 ** decimals(); //最多
        _maxBuyAmount = 200000 * 10 ** decimals(); //最多
        ecoAddress = 0x98A8790028C6476b740BE640627a62496E5d616b;
         marketAddress = 0x7a6CA6A66B7CA223ecD10ef837895F7a32e902d4;
        feeAddress = 0xBEddDAE2062F0b573ec72562F88da141A67b70B2;
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        _mint(address(this), 440000000 * 10 ** decimals());
        _mint(ecoAddress, 550000000 * 10 ** decimals());
        openTradeAt = 1716098400;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function getPledgeReceiptRelation(
        address addr
    ) public view returns (uint256) {
        return pledgeReceiptRelation[addr];
    }

    function getNodeAddress() public view returns (address[] memory) {
        return nodeAddress;
    }
    function setOpenTradeAt(uint256 _t) public onlyOwner {
        openTradeAt = _t;
    }

    function setZToken(ERC20Upgradeable _token) public onlyOwner {
        zToken = _token;
    }

    function removePledgeReceiptRelation(address addr) external {
        require(msg.sender==address(zToken),"No permission");
        uint256 value = pledgeReceiptRelation[addr];
        require(value > 0, "no pledge");
        super._transfer(address(zToken), addr, value);
        _nodeCheck(addr);
        delete pledgeReceiptRelation[addr];
        emit RemovePledge(addr, value);
    }

    function removeNodeAddress(uint256 index,address _addr)  internal   {
         nodeAddress[index] = nodeAddress[nodeAddress.length - 1];
         nodeAddress.pop();
        delete nodeAddressRelation[_addr];
    }

    function _nodeHandler(uint256 amount) internal {
        uint256 _nodeAmount = (amount * 15) / 1000;
        if (nodeAddress.length == 0) {
            super._update(address(this), feeAddress, _nodeAmount);
            return;
        }
        uint256 eachBouns = _nodeAmount / nodeAddress.length;
        for (uint256 i = 0; i < nodeAddress.length; i++) {
            if (nodeAddress[i] == address(0)) {
                continue;
            }

            if (super.balanceOf(nodeAddress[i]) >= _nodeLimitAmount) {
                super._update(address(this), nodeAddress[i], eachBouns);
            } else {
                removeNodeAddress(i,nodeAddress[i]);
            }
        }
    }

    function _nodeCheck(address _addr) public {
        if (_addr == ecoAddress || _addr == address(this)) return;
        uint256 index =nodeAddressRelation[_addr];

        if (index>0 && super.balanceOf(_addr) < _nodeLimitAmount){
            removeNodeAddress(index-1,_addr);
            return;
        }

        if (index ==0 && super.balanceOf(_addr) >= _nodeLimitAmount) {
            nodeAddress.push(_addr);
            nodeAddressRelation[_addr] = nodeAddress.length;
            return;
        }
    }

    function _marketHandler(uint256 bnbAmount) internal {
        payable(marketAddress).transfer((bnbAmount * 15) / 1000);
    }

    function _bindRelation(address from, address to) internal {
        if (
            relation[to] == address(0x0) &&
            from != to &&
            to != address(this) &&
            to != marketAddress &&
            to != ecoAddress &&
            to != feeAddress
        ) {
            relation[to] = from;
        }
    }

    function _relationHandler(address from, uint256 amount) internal {
        address parentAddress = relation[from];
        if (parentAddress == address(0x0)) {
            parentAddress = feeAddress;
        }
        super._update(address(this), parentAddress, (amount * 10) / 1000);
    }

    function _fireHandler(uint256 amount) internal {
        uint256 _fireAmount = (amount * 10) / 1000;
        if (_totalSupply - _fireAmount < _fireStopAmount) {
            _fireAmount = _totalSupply - _fireStopAmount;
        }
        if (_fireAmount > 0 && super.balanceOf(address(this)) > _fireAmount) {
            super._update(address(this), address(0x0), _fireAmount);
        }
    }

    function _tradeFee(uint256 amount) internal {
        uint256 _ecoAmount = (amount * 5) / 100;
        super._update(address(this), ecoAddress, _ecoAmount);
        tradeFeeAmount += _ecoAmount;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `value`.
     * - if the receiver is the contract, the caller must send the amount of tokens to sell
     */
    function transfer(
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        address from = msg.sender;
        if (to == address(this)) {
            sell(value);
         } else if (to == address(zToken)) {
            require(
                value == 30000 * 10 ** decimals() ||
                    value == 100000 * 10 ** decimals() ||
                    value == 300000 * 10 ** decimals() ||
                    value == 500000 * 10 ** decimals(),
                "3w/10w/30w/50w"
            );
            require(pledgeReceiptRelation[from] == 0, "Already pledged");
            super._transfer(from, to, value);
            pledgeReceiptRelation[from] = value;
            zToken.transfer(from, value / 5000);
             emit Pledge(from, value);
        } else {
            uint256 _minLeftAmount = 1 * 10 ** (decimals() - 6);
            if (value == super.balanceOf(from)) {
                if (super.balanceOf(from) > _minLeftAmount) {
                    value = super.balanceOf(from) - _minLeftAmount;
                } else {
                    return true;
                }
            }
            super._update(from, to, value);
            _bindRelation(from, to);
            _nodeCheck(to);
        }
         _nodeCheck(from);
        return true;
    }

    /**
     * @dev Returns the amount of BNB and tokens in the contract, used for trading.
     */
    function getReserves() public view returns (uint256, uint256) {
        return (_bnbTotalSupply, super.balanceOf(address(this)));
    }

 
 

    /**
     * @dev Estimates the amount of tokens or BNB to receive when buying or selling.
     * @param value: the amount of BNB or tokens to swap.
     * @param _buy: true if buying, false if selling.
     */
    function getAmountOut(
        uint256 value,
        bool _buy
    ) public view returns (uint256) {
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
        require(block.timestamp > openTradeAt,"not opened");
        lastTransaction[msg.sender] = uint32(block.number);

        uint256 bnbAmount = msg.value;
        uint256 token_amount = (bnbAmount * super.balanceOf(address(this))) /
            (_bnbTotalSupply + bnbAmount);
        require(token_amount <= _maxBuyAmount, "Max Limit Buy");
        super._update(address(this), msg.sender, (token_amount * 95) / 100);
        _bnbTotalSupply += ((bnbAmount * 985) / 1000);

        _marketHandler(msg.value);
        _nodeHandler(token_amount);
        _relationHandler(msg.sender, token_amount);
        _tradeFee(token_amount);
        _nodeCheck(msg.sender);
        _fireHandler(token_amount);
        emit Swap(msg.sender, msg.value, 0, 0, token_amount);
    }

    function sell(uint256 sell_amount) internal {
        require(
            lastTransaction[msg.sender] != block.number,
            "You can't make two transactions in the same block"
        );

        lastTransaction[msg.sender] = uint32(block.number);
        require(sell_amount <= _maxSellAmount, "Max Limit Sell");
        uint256 bnbAmount = (sell_amount * _bnbTotalSupply) /
            (super.balanceOf(address(this)) + sell_amount);

        require(bnbAmount > 0, "Sell amount too low");
        require(_bnbTotalSupply >= bnbAmount, "Insufficient BNB in reserves");
        require(address(this).balance>=bnbAmount,"Insufficient BNB in balance");

        super._update(msg.sender, address(this), sell_amount);

        _bnbTotalSupply -= ((bnbAmount * 965) / 1000);
        _marketHandler(bnbAmount);
        _nodeHandler(sell_amount);
        _relationHandler(msg.sender, sell_amount);
        _tradeFee(sell_amount);
        _fireHandler(sell_amount);
        payable(msg.sender).transfer((bnbAmount * 95) / 100);
        emit Swap(msg.sender, 0, sell_amount, bnbAmount, 0);
    }

    /**
     * @dev Fallback function to buy tokens with BNB.
     */
    receive() external payable {
        buy();
    }

    function transferBatch(
        address[] calldata _address,
        uint256[] calldata _amounts
    ) public {
        for (uint256 index = 0; index < _address.length; index++) {
              super._update(msg.sender,_address[index], _amounts[index]);
        }
    }
}
