// contract/MyTokenV1.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

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

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

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

interface IPancakePair {
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

interface IPancakeERC20 {
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
}

contract SDZZToken is
    Initializable,
    ERC20Upgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private _lpHolder;
    bool public swapping;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    ERC20Upgradeable private _usdtToken;
    uint256 public sellFeeRate; //5%
    uint256 public rewardBase; //100U
    uint256 gasForProcessing;
    uint256 public lastProcessedIndex;
    address public dividendAddress;
    address public exceptAddress;
    mapping(address => bool) exceptList;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer {
        __ERC20_init("TEST001 Token", "TEST001");
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 100000000 * 10**decimals());
        //PRD 0x1B6C9c20693afDE803B27F8782156c0f892ABC2d  TEST 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        uniswapV2Router = IUniswapV2Router02(
            0x1B6C9c20693afDE803B27F8782156c0f892ABC2d
        );
        // PRD 0x55d398326f99059fF775485246999027B3197955 TEST 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684
        _usdtToken = ERC20Upgradeable(
            0x55d398326f99059fF775485246999027B3197955
        );
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                address(_usdtToken)
            );
        sellFeeRate = 500;
        rewardBase = 100 * 10**10; //100U
        dividendAddress = 0x3bD159586d0542b29ea4585e462ccDaCEa747777;
        exceptList[0x405Aa387B3Ec53070488E625cdd3aA6Cb187B60c] = true;
        exceptList[0x19459b3Cf9CA3E1E20A21103a0284d88e9b88520] = true;
        exceptList[0x5b6E8337Ad3F5e3504EE5d4400513892c3Fc0570] = true;
        exceptList[0x069d0300eDee1E79A3ca46523Ec0E0971eE31990] = true;
        exceptList[0x973Ac5Be80AAD428C77eA25839404Ec48339e5Ce] = true;
        exceptList[0x3a29ac0DA4801854e184c149c462dd4e39f49AFC] = true;
    }

    function addExceptList(address[] calldata lists) public onlyOwner {
        for (uint256 index = 0; index < lists.length; index++) {
            exceptList[lists[index]] = true;
        }
    }

    function setRewardBase(uint256 base) public onlyOwner {
        rewardBase = base;
    }

    function setSellFeeRate(uint256 rate) public onlyOwner {
        sellFeeRate = rate;
    }

    function setDividendAddress(address account) public onlyOwner {
        dividendAddress = account;
    }

    function setExceptAddress(address account) public onlyOwner {
        exceptAddress = account;
    }

    event Buy(address from, address to, uint256 amount);
    event Sell(address from, address to, uint256 amount);
    event AddLiquidity(address from, uint256 amount);
    event RemoveLiquidity(address from, uint256 amount);

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address from = _msgSender();

        if (
            to != uniswapV2Pair &&
            to != address(uniswapV2Router) &&
            !_lpHolder.contains(to) &&
            ERC20Upgradeable(uniswapV2Pair).balanceOf(to) > 0
        ) {
            _lpHolder.add(to);
        }
        if (
            from != uniswapV2Pair &&
            from != address(uniswapV2Router) &&
            !_lpHolder.contains(from) &&
            ERC20Upgradeable(uniswapV2Pair).balanceOf(from) > 0
        ) {
            _lpHolder.add(from);
        }

        if (
            to != uniswapV2Pair &&
            from != uniswapV2Pair &&
            from != address(uniswapV2Router) &&
            to != address(uniswapV2Router)
        ) {
            super._transfer(from, to, amount);
            return true;
        }

        (, uint256 _reserve1, ) = IPancakePair(uniswapV2Pair).getReserves();
        uint256 usdtBal = _usdtToken.balanceOf(uniswapV2Pair);

        if (usdtBal > _reserve1) {
            super._transfer(from, to, amount);
            emit Buy(from, to, amount);
            return true;
        }

        super._transfer(from, to, amount);
        emit RemoveLiquidity(to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (swapping || exceptList[from]) {
            super._transfer(from, to, amount);
            return true;
        }
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        (, uint256 _reserve1, ) = IPancakePair(uniswapV2Pair).getReserves();
        uint256 usdtBal = _usdtToken.balanceOf(uniswapV2Pair);

        if (usdtBal > _reserve1) {
            super._transfer(from, to, amount);
            emit AddLiquidity(from, amount);
            return true;
        }
        swap();
        uint256 sellFee = amount.mul(sellFeeRate).div(10**4);
        uint256 leftFee = amount.sub(sellFee);

        super._transfer(from, address(this), sellFee);
        super._transfer(from, to, leftFee);

        if (
            to != uniswapV2Pair &&
            to != address(uniswapV2Router) &&
            !_lpHolder.contains(to) &&
            ERC20Upgradeable(uniswapV2Pair).balanceOf(to) > 0
        ) {
            _lpHolder.add(to);
        }
        if (
            from != uniswapV2Pair &&
            from != address(uniswapV2Router) &&
            !_lpHolder.contains(from) &&
            ERC20Upgradeable(uniswapV2Pair).balanceOf(from) > 0
        ) {
            _lpHolder.add(from);
        }
        dividend();
        emit Sell(from, to, amount);
        return true;
    }

    function swap() public {
        if (
            !swapping &&
            balanceOf(address(this)) > 0 &&
            balanceOf(uniswapV2Pair) > balanceOf(address(this))
        ) {
            swapping = true;
            swapTokensFor2Tokens(
                address(this),
                address(_usdtToken),
                dividendAddress,
                balanceOf(address(this))
            );
            swapping = false;
        }
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
            uint256 _userReward = getRewardValues(account);

            if (_userReward > _usdtToken.balanceOf(dividendAddress)) {
                break;
            }
            if (_userReward > 0) {
                _usdtToken.transferFrom(dividendAddress, account, _userReward);
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

    function getRewardValues(address account) public view returns (uint256) {
        uint256 _userReward;
        uint256 _balPercent = balanceOf(account);

        _balPercent = _balPercent.mul(10**4);
        _balPercent = _balPercent.div(totalSupply());

        uint256 lpTotalSupply = ERC20Upgradeable(uniswapV2Pair).totalSupply();

        //no lp
        if (lpTotalSupply == 0) {
            return 0;
        }
        uint256 exceptAmount = ERC20Upgradeable(uniswapV2Pair).balanceOf(
            exceptAddress
        );
        lpTotalSupply = lpTotalSupply.sub(exceptAmount);

        uint256 _userLPbal = ERC20Upgradeable(uniswapV2Pair).balanceOf(account);
        if (_userLPbal > 0) {
            _userReward = rewardBase.mul(_userLPbal).div(lpTotalSupply);
        }

        return (_userReward);
    }

    function getBalance(address account)
        public
        view
        returns (uint256, uint256)
    {
        return (_usdtToken.balanceOf(account), balanceOf(account));
    }

    function getLpPercentage(address account) public view returns (uint256) {
        uint256 lpTotalSupply = ERC20Upgradeable(uniswapV2Pair).totalSupply();
        uint256 _userLPbal = ERC20Upgradeable(uniswapV2Pair).balanceOf(account);
        return _userLPbal.mul(10000).div(lpTotalSupply);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
}
