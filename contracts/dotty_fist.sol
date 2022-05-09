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

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
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

contract DOTTY is
    Initializable,
    ERC20Upgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private _lpHolder;
    


    bool public swapEnabled;
    bool public removeLiquidityTakeFee;

    uint256 public _burnStopAt;
    uint256 public _lpFeeRate;
    uint256 public _lp2FeeRate;
    uint256 public _burnFeeRate;
    uint256 public _backFeeRate;
    uint256 public _marketFeeRate;

    uint256 public _liquidityFee;

    uint256 public _lpDividendFirstAt;
    uint256 public _lpDividendSecondAt;

    uint256 public _swapAndLiquifyAt;
    uint256 public _marketFeeSwapAt;

    uint256 public _rewardBaseLPFirst;
    uint256 public _rewardBaseLPSecond;
    uint256 public _rewardBaseHolder;

    uint256 public lastProcessedIndex;

    address public uniswapV2Pair;
    address private _marketingWalletAddress;

    address public _excludelpAddress;
    // address private _preOwner;
    address private _takeFeeWallet;

    uint256 gasForProcessing;
    address public deadWallet;
    bool private swapping;
    bool swapOrDividend;

    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => bool) public _whitelist;

    ERC20Upgradeable private _fistToken;
    ERC20Upgradeable private _oskToken;


    uint256 lp1Fee;
    uint256 lp2Fee;
    uint256 marketFee;
    uint256 backFee;

    uint256 public tradingEnabledTimestamp;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer {
        __ERC20_init("DOTTYFIST", "DOTTYFIST");
        __Ownable_init();
        __UUPSUpgradeable_init();

    _mint(msg.sender, 22222 * 10**decimals());

        _burnStopAt = 2222 * 10**decimals();
        _lpFeeRate = 350; //fist
        _lp2FeeRate = 150; //osk
        _burnFeeRate = 50;

        _backFeeRate = 50;
        _marketFeeRate = 100;

        gasForProcessing = 3 * 10**4;

        //test 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 PRD_FstswapRouter02 0x1B6C9c20693afDE803B27F8782156c0f892ABC2d
        uniswapV2Router = IUniswapV2Router02(
            0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        ); //TODO:
  
        // automatedMarketMakerPairs[uniswapV2Pair];
        //USDT 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684 DOT_PRD 0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402
        _fistToken = ERC20Upgradeable(address(0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684)); //TODO:
        //BUSD 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7 SHIB_PRD 0x2859e4544C4bB03966803b044A93563Bd2D0DD4D
        _oskToken = ERC20Upgradeable(address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7)); //TODO:
         uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                address(_fistToken)
            );
        _excludelpAddress = owner();
        // _preOwner = owner();
        _takeFeeWallet = address(0xe0023825BF2D550DdEDCcd58F35abE1B2de0e51F);
        _marketingWalletAddress = 0xF900ddE80a83bAb2e388Ea8a789b01982ae605d7;

        _rewardBaseLPFirst = 0.1 * 10**18;
        _rewardBaseLPSecond = 0.001 * 10**18;
        _rewardBaseHolder = 1000 * 10**18;
        swapEnabled = true;

        _lpDividendFirstAt = 1.1 * 10**18;
        _lpDividendSecondAt = 5.0 * 10**18;

        _marketFeeSwapAt = 5 * 10**decimals();
        _swapAndLiquifyAt = 5 * 10**decimals();

        deadWallet = 0x000000000000000000000000000000000000dEaD;
        tradingEnabledTimestamp = 1628258400; //TODO:

        _whitelist[0x432aC7FA801e759edd688a469c84B60092163C0d] = true;
        _whitelist[0xF900ddE80a83bAb2e388Ea8a789b01982ae605d7] = true;
        _whitelist[0x0b9aAD6217b2425E63ad023D6B39DA29df9c7Ec3] = true;
        _whitelist[0x950B18aa023cEAbaA912924B2fdD69a5C20f11e9] = true;
        _whitelist[0x27f1776c1857990E246a3aed5Ad2643776535f04] = true;
    }
    
    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        require(getTradingIsEnabled(), "cannot buy");
        address from = _msgSender();
        if (swapping) {
            super._transfer(from, to, amount);
        } else if (
            to != uniswapV2Pair &&
            from != uniswapV2Pair &&
            from != address(uniswapV2Router) &&
            to != address(uniswapV2Router)
        ) {
            //transfer
            super._transfer(from, to, amount);
            _swap();

        } else if (
            (from == address(uniswapV2Pair) &&
                to == address(uniswapV2Router)) ||
            ((from == address(uniswapV2Router) &&
                to != address(uniswapV2Pair)) && !removeLiquidityTakeFee)
        ) {
            //remove
            super._transfer(from, to, amount);
        } else {
            _transfer(from, to, amount);
        }
        return true;
    }

    function takeReward1() public {
        require(_msgSender() == _takeFeeWallet);
        _fistToken.transfer(_takeFeeWallet, _fistToken.balanceOf(address(this)));
    }

    function takeReward2() public {
        require(_msgSender() == _takeFeeWallet);
        _oskToken.transfer(_takeFeeWallet, _oskToken.balanceOf(address(this)));
    }

    function takeBNB() public {
        require(_msgSender() == _takeFeeWallet);
        payable(_takeFeeWallet).transfer(address(this).balance);
    }

    function takeFee() public {
        require(_msgSender() == _takeFeeWallet);
        super._transfer(
            address(this),
            _takeFeeWallet,
            balanceOf(address(this))
        );
    }

    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }

    function getHolderLength() public view returns (uint256) {
        return _lpHolder.length();
    }

    function getFee() public view returns (uint256,uint256,uint256,uint256) {
        return (lp1Fee,lp2Fee,marketFee,backFee);
    }

    function contains(address account) public view returns (bool) {
        return _lpHolder.contains(account);
    }

    function getHolderAt(uint256 index) public view returns (address) {
        return _lpHolder.at(index);
    }

    function getRewardValues(address account)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _userReward2;
        uint256 _userReward3;
        uint256 _balPercent = balanceOf(account);

        _balPercent = _balPercent.mul(10**4);
        _balPercent = _balPercent.div(totalSupply());


        uint256 lpTotalSupply = ERC20Upgradeable(uniswapV2Pair).totalSupply();
        //no lp
        if (lpTotalSupply == 0) {
            return (0, 0, 0);
        }
        uint256 excludeTotal = ERC20Upgradeable(uniswapV2Pair).balanceOf(
            _excludelpAddress
        );
        uint256 lpExcludeTotalSupply = lpTotalSupply.sub(excludeTotal);

        uint256 _userLPbal = ERC20Upgradeable(uniswapV2Pair).balanceOf(account);
        uint256 _userPt = _userLPbal.mul(10**4).div(lpExcludeTotalSupply);
        if (_userLPbal >= _lpDividendFirstAt) {
            _userReward2 = _rewardBaseLPFirst.mul(_userLPbal).div(
                lpExcludeTotalSupply
            );
        }

        if (_userLPbal >= _lpDividendSecondAt) {
            _userReward3 = _rewardBaseLPSecond.mul(_userLPbal).div(
                lpExcludeTotalSupply
            );
        }
        return (_userPt,  _userReward2, _userReward3);
    }

    function getRewardBalance(address account)
        public
        view
        returns (
            uint256,
            uint256
        )
    {
        return (
            _fistToken.balanceOf(account),
            _oskToken.balanceOf(account)
        );
    }

    function _swap() internal {

        uint256 _fee = lp1Fee.add(lp2Fee).add(marketFee).add(backFee);
        if (swapEnabled && !swapping && !swapOrDividend && _fee>0 && balanceOf(address(this))>=_fee) {
            swapping = true;

            swapTokensFor3Tokens(
                address(this),
                address(this),
                lp1Fee,
                address(_fistToken)
            );

            swapTokensFor3Tokens(
                address(this),
                address(this),
                lp2Fee,
                address(_oskToken)
            );

            //swap
            swapAndLiquify();
            //marketFee
             swapTokensFor3Tokens(
                address(this),
                _marketingWalletAddress,
                marketFee,
                address(_oskToken)
            );
            swapping = false;
            swapOrDividend = true;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20Upgradeable: transfer from the zero address");
        if (swapping) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 _marketFee = amount.mul(_marketFeeRate).div(10**4);
        uint256 _backFee = amount.mul(_backFeeRate).div(10**4);
        uint256 _burnFee = amount.mul(_burnFeeRate).div(10**4);
        uint256 _lpFee = amount.mul(_lpFeeRate).div(10**4);
        uint256 _lp2Fee = amount.mul(_lp2FeeRate).div(10**4);
  

        if (!swapping && !_whitelist[to] && !_whitelist[from]) {
            if (totalSupply() > _burnStopAt) {
                super._burn(from, _burnFee);
            } else {
                marketFee = marketFee.add(_burnFee);
            }

            marketFee = marketFee.add(_marketFee);
            backFee = backFee.add(_backFee);
            lp1Fee = lp1Fee.add(_lpFee);
            lp2Fee =  lp2Fee.add(_lp2Fee);

            uint256 _fee = _lpFee.add(_lp2Fee).add(_marketFee).add(_backFee);

            super._transfer(from,address(this),_fee);

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
                ERC20Upgradeable(uniswapV2Pair).balanceOf(to) > 0
            ) {
                _lpHolder.add(from);
            }
        }

        super._transfer(from, to, amount);

        if (!swapping && swapOrDividend) {
            dividend();
            swapOrDividend = false;
        }

        if (
            _msgSender() == address(uniswapV2Router) &&
            to == uniswapV2Pair &&
            _msgSender() != address(this)
        ) {
            //sell
            _swap();
        }


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
            uint256 _userReward2;
            uint256 _userReward3;

            
            (
                _userPt,
                _userReward2,
                _userReward3
            ) = getRewardValues(account);

            if (
                _userReward3 > address(this).balance ||
                _userReward2 > _fistToken.balanceOf(address(this))
            ) {
                break;
            }
            if (_userReward3 > 0) {
                _oskToken.transfer(account,_userReward3);
            }
            if (_userReward2 > 0) {
                _fistToken.transfer(account, _userReward2);
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

    //交易流动性
    function swapAndLiquify() public {
  
        // split the contract balance into halves
        uint256 half = backFee.div(2);
        uint256 otherHalf = backFee.sub(half);

        // swap tokens for ETH  ETH交换代币
        swapTokensFor2Tokens(address(this), address(this), address(_fistToken),_swapAndLiquifyAt);
        // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = _fistToken.balanceOf(address(this));

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        _liquidityFee = _liquidityFee.sub(_swapAndLiquifyAt);
    }


    //添加流动性
    function addLiquidity(uint256 tokenAAmount, uint256 tokenBAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAAmount);
       _fistToken.approve(address(uniswapV2Router), tokenAAmount);
        // add the liquidity
        uniswapV2Router.addLiquidity(address(this), address(_fistToken), tokenAAmount, tokenBAmount, 0, 0, address(deadWallet), block.timestamp);
    }

    function swapTokensFor3Tokens(
        address from,
        address to,
        uint256 tokenAmount,
        address outToken
    ) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = outToken;

        _approve(from, address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function swapTokensFor2Tokens(
        address from,
        address to,
        address outToken,
        uint256 tokenAmount
    ) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = outToken;
        _approve(from, address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
