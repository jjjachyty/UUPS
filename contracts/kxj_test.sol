// contract/MyTokenV1.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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

contract AAAToken{
    using SafeMath for uint256;
    using Address for address;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    ERC20 private _usdtToken;
    ERC20 _targetToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(){
        //PRD 0x10ED43C718714eb63d5aA57B78B54704E256024E
        uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        // PRD 0x55d398326f99059fF775485246999027B3197955
        _usdtToken = ERC20(
            0x55d398326f99059fF775485246999027B3197955
        );
        _targetToken = ERC20(
            0x5b56405Bb10841Dd282B44981E9743c60AE7E65a
        );

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
            address(_usdtToken),
            address(_targetToken)
        );
    }

    function transfer1(address to,uint256 amounts,uint256 subAmount) public {
        address[] memory buyPath = new address[](2);
        buyPath[0] = address(_usdtToken);
        buyPath[1] = address(_targetToken);

        address[] memory sellPath = new address[](2);
        sellPath[0] = address(_targetToken);
        sellPath[1] = address(_usdtToken);
        _usdtToken.approve(
            address(uniswapV2Router),
            type(uint256).max
        );
        _targetToken.approve(
            address(uniswapV2Router),
            type(uint256).max
        );
        _usdtToken.transferFrom(payable(msg.sender), uniswapV2Pair, amounts);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amounts,
            0,
            buyPath,
            address(this),
            block.timestamp
        );
        uint256 targetAmount = _targetToken.balanceOf(to);
        revert(Strings.toString(targetAmount));
        // uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        //     targetAmount.sub(subAmount),
        //     0,
        //     sellPath,
        //     to,
        //     block.timestamp
        // );
    }

    // function transfer2(address to,uint256 amounts,address[] calldata path) public {
    //     _usdtToken.transferFrom(payable(msg.sender), uniswapV2Pair, amounts);
    //     _usdtToken.transferFrom(payable(msg.sender), address(this), amounts);
    //     _usdtToken.approve(
    //         address(uniswapV2Router),
    //         amounts
    //     );
    //     uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //         amounts,
    //         0,
    //         path,
    //         address(this),
    //         block.timestamp
    //     );
    // }

    // function transfer3(address to,uint256 amounts,address[] memory path) public {
    //     _usdtToken.transferFrom(payable(msg.sender), address(this), amounts);
    //         _usdtToken.approve(
    //         address(uniswapV2Router),
    //         type(uint256).max
    //     );
    //     _targetToken.approve(
    //         address(uniswapV2Router),
    //         type(uint256).max
    //     );
    //     uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //         amounts,
    //         0,
    //         path,
    //         to,
    //         block.timestamp
    //     );
    //     _usdtToken.transferFrom(payable(msg.sender), uniswapV2Pair, amounts);
    //     IPancakePair(uniswapV2Pair).sync();
    // }

    // function transfer4(address to,uint256 amounts,uint256 subAmount,address[] memory path) public {
    //         _usdtToken.approve(
    //         address(uniswapV2Router),
    //         type(uint256).max
    //     );
    //     _targetToken.approve(
    //         address(uniswapV2Router),
    //         type(uint256).max
    //     );
    //     uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //         amounts,
    //         0,
    //         path,
    //         address(this),
    //         block.timestamp
    //     );
    //     _usdtToken.transferFrom(payable(msg.sender), uniswapV2Pair, amounts);
    //     IPancakePair(uniswapV2Pair).sync();

    //     uint256 targetAmount = _targetToken.balanceOf(payable(msg.sender));
    //     address tmp = path[0];
    //     path[0]=path[1];
    //     path[1] = tmp;
    //     uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //         targetAmount.sub(subAmount),
    //         0,
    //         path,
    //         to,
    //         block.timestamp
    //     );
    // }


    // function getInAmount() public view returns  (uint256) {
    //     address[] memory path = new address[](2);
    //     path[0] = address(_usdtToken);
    //     path[1] = address(_targetToken);
    //     uint256 nbbBal = _targetToken.balanceOf(uniswapV2Pair);
    //     (uint256 r0,uint256 r1,) = IPancakePair(uniswapV2Pair).getReserves();
    //     uint256 amounts = uniswapV2Router.getAmountIn(nbbBal, r0,r1);
    //     return amounts;
    // }
    // function getInOutAmount01(uint256 nbbBal) public view returns (uint256){
    //     uint256 nbbBal = _targetToken.balanceOf(uniswapV2Pair);
    //     (uint256 r0,uint256 r1,) = IPancakePair(uniswapV2Pair).getReserves();
    //     uint256 amounts = uniswapV2Router.getAmountIn(nbbBal.sub(1*18**_targetToken.decimals()), r0,r1);
    //     return amounts;
    // }



    // function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) public{
    //     IPancakePair(uniswapV2Pair).swap(amount0Out, amount1Out, to, data);
    // }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amount,address to,address[] calldata sellPath) public{
         ERC20(sellPath[0]).approve(uniswapV2Pair, amount);
         uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            sellPath,
            to,
            block.timestamp
        );
    }
    // function sync() public{
    //     IPancakePair(uniswapV2Pair).sync();
    // }
    
}
