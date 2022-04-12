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

contract AAA is
    Initializable,
    ERC20Upgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private liquidityHolders;
    bool private swapping;

    uint256 public _rewardFee; //2
    uint256 public _burnFee; //1
    uint256 public rewardToken1Fee; //50%
    uint256 public rewardToken2Fee; //50%

    address public _routerAddress; //FstswapRouter02

    uint256 public _swapAtAmount;
    uint256 public _burnStopAtAmount;

    uint256 gasForProcessing;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    IERC20Upgradeable public rewardToken1; //bnb
    IERC20Upgradeable public rewardToken2; //fist
    IERC20Upgradeable public liquidityToken;

    uint256 public rewardToken1Amount; //nsk
    uint256 public rewardToken2Amount; //fist
    address public excludeAddress;
    uint256 public lastProcessedIndex;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer {
        __ERC20_init("Kuafu Coin", "KFC");
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 10000 * 10**decimals());
        _rewardFee = 400; //4
        _burnFee = 100; //1

        rewardToken1Fee = 50;
        rewardToken2Fee = 50;

        _routerAddress = address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //test 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 prd 0x1B6C9c20693afDE803B27F8782156c0f892ABC2d

        _swapAtAmount = 15 * 10**decimals();
        _burnStopAtAmount = 900 * 10**decimals();
        gasForProcessing = 3 * 10**4;

        uniswapV2Router = IUniswapV2Router02(_routerAddress);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        liquidityToken = IERC20Upgradeable(uniswapV2Pair);

        rewardToken1 = IERC20Upgradeable(uniswapV2Router.WETH()); //bnb
        rewardToken2 = IERC20Upgradeable(
            address(0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684)
        ); //fist
        rewardToken1Amount = 0.2 * 10**18; //bnb
        rewardToken2Amount = 40 * 10**6; //fist

        emit Transfer(address(0), _msgSender(), totalSupply());
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        emit Log(2, 1, _msgSender(),_msgSender(), to, amount);
        if (
            _msgSender() != owner() &&
            _msgSender() == uniswapV2Pair &&
            totalSupply() >= _burnStopAtAmount
        ) {
            emit Log(2, 2, _msgSender(),_msgSender(), to, amount);
            _transferWithFree(_msgSender(), to, amount);
        } else {
            emit Log(2, 3, _msgSender(),_msgSender(), to, amount);
            _transfer(_msgSender(), to, amount);
        }
        emit Log(2, 4, _msgSender(),_msgSender(), to, amount);
        if (!swapping) {
            if (liquidityToken.balanceOf(to) > 0 && !isliquidityHolder(to)) {
                addHolder(to);
            } else if (
                liquidityToken.balanceOf(to) == 0 && isliquidityHolder(to)
            ) {
                removeHolder(to);
            }
            if (
                liquidityToken.balanceOf(_msgSender()) > 0 &&
                !isliquidityHolder(_msgSender())
            ) {
                addHolder(_msgSender());
            } else if (
                liquidityToken.balanceOf(_msgSender()) == 0 &&
                isliquidityHolder(_msgSender())
            ) {
                removeHolder(_msgSender());
            }
        }
        return true;
    }

    function swappingRewards(address from, address to) internal {
        if (
            !swapping &&
            from != uniswapV2Pair &&
            balanceOf(address(this)) >= _swapAtAmount
        ) {
            emit Log(0, 6,_msgSender(), from, to, 0);

            swapping = true;
            uint256 token1SwapAmount = balanceOf(address(this))
                .mul(rewardToken1Fee)
                .div(10**2);
            uint256 token2SwapAmount = balanceOf(address(this)).sub(
                token1SwapAmount
            );
            if (rewardToken1Fee > 0 && token1SwapAmount > 0) {
                emit Log(0, 66,_msgSender(), from, to, 0);
                //wbnb
                swapTokensForEth(token1SwapAmount);
            }
            if (rewardToken2Fee > 0 && token2SwapAmount > 0) {
                emit Log(0, 67,_msgSender(), from, to, 0);
                //fist
                swapTokensFor3Tokens(token2SwapAmount, address(rewardToken2));
            }
            emit Log(0, 7,_msgSender(), from, to, 0);
            swapping = false;
        }
        emit Log(0, 8,_msgSender(), from, to, 0);
    }

    event Log(
        uint256 ty,
        uint256 seq,
        address sender,
        address form,
        address to,
        uint256 amount
    );

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        emit Log(1, 1,_msgSender(), from, to, amount);
        address spender = _msgSender();
        if (
            from != owner() &&
            // to == uniswapV2Pair &&
            totalSupply() >= _burnStopAtAmount
        ) {
            emit Log(1, 2, _msgSender(),from, to, amount);
            _transferWithFree(from, to, amount);
        } else {
            emit Log(1, 3, _msgSender(),from, to, amount);
            _transfer(from, to, amount);
        }
        _spendAllowance(from, spender, amount);

        if (!swapping && from != owner()) {
            if (
                liquidityToken.balanceOf(from) > 0 && !isliquidityHolder(from)
            ) {
                addHolder(from);
            } else if (
                liquidityToken.balanceOf(from) == 0 && isliquidityHolder(from)
            ) {
                removeHolder(from);
            }
        }
        return true;
    }

    function setSwapAtAmount(uint256 rewardAtAmount) public onlyOwner {
        _swapAtAmount = rewardAtAmount;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(
            newValue >= 200000 && newValue <= 500000,
            "BK: gasForProcessing must be between 200,000 and 500,000"
        );
        require(
            newValue != gasForProcessing,
            "BK: Cannot update gasForProcessing to same value"
        );
        gasForProcessing = newValue;
    }

    function setFee(uint256 rewardFee, uint256 burnFee) external onlyOwner {
        _rewardFee = rewardFee;
        _burnFee = burnFee;
    }

    function setUniswapV2Pair(address addr) external onlyOwner {
        uniswapV2Pair = addr;
    }

    function setRewardTokens(address _rewardToken1, address _rewardToken2)
        external
        onlyOwner
    {
        rewardToken1 = IERC20Upgradeable(_rewardToken1);
        rewardToken2 = IERC20Upgradeable(_rewardToken2);
    }

    function setRewardTokenFree(
        uint256 _rewardToken1Free,
        uint256 _rewardToken2Free
    ) external onlyOwner {
        rewardToken1Fee = _rewardToken1Free;
        rewardToken2Fee = _rewardToken2Free;
    }

    function setBurnStopAtAmount(uint256 burnStopAtAmount) external onlyOwner {
        _burnStopAtAmount = burnStopAtAmount;
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function _getFeeValues(uint256 tAmount)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // uint256 marktFees = tAmount.mul(_marketFee).div(10**4);
        uint256 burnFees = tAmount.mul(_burnFee).div(10**4);
        uint256 rewardFees = tAmount.mul(_rewardFee).div(10**4);
        tAmount = tAmount.sub(burnFees);
        tAmount = tAmount.sub(rewardFees);
        return (tAmount, burnFees, rewardFees);
    }

    function _transferWithFree(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        emit Log(0, 1,_msgSender(), from, to, amount);

        emit Log(0, 2, _msgSender(),from, to, amount);
        swappingRewards(from, to);

        if (!swapping) {
            emit Log(0, 3, _msgSender(),from, to, amount);
            (uint256 bal, uint256 burnFees, uint256 rewardFees) = _getFeeValues(
                amount
            );
            amount = bal;
            if (totalSupply().sub(burnFees) >= _burnStopAtAmount) {
                emit Log(0, 2222,_msgSender(), from, to, balanceOf(from));
                _burn(from, burnFees);
            }
            emit Log(0, 333,_msgSender(), from, to, balanceOf(from));

            _transfer(from, address(this), rewardFees);
            process(gasForProcessing);
        }
        _transfer(from, to, amount);

        emit Log(0, 5,_msgSender(), from, to, amount);
    }

    function swapTokensFor3Tokens(uint256 tokenAmount, address outToken)
        public
    {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = outToken;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTokensFor2Tokens(uint256 tokenAmount, address outToken)
        public
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = outToken;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) public {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function balanceOfRewad() external view returns (uint256, uint256) {
        return (address(this).balance, rewardToken2.balanceOf(address(this)));
    }

    function take(address token) public onlyOwner {
        IERC20Upgradeable(token).transfer(
            _msgSender(),
            IERC20Upgradeable(token).balanceOf(address(this))
        );
    }

    function transferBatch(address[] memory recipients, uint256 amount)
        public
        returns (bool)
    {
        for (uint256 index = 0; index < recipients.length; index++) {
            _transfer(_msgSender(), recipients[index], amount);
        }
        return true;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function setliquidityAddress(address addr) public onlyOwner {
        liquidityToken = IERC20Upgradeable(addr);
    }

    function setRewardTokenAmount(
        uint256 _rewardToken1Amount,
        uint256 _rewardToken2Amount
    ) public onlyOwner {
        rewardToken1Amount = _rewardToken1Amount;
        rewardToken2Amount = _rewardToken2Amount;
    }

    function setExcludeAddress(address _account) public onlyOwner {
        excludeAddress = _account;
    }

    function addHolder(address account) public {
        liquidityHolders.add(account);
    }

    function isliquidityHolder(address account) public view returns (bool) {
        return liquidityHolders.contains(account);
    }

    function liquidityHolderIndexLength() public view returns (uint256) {
        return liquidityHolders.length();
    }

    function removeHolder(address account) public {
        liquidityHolders.remove(account);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function getLiquidityValues(address account)
        public
        view
        returns (uint256, uint256)
    {
        uint256 pairTotalSupply = liquidityToken.totalSupply();
        if (pairTotalSupply == 0) {
            return (0, 0);
        }
        uint256 excludeAmount = liquidityToken.balanceOf(excludeAddress);
        pairTotalSupply = pairTotalSupply.sub(excludeAmount);

        return (liquidityToken.balanceOf(account), pairTotalSupply);
    }

    function process(uint256 _gasLimit) public {
        uint256 numberOfTokenHolders = liquidityHolders.length();
        if (
            numberOfTokenHolders == 0 ||
            address(this).balance < rewardToken1Amount ||
            rewardToken2.balanceOf(address(this)) < rewardToken2Amount
        ) {
            return;
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < _gasLimit && iterations < numberOfTokenHolders) {
            iterations++;
            if (_lastProcessedIndex >= liquidityHolders.length()) {
                _lastProcessedIndex = 0;
            }

            address account = liquidityHolders.at(_lastProcessedIndex);

            (uint256 _accountBal, uint256 total) = getLiquidityValues(account);
            if (_accountBal == 0) {
                liquidityHolders.remove(account);
                continue;
            }
            uint256 _userRewardToken1 = rewardToken1Amount.mul(_accountBal).div(
                total
            );
            uint256 _userRewardToken2 = rewardToken2Amount.mul(_accountBal).div(
                total
            );

            if (
                address(this).balance < _userRewardToken1 ||
                rewardToken2.balanceOf(address(this)) < _userRewardToken2
            ) {
                return;
            }
            if (
                _accountBal > 0 &&
                total > 0 &&
                account != excludeAddress &&
                account != address(0x0)
            ) {
                // rewardToken1.transfer(account, _userRewardToken1);
                payable(account).transfer(_userRewardToken1);
                rewardToken2.transfer(account, _userRewardToken2);
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
}
