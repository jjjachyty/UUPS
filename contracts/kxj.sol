
pragma solidity ^0.8.3;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// interface IUniswapV2Factory {
//     event PairCreated(
//         address indexed token0,
//         address indexed token1,
//         address pair,
//         uint256
//     );

//     function getPair(address tokenA, address tokenB)
//         external
//         view
//         returns (address pair);

//     function createPair(address tokenA, address tokenB)
//         external
//         returns (address pair);
// }

// interface IUniswapV2Router01 {
//     function factory() external pure returns (address);

//     function WETH() external pure returns (address);

//     function addLiquidity(
//         address tokenA,
//         address tokenB,
//         uint256 amountADesired,
//         uint256 amountBDesired,
//         uint256 amountAMin,
//         uint256 amountBMin,
//         address to,
//         uint256 deadline
//     )
//         external
//         returns (
//             uint256 amountA,
//             uint256 amountB,
//             uint256 liquidity
//         );

//     function addLiquidityETH(
//         address token,
//         uint256 amountTokenDesired,
//         uint256 amountTokenMin,
//         uint256 amountETHMin,
//         address to,
//         uint256 deadline
//     )
//         external
//         payable
//         returns (
//             uint256 amountToken,
//             uint256 amountETH,
//             uint256 liquidity
//         );

//     function removeLiquidity(
//         address tokenA,
//         address tokenB,
//         uint256 liquidity,
//         uint256 amountAMin,
//         uint256 amountBMin,
//         address to,
//         uint256 deadline
//     ) external returns (uint256 amountA, uint256 amountB);

//     function removeLiquidityETH(
//         address token,
//         uint256 liquidity,
//         uint256 amountTokenMin,
//         uint256 amountETHMin,
//         address to,
//         uint256 deadline
//     ) external returns (uint256 amountToken, uint256 amountETH);

//     function removeLiquidityWithPermit(
//         address tokenA,
//         address tokenB,
//         uint256 liquidity,
//         uint256 amountAMin,
//         uint256 amountBMin,
//         address to,
//         uint256 deadline,
//         bool approveMax,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) external returns (uint256 amountA, uint256 amountB);

//     function removeLiquidityETHWithPermit(
//         address token,
//         uint256 liquidity,
//         uint256 amountTokenMin,
//         uint256 amountETHMin,
//         address to,
//         uint256 deadline,
//         bool approveMax,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) external returns (uint256 amountToken, uint256 amountETH);

//     function swapExactTokensForTokens(
//         uint256 amountIn,
//         uint256 amountOutMin,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     ) external returns (uint256[] memory amounts);

//     function swapTokensForExactTokens(
//         uint256 amountOut,
//         uint256 amountInMax,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     ) external returns (uint256[] memory amounts);

//     function swapExactETHForTokens(
//         uint256 amountOutMin,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     ) external payable returns (uint256[] memory amounts);

//     function swapTokensForExactETH(
//         uint256 amountOut,
//         uint256 amountInMax,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     ) external returns (uint256[] memory amounts);

//     function swapExactTokensForETH(
//         uint256 amountIn,
//         uint256 amountOutMin,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     ) external returns (uint256[] memory amounts);

//     function swapETHForExactTokens(
//         uint256 amountOut,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     ) external payable returns (uint256[] memory amounts);

//     function quote(
//         uint256 amountA,
//         uint256 reserveA,
//         uint256 reserveB
//     ) external pure returns (uint256 amountB);

//     function getAmountOut(
//         uint256 amountIn,
//         uint256 reserveIn,
//         uint256 reserveOut
//     ) external pure returns (uint256 amountOut);

//     function getAmountIn(
//         uint256 amountOut,
//         uint256 reserveIn,
//         uint256 reserveOut
//     ) external pure returns (uint256 amountIn);

//     function getAmountsOut(uint256 amountIn, address[] calldata path)
//         external
//         view
//         returns (uint256[] memory amounts);

//     function getAmountsIn(uint256 amountOut, address[] calldata path)
//         external
//         view
//         returns (uint256[] memory amounts);
// }

// // pragma solidity >=0.6.2;

// interface IUniswapV2Router02 is IUniswapV2Router01 {
//     function removeLiquidityETHSupportingFeeOnTransferTokens(
//         address token,
//         uint256 liquidity,
//         uint256 amountTokenMin,
//         uint256 amountETHMin,
//         address to,
//         uint256 deadline
//     ) external returns (uint256 amountETH);

//     function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
//         address token,
//         uint256 liquidity,
//         uint256 amountTokenMin,
//         uint256 amountETHMin,
//         address to,
//         uint256 deadline,
//         bool approveMax,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) external returns (uint256 amountETH);

//     function swapExactTokensForTokensSupportingFeeOnTransferTokens(
//         uint256 amountIn,
//         uint256 amountOutMin,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     ) external;

//     function swapExactETHForTokensSupportingFeeOnTransferTokens(
//         uint256 amountOutMin,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     ) external payable;

