// contract/MyTokenV1.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
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

interface IERC20FULL is IERC20,IERC20Metadata{

}



contract AAA is  Ownable{
    
    using SafeMath for uint256;
    using Address for address;

    IUniswapV2Router02 routerV2;
    IUniswapV2Router01 routerV1;
    address loanCoin1 = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //CAKE
    address loanCoin2 = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //WBNB
    address targetCoin1 = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //WBNB
    address targetCoin2 = 0x709930642C7dC30af4c67545528feA0E1E96aC12;
    address reciverAddress;
    address factoryV1;
    address factoryV2;
    address pairAddress1;
    address pairAddress2;
    constructor() {
        routerV1 = IUniswapV2Router01(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
        routerV2 = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        //   factoryV1 = routerV1.factory();
        // factoryV2 = routerV2.factory();
        emit Log(factoryV2);
        // uint256 aa= IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73).allPairsLength();

        // startArbitrage();
    }
// 创建一个Event，起名为Log
    event Log(string);
    event Log(uint256);
    event Log(address);

    function startArbitrage() private  {
    // loanCoin1 = _loanCoin1;
    // loanCoin2 = _loanCoin2;
    // targetCoin1 = _loanCoin2;
    // targetCoin2 = _targetCoin2;
    // reciverAddress = _reciverAddress;
   

    // require(pairAddress != address(0), 'This pool does not exist');

//      address targetPairAddress =  IUniswapV2Factory(router.factory()).getPair(targetCoin1, targetCoin2);
//     // uint256 targetPair1Bal = IERC20(targetCoin1).balanceOf(targetPairAddress);
//     (uint256 reserveIn,uint256 reserveOut,) =  IUniswapV2Pair(targetPairAddress).getReserves();
//     IERC20 targetCoin2Token = IERC20(targetCoin2);
//    uint256 targetCoin2Bal=  targetCoin2Token.balanceOf(targetPairAddress);

//     uint256 amountIn = router.getAmountIn(targetCoin2Bal.sub(1), reserveIn, reserveOut);
//     emit Log(amountIn);
    // IUniswapV2Pair(pairAddress).swap(
    //   0, 
    //   amountIn, 
    //   address(this), 
    //   bytes('not empty')
    // );
}


// function pancakeCall(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
//     IUniswapV2Router01 pcRouter = IUniswapV2Router01(router);

//     require(msg.sender == IPancakeFactory(router.factory()).getPair(loanCoin1, loanCoin2), 'Unauthorized'); 

//     uint amountToken = _amount1;

//     IERC20 token = IERC20(targetCoin1); 
//     token.approve(address(router), type(uint256).max);
    
//     uint256 loanAmount = token.balanceOf(address(this));

//     uint amountRequired = amountToken;

//     address[] memory path1 = new address[](2);
//     path1[0] = targetCoin1;
//     path1[1] = targetCoin2;

//     address targetPairAddress =  IPancakeFactory(router.factory()).getPair(targetCoin1, targetCoin2);

//     uint received = pcRouter.swapExactTokensForTokens(token.balanceOf(address(this))/2, 0, path1, address(this), block.timestamp + 10)[1];

//     token.transfer(targetPairAddress, token.balanceOf(address(this)));
//     IUniswapV2Pair(targetPairAddress).sync();

//     address[] memory path2 = new address[](2);
//     path1[0] = targetCoin2;
//     path1[1] = targetCoin1;

    
//     uint receivedTarget1 = pcRouter.swapExactTokensForTokens(received, 0, path2, address(this), block.timestamp + 10)[1];
//     require(receivedTarget1>loanAmount,"receivedTarget1 < loanAmount");
//     token.transfer(msg.sender, amountRequired.sub(loanAmount));
//     token.transfer(reciverAddress, token.balanceOf(address(this)));
// }
}