// contract/MyTokenV1.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


contract XLToken is
    Initializable,
    ERC20Upgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private _lpHolder;

    uint256 public _lpFeeRate;
    uint256 public _burnFeeRate;

    uint256 public _rewardBaseLP;
    uint256 public lastProcessedIndex;

    address public uniswapV2Pair;
    address public _excludelpAddress;

    uint256 gasForProcessing;
    address public deadWallet;
    bool private swapping;
    bool public swapOrDividend;

    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => bool) public _whitelist;

    ERC20Upgradeable private _fonToken;


    uint256 public tradingEnabledTimestamp;
    address collectionWallet;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer {
        __ERC20_init("XL", "XL");
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 10000000 * 10**decimals());

        _lpFeeRate = 300; //fist
        _burnFeeRate = 100;


        gasForProcessing = 30 * 10**4;

        //test 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 PRD_FstswapRouter02 0x1B6C9c20693afDE803B27F8782156c0f892ABC2d
        uniswapV2Router = IUniswapV2Router02(
            0x1B6C9c20693afDE803B27F8782156c0f892ABC2d
        ); //TODO:
        collectionWallet = owner();

        // automatedMarketMakerPairs[uniswapV2Pair];
        //USDT 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684 FIST_PRD 0x12a055d95855b4ec2cd70c1a5eadb1ed43eaef65
        _fonToken = ERC20Upgradeable(
            address(0x12a055D95855b4Ec2cd70C1A5EaDb1ED43eaeF65)
        ); //TODO:

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                address(_fonToken)
            );

        _excludelpAddress = owner();
        _rewardBaseLP = 0.1 * 10**6;
        deadWallet = 0x000000000000000000000000000000000000dEaD;
        tradingEnabledTimestamp = 1628258400; //TODO:

        _whitelist[owner()] = true;
    }



    function setRewardBaseLP(
        uint256 rewardBaseLP
    ) public onlyOwner {
        _rewardBaseLP = rewardBaseLP;
    }

    function setFee(
        uint256 lpFeeRate,
        uint256 burnFeeRate
    ) public onlyOwner {
        _lpFeeRate = lpFeeRate;
        _burnFeeRate = burnFeeRate;
    }

    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }

    function getHolderLength() public view returns (uint256) {
        return _lpHolder.length();
    }


    function contains(address account) public view returns (bool) {
        return _lpHolder.contains(account);
    }

    function getHolderAt(uint256 index) public view returns (address) {
        return _lpHolder.at(index);
    }

    function holdeRremove(address account) public onlyOwner {
        _lpHolder.remove(account);
    }

    function HolderAdd(address account) public onlyOwner {
        _lpHolder.add(account);
    }

    function getRewardValues(address account)
        public
        view
        returns (
            uint256,
            uint256
        )
    {
        uint256 _userReward;
        uint256 _balPercent = balanceOf(account);

        _balPercent = _balPercent.mul(10**4);
        _balPercent = _balPercent.div(totalSupply());

        uint256 lpTotalSupply = ERC20Upgradeable(uniswapV2Pair).totalSupply();
        //no lp
        if (lpTotalSupply == 0) {
            return (0, 0);
        }
        uint256 excludeTotal = ERC20Upgradeable(uniswapV2Pair).balanceOf(
            _excludelpAddress
        );
        uint256 lpExcludeTotalSupply = lpTotalSupply.sub(excludeTotal);

        uint256 _userLPbal = ERC20Upgradeable(uniswapV2Pair).balanceOf(account);
        uint256 _userPt = _userLPbal.mul(10**4).div(lpExcludeTotalSupply);
        if (_userLPbal > 0) {
            _userReward = _rewardBaseLP.mul(_userLPbal).div(
                lpExcludeTotalSupply
            );
        }


        return (_userPt, _userReward);
    }

    function getRewardBalance(address account)
        public
        view
        returns (uint256, uint256)
    {
        return (_fonToken.balanceOf(account), balanceOf(account));
    }

    function _swap() public {
        if (
            !swapping &&
            balanceOf(address(this)) > 0
        ) {
   
            swapping = true;
            uint256 initialBalance = _fonToken.balanceOf(collectionWallet);
            swapTokensFor2Tokens(
                address(this),
                address(_fonToken),
                collectionWallet,
                balanceOf(address(this))
            );

            uint256 swapAmount = _fonToken.balanceOf(collectionWallet).sub(
                initialBalance
            );

            _fonToken.transferFrom(
                collectionWallet,
                address(this),
                swapAmount
            );
            swapping = false;
        }
    }

    event Log(uint256 t, address a, address b, address c, uint256 amount);

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        emit Log(1, _msgSender(), from, to, amount);

        if (swapping) {
            emit Log(2, _msgSender(), from, to, amount);

            super._transfer(from, to, amount);
            return;
        } else if (
            to != uniswapV2Pair &&
            from != uniswapV2Pair &&
            from != address(uniswapV2Router) &&
            to != address(uniswapV2Router)
        ) {
            //transfer
            emit Log(5, _msgSender(), from, to, amount);

            super._transfer(from, to, amount);
            return;
        } else if (
            !swapping &&
            !(from == address(uniswapV2Router) && to != address(uniswapV2Pair))
        ) {
            emit Log(4, _msgSender(), from, to, amount);

            //sell
            if (!swapOrDividend) {
                emit Log(8, _msgSender(), from, to, amount);
                _swap();
                swapOrDividend = true;
            } else {
                emit Log(9, _msgSender(), from, to, amount);
                dividend();
                swapOrDividend = false;
            }
        }
        emit Log(6, _msgSender(), from, to, amount);

        if (!swapping && !_whitelist[from]) {
            uint256 _burnFee = amount.mul(_burnFeeRate).div(10**4);
            uint256 _lpFee = amount.mul(_lpFeeRate).div(10**4);
  

            emit Log(7, _msgSender(), from, to, amount);

            super._burn(from, _burnFee);
            amount = amount.sub(_burnFee);

            super._transfer(from, address(this), _lpFee);
            amount = amount.sub(_lpFee);
        }

        if (
            to != uniswapV2Pair &&
            to != address(uniswapV2Router) &&
            to != _excludelpAddress &&
            !_lpHolder.contains(to) &&
            ERC20Upgradeable(uniswapV2Pair).balanceOf(to) > 0
        ) {
            _lpHolder.add(to);
        }
        if (
            from != uniswapV2Pair &&
            from != address(uniswapV2Router) &&
            from != _excludelpAddress &&
            !_lpHolder.contains(from) &&
            ERC20Upgradeable(uniswapV2Pair).balanceOf(from) > 0
        ) {
            _lpHolder.add(from);
        }

        super._transfer(from, to, amount);
    }

    function dividend() public {
        uint256 _gasLimit = gasForProcessing;

        uint256 numberOfTokenHolders = _lpHolder.length();
        if (numberOfTokenHolders == 0) {
            return;
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < _gasLimit && iterations < numberOfTokenHolders) {
            iterations++;
            if (_lastProcessedIndex >= _lpHolder.length()) {
                _lastProcessedIndex = 0;
            }

            address account = _lpHolder.at(_lastProcessedIndex);
            if (account == _excludelpAddress || account == owner()) {
                continue;
            }
            uint256 _userPt;
            uint256 _userReward;
  

            (_userPt, _userReward) = getRewardValues(account);

            if (
                _userReward > _fonToken.balanceOf(address(this))
            ) {
                break;
            }
            if (_userReward > 0) {
                _fonToken.transfer(account, _userReward);
            }
        

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
            _lastProcessedIndex++;
        }

        lastProcessedIndex = _lastProcessedIndex;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(
            newValue >= 200000 && newValue <= 500000,
            " gasForProcessing must be between 200,000 and 500,000"
        );
        require(
            newValue != gasForProcessing,
            " Cannot update gasForProcessing to same value"
        );
        gasForProcessing = newValue;
    }


    function swapTokensFor2Tokens(
        address inToken,
        address outToken,
        address to,
        uint256 tokenAmount
    ) private {
        address[] memory path = new address[](2);
        path[0] = inToken;
        path[1] = outToken;

        ERC20Upgradeable(inToken).approve(
            address(uniswapV2Router),
            tokenAmount
        );

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
}
