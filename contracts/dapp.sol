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

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        token0 = ERC20Upgradeable(
            address(0xA61cA8d36b29B8920dD9aB3E61BAFf23eB5463eE)
        );
        token1 = ERC20Upgradeable(
            address(0x4d67D4324cef36C2d6c4dc17e33b38beD1CCd7Cc)
        );

        refTokens[address(token0)][address(token1)] = 10000;
    }

    receive() external payable {}

    function getVars(address user, ERC20Upgradeable fromToken, ERC20Upgradeable toToken) public view returns (uint256, uint256,uint256, uint256,uint256,uint256) {
        return (
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this)),
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
    ) public {
        refTokens[address(fromToken)][address(toToken)] = _rate;
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
            toAmount = amount.div(_rate).div(10**4);
        }

        fromToken.transferFrom(sender, address(this), amount);
        toToken.transfer(sender, toAmount);
    }
}
