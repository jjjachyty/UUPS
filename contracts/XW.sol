// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

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

contract XW is ERC20, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _lpHolder;

    address marketAddress = 0x04c1E2d8D1D2069C9405240D156bf7004f1108ae;
    uint256 public lastProcessedIndex;
    uint256 gasForProcessing = 300000;
    uint256 baseReward = 4 * 10**18;

    uint256 buyFee = 300; //3%
    uint256 sellDividendFee = 200;
    uint256 sellMarketFee = 200;
    IUniswapV2Router02 public uniswapV2Router =
        IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public uniswapV2Pair;

    constructor() ERC20("XW", "XW") {
        _mint(msg.sender, 666 * 10**decimals());
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                address(0x55d398326f99059fF775485246999027B3197955)
            );
    }

    function setMarketAddress(address account) public onlyOwner {
        marketAddress = account;
    }

    function setBaseReward(uint256 _baseReward) public onlyOwner {
        baseReward = _baseReward;
    }

    function setFeeRate(
        uint256 _buyFee,
        uint256 _sellDividendFee,
        uint256 _sellMarketFee
    ) public onlyOwner {
        buyFee = _buyFee;
        sellDividendFee = _sellDividendFee;
        sellMarketFee = _sellMarketFee;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        uint256 dividendFee = amount.mul(sellDividendFee).div(10000);
        uint256 marketFee = amount.mul(sellMarketFee).div(10000);

        _transfer(from, address(this), dividendFee);
        _transfer(from, marketAddress, marketFee);

        _transfer(from, to, amount.sub(dividendFee).sub(marketFee));

        if (
            to != uniswapV2Pair &&
            to != address(uniswapV2Router) &&
            !_lpHolder.contains(to) &&
            ERC20(uniswapV2Pair).balanceOf(to) > 0
        ) {
            _lpHolder.add(to);
        }
        if (
            from != uniswapV2Pair &&
            from != address(uniswapV2Router) &&
            !_lpHolder.contains(from) &&
            ERC20(uniswapV2Pair).balanceOf(from) > 0
        ) {
            _lpHolder.add(from);
        }
        dividend();
        return true;
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address from = _msgSender();

        if (
            to != uniswapV2Pair &&
            from != uniswapV2Pair &&
            from != address(uniswapV2Router) &&
            to != address(uniswapV2Router)
        ) {
            _transfer(from, to, amount);
            return true;
        }
        uint256 fee = amount.mul(buyFee).div(10000);
        _transfer(from, address(this), fee);
        _transfer(from, to, amount.sub(fee));

        if (
            to != uniswapV2Pair &&
            to != address(uniswapV2Router) &&
            !_lpHolder.contains(to) &&
            ERC20(uniswapV2Pair).balanceOf(to) > 0
        ) {
            _lpHolder.add(to);
        }
        if (
            from != uniswapV2Pair &&
            from != address(uniswapV2Router) &&
            !_lpHolder.contains(from) &&
            ERC20(uniswapV2Pair).balanceOf(from) > 0
        ) {
            _lpHolder.add(from);
        }

        return true;
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
        returns (uint256, uint256)
    {
        uint256 _userReward;
        uint256 _balPercent = balanceOf(account);

        _balPercent = _balPercent.mul(10**4);
        _balPercent = _balPercent.div(totalSupply());

        uint256 lpTotalSupply = ERC20(uniswapV2Pair).totalSupply();
        //no lp
        if (lpTotalSupply == 0) {
            return (0, 0);
        }
        uint256 _userLPbal = ERC20(uniswapV2Pair).balanceOf(account);
        uint256 _userPt = _userLPbal.mul(10**4).div(lpTotalSupply);
        if (_userLPbal > 0) {
            _userReward = baseReward.mul(_userLPbal).div(lpTotalSupply);
        }

        return (_userPt, _userReward);
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
            uint256 _userPt;
            uint256 _userReward;

            (_userPt, _userReward) = getRewardValues(account);

            if (_userReward > balanceOf(address(this))) {
                break;
            }
            if (_userReward > 0) {
                _transfer(address(this),account, _userReward);
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
}
