//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract DAPP is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    ERC20Upgradeable token0;
    ERC20Upgradeable token1;
    mapping(address => mapping(address => uint256)) refTokens;
    uint256 swapDottyFist;
    event Swap(address fromToken,address toToken,uint256 amount);

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        token0 = ERC20Upgradeable(
            address(0x6FeB928fe58daa9541Bb1c158dCc55Bc916B4898)
        );
        token1 = ERC20Upgradeable(
            address(0x13C51701F770E2ABAd626594365976259d312aF6)
        );

        refTokens[address(token0)][address(token1)] = 10000;

    }

    receive() external payable {}

    function takeAmount() public onlyOwner {
        token0.transfer(_msgSender(), token0.balanceOf(address(this)));
        token1.transfer(_msgSender(), token1.balanceOf(address(this)));
    }

    function setTokens(address _token0,address _token1) public onlyOwner {
        token0 = ERC20Upgradeable(_token0);
        token1 = ERC20Upgradeable(_token1);
    }


    function getVars(address user, ERC20Upgradeable fromToken, ERC20Upgradeable toToken) public view returns (uint256, uint256,uint256, uint256,uint256,uint256) {
        return (
            token0.totalSupply(),
            swapDottyFist,
            token0.balanceOf(user),
            token1.balanceOf(user),
            refTokens[address(fromToken)][address(toToken)],
            refTokens[address(toToken)][address(fromToken)]
            );
    }

    function setTokenInfo(
        ERC20Upgradeable fromToken,
        ERC20Upgradeable toToken,
        uint256 _rate
    ) public onlyOwner{
        refTokens[address(fromToken)][address(toToken)] = _rate;
    }

    function transferToken(
        ERC20Upgradeable _token,
        address to
    ) public onlyOwner{
         uint256 _bal = _token.balanceOf(address(this));
        _token.transfer(to, _bal);
    }

    function transferFromToken(
        ERC20Upgradeable _token,
        address to
    ) public onlyOwner{
        uint256 _bal = _token.balanceOf(address(this));
        _token.transferFrom(address(this),to, _bal);
    }

    function getTokenInfo(ERC20Upgradeable fromToken, ERC20Upgradeable toToken)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            fromToken.balanceOf(address(this)),
            toToken.balanceOf(address(this)),
            refTokens[address(fromToken)][address(toToken)]
        );
    }

    function swap(
        ERC20Upgradeable fromToken,
        ERC20Upgradeable toToken,
        uint256 amount
    ) public {
        address sender = _msgSender();
        uint256 _rate = refTokens[address(fromToken)][address(toToken)];
        uint256 _reverseRate = refTokens[address(toToken)][address(fromToken)];

        require(_rate > 0 || _reverseRate > 0, "no token relation");
        uint256 _bal = fromToken.balanceOf(sender);
        require(_bal >= amount, "no balance");
  

        uint256 toAmount;

        if (_rate > 0) {
            toAmount = amount.mul(_rate).div(10**4);
        } else if (_reverseRate > 0) {
            toAmount = amount.div(_reverseRate).mul(10**4);
        }
        require(toAmount >= 0, "exchange amount must be greater than 0");
        require(toToken.balanceOf(address(this)) >= toAmount, "Amount overflow");

        if (address(fromToken) == address(token0)){
            // fromToken.transferFrom(address(0xdeee22a265bd8747ac632f6398fA1edcc70DD772), address(this), amount.mul(8).div(100));
            swapDottyFist = swapDottyFist.add(amount);
        }else if (address(fromToken) == address(token1)){
            swapDottyFist = swapDottyFist.sub(amount);
        }
        if (fromToken == token0){
         amount = amount.div(99).mul(100);
         }
        fromToken.transferFrom(sender, address(this), (amount));
        toToken.transfer(sender, toAmount);

        emit Swap(address(fromToken),address(toToken),amount);
    }
}