//     function swapExactTokensForETHSupportingFeeOnTransferTokens(
//         uint256 amountIn,
//         uint256 amountOutMin,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     ) external;
// }

// interface IPancakePair {
//     event Approval(
//         address indexed owner,
//         address indexed spender,
//         uint256 value
//     );
//     event Transfer(address indexed from, address indexed to, uint256 value);

//     function name() external pure returns (string memory);

//     function symbol() external pure returns (string memory);

//     function decimals() external pure returns (uint8);

//     function totalSupply() external view returns (uint256);

//     function balanceOf(address owner) external view returns (uint256);

//     function allowance(address owner, address spender)
//         external
//         view
//         returns (uint256);

//     function approve(address spender, uint256 value) external returns (bool);

//     function transfer(address to, uint256 value) external returns (bool);

//     function transferFrom(
//         address from,
//         address to,
//         uint256 value
//     ) external returns (bool);

//     function DOMAIN_SEPARATOR() external view returns (bytes32);

//     function PERMIT_TYPEHASH() external pure returns (bytes32);

//     function nonces(address owner) external view returns (uint256);

//     function permit(
//         address owner,
//         address spender,
//         uint256 value,
//         uint256 deadline,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) external;

//     event Mint(address indexed sender, uint256 amount0, uint256 amount1);
//     event Burn(
//         address indexed sender,
//         uint256 amount0,
//         uint256 amount1,
//         address indexed to
//     );
//     event Swap(
//         address indexed sender,
//         uint256 amount0In,
//         uint256 amount1In,
//         uint256 amount0Out,
//         uint256 amount1Out,
//         address indexed to
//     );
//     event Sync(uint112 reserve0, uint112 reserve1);

//     function MINIMUM_LIQUIDITY() external pure returns (uint256);

//     function factory() external view returns (address);

//     function token0() external view returns (address);

//     function token1() external view returns (address);

//     function getReserves()
//         external
//         view
//         returns (
//             uint112 reserve0,
//             uint112 reserve1,
//             uint32 blockTimestampLast
//         );

//     function price0CumulativeLast() external view returns (uint256);

//     function price1CumulativeLast() external view returns (uint256);

//     function kLast() external view returns (uint256);

//     function mint(address to) external returns (uint256 liquidity);

//     function burn(address to)
//         external
//         returns (uint256 amount0, uint256 amount1);

//     function swap(
//         uint256 amount0Out,
//         uint256 amount1Out,
//         address to,
//         bytes calldata data
//     ) external;

//     function skim(address to) external;

//     function sync() external;

//     function initialize(address, address) external;
// }

// interface IPancakeERC20 {
//     event Approval(
//         address indexed owner,
//         address indexed spender,
//         uint256 value
//     );
//     event Transfer(address indexed from, address indexed to, uint256 value);

//     function name() external pure returns (string memory);

//     function symbol() external pure returns (string memory);

//     function decimals() external pure returns (uint8);

//     function totalSupply() external view returns (uint256);

//     function balanceOf(address owner) external view returns (uint256);

//     function allowance(address owner, address spender)
//         external
//         view
//         returns (uint256);

//     function approve(address spender, uint256 value) external returns (bool);

//     function transfer(address to, uint256 value) external returns (bool);

//     function transferFrom(
//         address from,
//         address to,
//         uint256 value
//     ) external returns (bool);

//     function DOMAIN_SEPARATOR() external view returns (bytes32);

//     function PERMIT_TYPEHASH() external pure returns (bytes32);

//     function nonces(address owner) external view returns (uint256);

//     function permit(
//         address owner,
//         address spender,
//         uint256 value,
//         uint256 deadline,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) external;
// }

// contract FuckToken is
//     ERC20,
//     Ownable
// {
//     using SafeMath for uint256;
//     using Address for address;

//     IUniswapV2Router02 public uniswapV2Router;
//     address public uniswapV2Pair;
//     ERC20 private _usdtToken;
//     ERC20 _targetToken;
   
//     // function transfer(address usdtToken,address targetToken){
//     //     _usdtToken = ERC20(usdtToken);
//     //     _targetToken = ERC20(targetToken);

//     //    uint256[] memory amounts =  getInAmount();
//     // address[] memory path = new address[](2);
//     //     path[1] = address(_usdtToken);
//     //     path[0] = address(_targetToken);

//     //     _usdtToken.transferFrom(_msgSender(),uniswapV2Pair, amounts[0]);
//     //     uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amounts[0], 0, path, 0xbfeeba2508e057d028b0313d3a0c7d9cacdd248b, deadline);
//     // }

//     function getInAmount() public returns (uint256[] memory){
//           address[] memory path = new address[](2);
//         path[0] = address(_usdtToken);
//         path[1] = address(_targetToken);
//         uint256 bal = _usdtToken.balanceOf(_msgSender());
//         uint256 nbbBal = balanceOf(uniswapV2Pair);
//         uint256[] memory amounts =  uniswapV2Router.getAmountsIn(nbbBal, path);
//         return amounts;
//     }
    
// }
