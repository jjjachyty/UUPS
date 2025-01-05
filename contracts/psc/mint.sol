pragma solidity ^0.8.25;
// SPDX-License-Identifier: MIT

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IPancakeRouter01 {
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
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface SwapContract {
    function getPrice() external view returns (uint256);
}

contract Mint is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IERC1155Receiver,
    ERC165Upgradeable
{
    using Math for uint256;
    //内盘合约地址
    SwapContract _swapContract;
    //代币合约地址
    address public _token;
    //NFT合约地址
    address public _nft;
    //20%产出指定地址
    address public _targetAddress20;
    //5%产出指定地址
    address public _targetAddress5;

    //昨日平台总算力
    uint256 public lastdayPower;
    //前天平台总算力
    uint256 public lastdaydayPower;
    //前500总T
    uint256 public totalT500;
    //算力增加万分比 默认增加1%
    uint256 public addPowerFee;
    //管理员2%总权重
    uint256 public totalAdminWeight;
    //今日总产出
    uint256 public todayProduce;

    uint public start = 0;
    uint public end = 0;
    uint public size = 0;

    uint256 id;

    //推荐关系
    mapping(address => address) public recommend;
    //挖矿算力积分
    mapping(uint256 => MintLevelPoint) public _mintLevelInfo;
    //个人挖矿信息
    mapping(address => PledgeOrder) public _orders;
    //个人挖矿信息
    mapping(address => PledgeOrderReward) public _ordersReward;
    //团队信息
    mapping(address => Team) public _teamInfo;

    //直推数组
    mapping(address => address[]) public teamList;
    //领取收益数量 日期-地址-数量
    mapping(uint256 => mapping(address => uint256)) public lastReward;
    //每周新增业绩 日期-地址-数量
    mapping(uint256 => mapping(address => uint256)) public weekReward;
    //直推t数量 地址-数量
    mapping(address => uint256) public tReward;
    //之前T数量
    mapping(address => uint256) public _lastT;
    //个人累计领取额度
    mapping(address => uint256) public rewardTotalAmount;
    //全网总和T
    uint256 public lastTotalT;
    //每周累计业绩 日期-数量
    mapping(uint256 => uint256) public weekTotal;
    //当日累计算力 日期-数量
    mapping(uint256 => uint256) public powerInfo;
    //今日是否领取过收益
    mapping(uint256 => mapping(address => bool)) public _isReward;
    //每周业绩前20地址
    mapping(uint256 => RewardInfo[]) public weekRankAddress;
    //质押记录
    mapping(address => PladgeRecord[]) public pladeList;
    //收益记录
    mapping(address => RewardRecord[]) public rewardList;
    //收益记录 2%权重
    mapping(address => PladgeRecord[]) public adminRewardRecord;
    //直推T排名
    RewardInfo[] public tRankAddress;
    // 用于存储每个周的所有用户地址
    mapping(uint256 => address[]) public weekUsers;

    uint256 public constant MAX = ~uint256(0);

    IPancakeRouter02 public _swapRouter;
    //最新550入单
    BuyRecord[550] public _buyRecord;

    //t收益地址列表
    address[] public tList;

    //管理员2%收益列表
    Admin2RewardInfo[] public adminRewardList;

    //挖矿档位
    struct MintLevelPoint {
        uint256 price; //价格
        uint256 power; //算力
        uint256 bei; //出局倍率
    }

    //我的团队
    struct Team {
        uint256 zhi; //直推人数
        uint256 tureZhi; //有效直推人数
        uint256 team; //团队人数
        uint256 trueTeam; //有效团队人数
        uint256 teamAmount; //团队业绩
    }

    struct PledgeOrder {
        bool isExist; //是否存在质押
        uint256 power; //个人算力
        uint256 totalU; //U总价值
        uint256 remain; //剩余额度 u
        uint256 lastTime; //最后领取日期
        uint256 rank; //排名
        uint256 b; //b
        uint256 t; //t
    }

    struct PledgeOrderReward {
        uint256 zhiJunRankReward; //直推排名均分未领取收益
        uint256 zhiRankReward; //直推排名未领取收益
        uint256 weekRankReward; //周排名未领取收益
        uint256 admin2Reward; //管理员2%收益未领取收益
    }

    //入单记录
    struct BuyRecord {
        address ads;
        uint256 value;
        uint256 time;
    }

    //收益记录 静态 动态 总
    struct RewardRecord {
        uint256 stat;
        uint256 dyna;
        uint256 total;
    }

    //质押记录
    struct PladgeRecord {
        uint256 id;
        uint256 time;
    }

    // 用于排序的业绩对象
    struct RewardInfo {
        address user;
        uint256 reward;
    }

    // 管理员2%收益列表
    struct Admin2RewardInfo {
        address user;
        uint256 weight;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        todayProduce = 100000 * 10 ** 18;
        addPowerFee = 100;
        _token = 0x3e81AE5448ED9fd785467FDe13AC3127775E8d00;
        //NFT合约地址
        _nft = 0xaafDa90AE7C6b084216872e6950eEf5dAfE48bd9;
        //20%产出指定地址
        _targetAddress20 = 0xa1fA5D2f89E40E442Fbd65DD358C062966e30593;
        //5%产出指定地址
        _targetAddress5 = 0x2b676458B0Cf2Dd910f1b332105B55B010Bf832B;
        _swapContract = SwapContract(
            0x63390f615D290324C81271fD9Ac48e5422aed80A
        );
        IPancakeRouter02 swapRouter = IPancakeRouter02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        _targetAddress20 = 0xa1fA5D2f89E40E442Fbd65DD358C062966e30593;
        //5%产出指定地址
        _targetAddress5 = 0x2b676458B0Cf2Dd910f1b332105B55B010Bf832B;

        _swapRouter = swapRouter;
        _mintLevelInfo[1] = MintLevelPoint(200 * 10 ** 18, 200 * 10 ** 18, 20);
        _mintLevelInfo[2] = MintLevelPoint(600 * 10 ** 18, 750 * 10 ** 18, 25);
        _mintLevelInfo[3] = MintLevelPoint(
            1800 * 10 ** 18,
            2700 * 10 ** 18,
            30
        );
        _mintLevelInfo[4] = MintLevelPoint(
            5400 * 10 ** 18,
            9450 * 10 ** 18,
            35
        );
        _mintLevelInfo[5] = MintLevelPoint(
            16200 * 10 ** 18,
            32400 * 10 ** 18,
            40
        );
        id = 1;
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    //挖矿
    function mining(address _operAddress, uint256 _id) public {
        require(address(msg.sender) == address(tx.origin), "no contract");
        ERC1155Upgradeable nft = ERC1155Upgradeable(_nft);
        nft.safeTransferFrom(_operAddress, address(this), _id, 1, "");
        MintLevelPoint memory info = _mintLevelInfo[_id];
        createOrder(_operAddress, info);

        address top = recommend[_operAddress];
        if (top != address(0)) {
            addTeamAmountInfo(top, info.price);
        }
        PladgeRecord memory pr = PladgeRecord(_id, block.timestamp);
        pladeList[_operAddress].push(pr);
    }

    //管理员质押 写入下级地址，上级地址， 价格， 算力
    function adminWrite(
        address _target,
        address _top,
        uint256 price,
        uint256 power
    ) external onlyOwner {
        bind(_target, _top);
        MintLevelPoint memory info = MintLevelPoint(price, power, 10);
        createOrder(_target, info);

        address top = recommend[_target];
        if (top != address(0)) {
            addTeamAmountInfo(top, info.price);
        }
        PladgeRecord memory pr = PladgeRecord(0, block.timestamp);
        pladeList[_target].push(pr);
    }

    function createOrder(
        address _operAddress,
        MintLevelPoint memory info
    ) private {
        PledgeOrder storage order = _orders[_operAddress];
        if (id > 1) {
            info.power =
                info.power +
                (info.power * (id - 1) * addPowerFee) /
                10000;
        }
        //存在
        if (order.isExist) {
            order.power += info.power;
            order.remain += ((info.price * info.bei) / 10);
            order.totalU += info.price;
        } else {
            _orders[_operAddress] = PledgeOrder(
                true,
                info.power,
                info.price,
                (info.price * info.bei) / 10,
                id,
                0,
                0,
                0
            );
        }
        address top = recommend[_operAddress];

        //每周业绩
        weekReward[id / 7][top] += info.price;
        //每周业绩之和
        weekTotal[id / 7] += info.price;
        //当日累计算力
        powerInfo[id] += info.power;
        //添加入单记录
        addElement(_operAddress, info.price);
        //添加 weekReward 的数据，并保存用户地址到数组中
        setWeekReward(id / 7, top, info.price);

        saveTeamInfo(top, true);

        updateT(_operAddress);
    }

    function saveTeamInfo(address top, bool zhi) internal {
        if (top != address(0)) {
            Team storage team = _teamInfo[top];
            team.tureZhi++;
            if (!zhi) {
                team.trueTeam++;
            }
            top = recommend[top];
            saveTeamInfo(top, false);
        }
    }

    //更新全网T，获取最新自身动态收益
    function updateT(address _target) public {
        if (_target != address(0)) {
            uint256 t = getAmountT(_target);
            uint256 b = getAmountB(_target);
            if (t > 0) {
                PledgeOrder storage order = _orders[_target];
                order.t = t;
                order.b = b;
                lastTotalT -= _lastT[_target];
                lastTotalT += t;
                _lastT[_target] = t;
                //增加t列表
                settRank(_target, t);
            }
            updateT(recommend[_target]);
        }
    }

    //复投算力
    function addPower(address _target, uint256 _amount) public {
        require(
            address(msg.sender) == address(_swapContract),
            "Prohibit operation"
        );
        if (id > 1) {
            _amount = _amount + (_amount * (id - 1) * addPowerFee) / 10000;
        }
        PledgeOrder storage order = _orders[_target];
        //增加个人算力
        order.power += _amount;
        //增加出局额度（代币）
        order.remain += _amount;
        //当日累计算力
        powerInfo[id] += _amount;
    }

    //查询个人静态收益 A
    function getAmountA(address _target) public view returns (uint256) {
        PledgeOrder memory order = _orders[_target];
        return order.power;
    }

    //获取市场动态算力 B
    function getAmountB(address _target) public view returns (uint256) {
        address[] memory zhi = teamList[_target];
        uint256 total = 0;
        PledgeOrder memory order;
        for (uint256 i = 0; i < zhi.length; i++) {
            order = _orders[zhi[i]];
            total = total + (order.power * 3) / 10 + (order.b * 3) / 10;
        }
        return total;
    }

    //个人整体收益 T
    function getAmountT(address _target) public view returns (uint256) {
        uint256 a = getAmountA(_target);
        uint256 b = getAmountB(_target);
        if (a + b == 0) {
            return 0;
        }
        return (b * (10000 + (a * 10000) / (a + b))) / 10000;
    }

    //修改swap合约地址
    function setSwapContractAddress(address _target) external onlyOwner {
        _swapContract = SwapContract(_target);
    }

    //手动设置某日算力（time单位时间戳 日）
    function setPow(uint256 time, uint256 amount) public onlyOwner {
        powerInfo[time] = amount;
    }

    //计算当天时间戳（单位 日）
    function getTime() external view returns (uint256) {
        return id;
    }

    //计算当天时间戳（单位 周）
    function getTimeWeek() external view returns (uint256) {
        return id / 7;
    }


    //70%铸币分配
    function reawrd70(
        address _target,
        uint256 _remain
    ) internal returns (uint256 res) {
        //60%个人静态收益
        uint256 a = getStatic(_target);
        IERC20(_token).transfer(_target, a);
        a = _remain <= getTokenPriceByU(a) ? _remain : getTokenPriceByU(a);
        _remain -= a;
        //累计个人领取额度
        rewardTotalAmount[_target] += a;
        res = a;
        //记录个人领取数量
        uint256 b = getAmountB(_target);
        lastReward[id][_target] = b;
        uint256 t = getAmountT(_target);
        PledgeOrder storage order = _orders[_target];
        order.t = t;
        order.b = b;
        lastTotalT -= _lastT[_target];
        lastTotalT += t;
        _lastT[_target] = t;
        uint256 result = 0;
        if (_remain > 0) {
            //动态35%收益
            result = getSync(_target);
            if (result > 0) {
                IERC20(_token).transfer(_target, result);
                result = _remain <= getTokenPriceByU(result)
                    ? _remain
                    : getTokenPriceByU(result);
                //累计个人领取额度
                rewardTotalAmount[_target] += result;
                res += result;
            }
        }

        RewardRecord memory pr = RewardRecord(a, result, a + result);
        rewardList[_target].push(pr);

        return res;
    }

    function queryReawrd70(
        address _target,
        uint256 _amount
    ) public view returns (uint256 res) {
        //60%个人静态收益
        uint256 a = getStatic(_target);
        res = a;
        //记录个人领取数量
        uint256 t = getAmountT(_target);
        uint256 result = 0;
        if (lastTotalT > 0) {
            //动态35%收益
            result = (t * _amount * 7 * 35) / lastTotalT / 1000;
            res += result;
        }
        return getTokenPriceByU(res);
    }

    //查询静态收益 精度18
    function getStatic(address _target) public view returns (uint256) {
        PledgeOrder storage order = _orders[_target];
        if (order.lastTime >= id || powerInfo[id - 1] == 0) {
            return 0;
        }
        return
            (getAmountA(_target) * todayProduce * 42) / 100 / powerInfo[id - 1];
    }

    //查询动态收益
    function getSync(address _target) public view returns (uint256) {
        PledgeOrder storage order = _orders[_target];
        if (order.lastTime >= id) {
            return 0;
        }
        uint256 t = order.t;
        uint256 result = 0;
        if (lastTotalT > 0) {
            //动态35%收益
            result = (t * todayProduce * 7 * 35) / lastTotalT / 1000;
        }
        return result;
    }

    // 添加新入单
    function addElement(address _ads, uint256 value) public {
        BuyRecord memory rec = BuyRecord(_ads, value, block.timestamp);
        _buyRecord[end] = rec;
        end = (end + 1) % 550;
        if (size < 550) {
            size++;
        } else {
            start = (start + 1) % 1000;
        }
    }

    // 添加 tRank 的数据，并保存用户地址到数组中
    function settRank(address user, uint256 reward) internal {
        tReward[user] = reward;

        // 如果用户还没加入到 weekUsers 列表中，则添加
        bool userExists = false;
        for (uint256 i = 0; i < tList.length; i++) {
            if (tList[i] == user) {
                userExists = true;
                break;
            }
        }
        if (!userExists) {
            tList.push(user);
        }
    }

    // 添加 weekReward 的数据，并保存用户地址到数组中
    function setWeekReward(
        uint256 weekId,
        address user,
        uint256 reward
    ) internal {
        weekReward[weekId][user] = reward;

        // 如果用户还没加入到 weekUsers 列表中，则添加
        bool userExists = false;
        for (uint256 i = 0; i < weekUsers[weekId].length; i++) {
            if (weekUsers[weekId][i] == user) {
                userExists = true;
                break;
            }
        }
        if (!userExists) {
            weekUsers[weekId].push(user);
        }
    }

    //定时外部调用任务
    // 获取指定周的排序后的地址数组
    function sortWeekReward() public {
        uint256 weekId = id / 7;
        uint256 userCount = weekUsers[weekId].length;
        RewardInfo[] memory rewards = new RewardInfo[](userCount);

        for (uint256 i = 0; i < userCount; i++) {
            address user = weekUsers[weekId][i];
            rewards[i] = RewardInfo({
                user: user,
                reward: weekReward[weekId][user]
            });
        }

        for (uint256 i = 0; i < rewards.length; i++) {
            for (uint256 j = 0; j < rewards.length - 1; j++) {
                if (rewards[j].reward < rewards[j + 1].reward) {
                    // 交换两个元素的位置
                    RewardInfo memory temp = rewards[j];
                    rewards[j] = rewards[j + 1];
                    rewards[j + 1] = temp;
                }
            }
        }

        for (uint256 i = 0; i < rewards.length; i++) {
            if (tRankAddress.length <= 20) {
                weekRankAddress[id / 7].push(rewards[i]);
            }
        }

        //每周新增排行前20权重分红
        PledgeOrderReward storage orders;
        uint256 wk = (700000 * 10 ** 18 * 7 * 3) / 10 / 100;
        RewardInfo[] memory weekss = weekRankAddress[id / 7];
        for (uint256 i = 0; i < weekss.length; i++) {
            orders = _ordersReward[weekss[i].user];
            orders.weekRankReward = (weekss[i].reward * wk) / weekTotal[id / 7];
        }

        //权重分红
        uint256 totalReward = (700000 * 10 ** 18 * 7) / 10 / 50;
        for (uint256 i = 0; i < adminRewardList.length; i++) {
            uint256 reweard = (adminRewardList[i].weight * totalReward) /
                totalAdminWeight;
            PledgeOrderReward storage order = _ordersReward[
                adminRewardList[i].user
            ];
            order.admin2Reward = reweard;
        }
    }

    //定时外部调用任务
    // 对tList中的地址按照tReward数值从大到小排序，并存储到tRankAddress数组中
    function sortTList() public {
        uint256 userCount = tList.length;
        RewardInfo[] memory rewards = new RewardInfo[](userCount);

        // 1. 将 tReward 数据提取到结构体数组中
        for (uint256 i = 0; i < userCount; i++) {
            address user = tList[i];
            rewards[i] = RewardInfo({user: user, reward: tReward[user]});
        }

        // 2. 使用冒泡排序算法对 rewards 数组按照 tReward 从大到小排序
        for (uint256 i = 0; i < rewards.length; i++) {
            for (uint256 j = 0; j < rewards.length - 1; j++) {
                if (rewards[j].reward < rewards[j + 1].reward) {
                    // 交换两个元素的位置
                    RewardInfo memory temp = rewards[j];
                    rewards[j] = rewards[j + 1];
                    rewards[j + 1] = temp;
                }
            }
        }

        // 3. 将排序后的结果存储到 tRankAddress 数组中
        totalT500 = 0;
        delete tRankAddress;
        uint256 limit = rewards.length > 500 ? 500 : rewards.length;
        for (uint256 i = 0; i < limit; i++) {
            tRankAddress.push(rewards[i]);
            totalT500 += rewards[i].reward;
            PledgeOrder storage order = _orders[rewards[i].user];
            order.rank = i + 1;
        }

        if (tRankAddress.length > 0 && totalT500 > 0) {
            //分配额度
            uint256 total = 700000 * 10 ** 18;
            PledgeOrderReward storage orders;
            //30%平分t排名
            for (uint256 i = 0; i < tRankAddress.length; i++) {
                orders = _ordersReward[tRankAddress[i].user];
                orders.zhiJunRankReward =
                    (total * 3) /
                    10 /
                    tRankAddress.length /
                    20;
            }
            if (totalT500 > 0) {
                //加权分70%
                RewardInfo[] memory info = getRankedAddressesByRange(0, 49);
                for (uint256 i = 0; i < info.length; i++) {
                    if (info[i].user != address(0)) {
                        orders = _ordersReward[info[i].user];
                        orders.zhiRankReward =
                            (info[i].reward * total * 45 * 7) /
                            10 /
                            20 /
                            100 /
                            totalT500;
                    }
                }
                info = getRankedAddressesByRange(50, 199);
                for (uint256 i = 0; i < info.length; i++) {
                    if (info[i].user != address(0)) {
                        orders = _ordersReward[info[i].user];
                        orders.zhiRankReward =
                            (info[i].reward * total * 35 * 7) /
                            10 /
                            20 /
                            100 /
                            totalT500;
                    }
                }
                info = getRankedAddressesByRange(200, 499);
                for (uint256 i = 0; i < info.length; i++) {
                    if (info[i].user != address(0)) {
                        orders = _ordersReward[info[i].user];
                        orders.zhiRankReward =
                            (info[i].reward * total * 7) /
                            10 /
                            20 /
                            5 /
                            totalT500;
                    }
                }
            }
        }
    }

    // 获取排序后的tRankAddress中指定范围的数据 起始名次和结束名次
    function getRankedAddressesByRange(
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (RewardInfo[] memory) {
        //require(endIndex >= startIndex, "Invalid range");
        //require(endIndex < tRankAddress.length, "End index out of bounds");

        uint256 rangeLength = endIndex - startIndex + 1;
        RewardInfo[] memory range = new RewardInfo[](rangeLength);
        rangeLength = rangeLength >= tRankAddress.length
            ? tRankAddress.length
            : rangeLength;
        if (rangeLength >= startIndex) {
            for (uint256 i = 0; i < rangeLength; i++) {
                range[i] = tRankAddress[startIndex + i];
            }
        }
        return range;
    }

    // 获取某个周排序后的对象 每周业绩前20地址
    function getWeekRankUsers(
        uint256 weekId
    ) public view returns (RewardInfo[] memory) {
        return weekRankAddress[weekId];
    }

    //定时外部调用任务
    //计算今日产出
    function calTodayProduce() public {
        if (id > 2) {
            lastdaydayPower = powerInfo[id - 2];
            lastdayPower = powerInfo[id - 1];
            if (
                lastdaydayPower <= lastdayPower &&
                lastdaydayPower != 0 &&
                lastdayPower != 0
            ) {
                uint256 diff = calculatePercentageDifference(
                    lastdaydayPower,
                    lastdayPower
                );
                if (diff >= 60) {
                    todayProduce =
                        todayProduce +
                        20000 *
                        10 ** 18 *
                        ((diff - 60) / 10 + 1);
                    todayProduce = todayProduce > 500000 * 10 ** 18
                        ? 500000 * 10 ** 18
                        : todayProduce;
                }
            }
        }
        id++;
        powerInfo[id] = powerInfo[id - 1];
    }

    //计算百分比
    function calculatePercentageDifference(
        uint256 a,
        uint256 b
    ) public pure returns (uint256) {
        uint256 difference = b - a;
        uint256 percentage = (difference * 100) / a;
        return percentage;
    }

    //管理员推荐人绑定
    function adminBind(
        address[] memory _operAddress,
        address _target
    ) external onlyOwner {
        for (uint256 i = 0; i < _operAddress.length; i++) {
            recommend[_operAddress[i]] = _target;
            teamList[_target].push(_operAddress[i]);
        }
        addTeamInfo(_target, true);
    }

    //推荐人绑定
    function bind(address _operAddress, address _target) public {
        require(msg.sender == _operAddress, "msg error");
        recommend[_operAddress] = _target;
        addTeamInfo(_target, true);
        teamList[_target].push(_operAddress);
    }

    //更新个人/团队人数
    function addTeamInfo(address _target, bool _isZhi) internal {
        Team storage team = _teamInfo[_target];
        if (_isZhi) {
            team.zhi++;
        }
        team.team++;
        address top = recommend[_target];
        if (top != address(0)) {
            addTeamInfo(top, false);
        }
    }

    //添加团队业绩
    function addTeamAmountInfo(address _target, uint256 _amount) internal {
        Team storage team = _teamInfo[_target];
        team.teamAmount += _amount;
        address top = recommend[_target];
        if (top != address(0)) {
            addTeamAmountInfo(top, _amount);
        }
    }

    //添加管理员2%地址
    function addAdminRewardUser(
        address _target,
        uint256 _weight
    ) external onlyOwner {
        adminRewardList.push(Admin2RewardInfo(_target, _weight));
        totalAdminWeight += _weight;
    }

    //修改20%产出指定地址
    function setTargetAddress20(address _target) external onlyOwner {
        _targetAddress20 = _target;
    }

    //修改算力增加万分比 默认100 即1%
    function setPowerFee(uint256 fee) external onlyOwner {
        addPowerFee = fee;
    }

    //修改5%产出指定地址
    function setTargetAddress5(address _target) external onlyOwner {
        _targetAddress5 = _target;
    }

    //修改token地址
    function setToken(address _target) external onlyOwner {
        _token = _target;
    }

    //修改nft地址
    function setNFT(address _target) external onlyOwner {
        _nft = _target;
    }

    //查询推荐人
    function getRecommend(address _address) external view returns (address) {
        return recommend[_address];
    }

    //查看直推地址
    function getTeamList(
        address _target
    ) external view returns (address[] memory) {
        return teamList[_target];
    }

    //查看tList地址
    function getTListList() external view returns (address[] memory) {
        return tList;
    }

    // 获取最新50台矿机入单记录
    function getFirst50Elements()
        public
        view
        returns (BuyRecord[] memory result)
    {
        uint length = _buyRecord.length;
        uint count = length < 50 ? length : 50;
        result = new BuyRecord[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = _buyRecord[(start + i) % 1000];
        }
        return result;
    }

    // 获取最新51-200台矿机入单记录
    function getElements51to550()
        public
        view
        returns (BuyRecord[] memory result)
    {
        uint length = _buyRecord.length;
        uint count = length < 500 ? length : 500;
        result = new BuyRecord[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = _buyRecord[(start + 50 + i) % 1000];
        }
        return result;
    }

    //获取我的团队信息
    function getMyTeam(address _target) external view returns (Team memory) {
        return _teamInfo[_target];
    }

    //获取个人信息  推荐人地址 个人u总价值 个人算力 剩余额度(代币） 排名
    function getMyInfo(
        address _target
    ) external view returns (address, uint256, uint256, uint256, uint256) {
        address top = recommend[_target];
        PledgeOrder memory order = _orders[_target];
        return (top, order.totalU, order.power, order.remain, order.rank);
    }

    //获取个人信息 均分 节点矿池排行未领取收益 新增业绩排行未领取收益 管理员2%收益
    function getMyInfo2(
        address _target
    ) external view returns (uint256, uint256, uint256, uint256) {
        PledgeOrderReward memory order = _ordersReward[_target];
        return (
            order.zhiRankReward,
            order.zhiJunRankReward,
            order.weekRankReward,
            order.admin2Reward
        );
    }

    //查询tRankAddress长度
    function getTRankLength() external view returns (uint256) {
        return tRankAddress.length;
    }

    //查询tRankAddress信息
    function getTRankAddress(
        uint i
    ) external view returns (address user, uint256 reward) {
        return (tRankAddress[i].user, tRankAddress[i].reward);
    }

    //查询管理员2%总权重
    function getTotalAdminWeight() external view returns (uint256) {
        return totalAdminWeight;
    }

    //查询管理员2%收益列表
    function getAdminRewardList()
        external
        view
        returns (Admin2RewardInfo[] memory)
    {
        return adminRewardList;
    }

    //查询指定周的所有用户地址
    function getWeekUsers(
        uint256 weekId
    ) external view returns (address[] memory) {
        return weekUsers[weekId];
    }

    //查询指定日期全网算力
    function getDayPower(uint256 _time) external view returns (uint256) {
        return powerInfo[_time];
    }

    //查询指定日期新增业绩
    function getWeekTotal(uint256 _time) external view returns (uint256) {
        return weekTotal[_time];
    }

    //查询质押记录
    function getPladeList(
        address _target
    ) external view returns (PladgeRecord[] memory) {
        return pladeList[_target];
    }

    //查询收益记录
    function getRewardList(
        address _target
    ) external view returns (RewardRecord[] memory) {
        return rewardList[_target];
    }

    //查询2%权重收益记录
    function getAdminRewardList(
        address _target
    ) external view returns (PladgeRecord[] memory) {
        return adminRewardRecord[_target];
    }
    //领取收益
    function getReawrd(address _target) external {
        //require(!_isReward[block.timestamp / 1 days + 1][_target], "You can only receive it once a day");
        //70%铸币
        PledgeOrder storage order = _orders[_target];
        require(order.remain > 0, "no reward");
        require(order.isExist, "status error");
        require(order.lastTime < id, "no reward time");
        uint256 res = reawrd70(_target, order.remain);
        res = res > order.remain ? order.remain : res;
        order.remain -= res;
        if (order.remain <= 0) {
            order.isExist = false;
        }
        //20%
        IERC20(_token).transfer(_targetAddress20, res / 5);
        //5%
        IERC20(_token).transfer(_targetAddress5, res / 20);
        PledgeOrderReward storage orders = _ordersReward[_target];
        if (orders.zhiJunRankReward > 0) {
            //节点矿池排行均分未领取收益
            IERC20(_token).transfer(_target, orders.zhiJunRankReward);
            orders.zhiJunRankReward = 0;
        }
        if (orders.zhiRankReward > 0) {
            //节点矿池排行未领取收益
            IERC20(_token).transfer(_target, orders.zhiRankReward);
            orders.zhiRankReward = 0;
        }
        if (orders.weekRankReward > 0) {
            //周新增业绩排行未领取收益
            IERC20(_token).transfer(_target, orders.weekRankReward);
            orders.weekRankReward = 0;
        }
        if (orders.admin2Reward > 0) {
            //管理员2%未领取收益
            IERC20(_token).transfer(_target, orders.admin2Reward);
            adminRewardRecord[_target].push(
                PladgeRecord(orders.admin2Reward, block.timestamp)
            );
            orders.admin2Reward = 0;
        }
        _isReward[id][_target] = true;
        order.lastTime = id;
    }
    //查询全网T
    function getTotalT() external view returns (uint256) {
        return lastTotalT;
    }

    //查询个人领取累计额度
    function getRewardTotal(address _target) external view returns (uint256) {
        return rewardTotalAmount[_target];
    }

    //查询日产出 无精度
    function getTodayProduceNoDecimal() public view returns (uint256) {
        return todayProduce / 10 ** 18;
    }

    //领取主链币余额
    function claimBalance(address fundAddress) external onlyOwner {
        payable(fundAddress).transfer(address(this).balance);
    }

    //领取代币余额
    function claimToken(
        address fundAddress,
        address token,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(fundAddress, amount);
    }

    //查询地址之前T
    function getLastTByUser(address _target) external view returns (uint256) {
        return _lastT[_target];
    }

    //查询代币价值u
    function getTokenPriceByU(uint total) public view returns (uint) {
        uint256 price = _swapContract.getPrice();

        return (total * price) / 10 ** 18;
    }

    //查询u价值代币
    function getUPriceByToken(uint total) public view returns (uint) {
        uint256 price = _swapContract.getPrice();

        return (total / price) * 10 ** 18;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
