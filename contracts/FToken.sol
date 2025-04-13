// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./IPoolBase.sol";

interface IFoMox {
    function isCommunityLeader(address leader) external view returns (bool);
    function communityLeaderOf(address user) external view returns (address);
    function checkIsExemptFromTransferRestrictions(
        address addr
    ) external view returns (bool);
    function referrers(address user) external view returns (address);
    function getDirectReferralPercent() external view returns (uint256);
    function getIndirectReferralPercent() external view returns (uint256);
    function getMaxReferralLevels() external view returns (uint256);
    function getBuyReferralPercent() external view returns (uint256);
    function getCommunityRewardAddress() external view returns (address);
    function checkAddressEffect(address addr) external view returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract FToken is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    // FoMox合约接口
    IFoMox public fomoxContract;
    IUniswapV2Router02 public router;
    // FoPool合约接口
    IPoolBase public foPoolContract;
    IPoolBase public moPoolContract;
    ERC20Upgradeable public usdtContract;
    // 推荐关系
    mapping(address => address) public referrers; // 用户的推荐人
    mapping(address => address[]) public referrals; // 用户的直接推荐列表
    mapping(address => uint256) public referralCount; // 用户的直接推荐数量

    // 社区长相关
    mapping(address => bool) public isCommunityLeader; // 是否是社区长
    mapping(address => address) public communityLeaderOf; // 用户的社区长地址
    mapping(address => address[]) public communityMembers; // 社区长的所有成员

    // 是否已建立推荐关系的记录
    mapping(address => bool) public hasReferrer;
    uint256 public directReferralPercent; // 直推比例
    uint256 public maxReferralLevels; // 最大推荐层级
    mapping(address => bool) public isExemptFromTransferRestrictions;
    userFoMoxAmount[] public userFoMoxFees;
    uint256 public userFoMoxFeeIndex;
    uint256 public swapCount;

    struct userFoMoxAmount {
        address addr;
        uint256 amount;
        uint256 teachAmount;
    }

    // 事件
    event ReferralRegistered(address indexed referrer, address indexed referee);
    event CommunityLeaderAssigned(address indexed user, address indexed leader);
    event TokensMinted(address indexed to, uint256 amount);
    event CommunityLeaderFeeDistributed(
        address indexed user,
        address indexed leader,
        uint256 amount
    );

    modifier onlyFomox() {
        require(
            msg.sender == address(fomoxContract) || msg.sender == owner(),
            "Ownable: caller is not the owner"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _usdtAddress,
        address _router
    ) public initializer {
        __ERC20_init("FToken", "F");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        usdtContract = ERC20Upgradeable(_usdtAddress);
        

        // 初始铸造一些代币给部署者
        _mint(msg.sender, 1000000 * 10 ** decimals());
        directReferralPercent = 1; // 直推1%
        maxReferralLevels = 7; // 最大7级推荐
        router = IUniswapV2Router02(_router);

        // 添加初始例外地址
        isExemptFromTransferRestrictions[address(0)] = true;
        isExemptFromTransferRestrictions[address(0xdead)] = true;
        swapCount = 1;
    }

    // 重写transfer函数，添加推荐关系逻辑
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        // 先执行基本的转账逻辑，确保状态更新在前
        bool success = super.transfer(recipient, amount);
        
        // 只有转账成功后才处理其他逻辑
        if (success) {
            // 如果需要处理推荐关系
            if (
                !hasReferrer[recipient] &&
                !isExemptFromTransferRestrictions[recipient]
            ) {
                _processReferralRelationship(msg.sender, recipient);
            }
            
            // 处理推荐奖励（应考虑将此逻辑移出转账函数）
            processReferralRewards();
        }
        
        return success;
    }

    // 重写transferFrom函数，添加推荐关系逻辑
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        // 先执行基本的转账逻辑
        bool success = super.transferFrom(sender, recipient, amount);
        
        // 只有转账成功后才处理其他逻辑
        if (success) {
            // 如果需要处理推荐关系
            if (
                !hasReferrer[recipient] &&
                !isExemptFromTransferRestrictions[recipient]
            ) {
                _processReferralRelationship(sender, recipient);
            }
            
            // 处理推荐奖励
            processReferralRewards();
        }
        
        return success;
    }

   

    // 修改为受保护的公共函数
    function swapUSDTTokens(uint256 tokenAmount) internal {
        // require(msg.sender == address(this) || msg.sender == owner(), "Unauthorized");
        
        // 使用有限授权
        bool approved = fomoxContract.approve(address(router), tokenAmount);
        require(approved, "Approval failed");

        address[] memory path = new address[](2);
        path[0] = address(fomoxContract);
        path[1] = address(usdtContract);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
             0, // 最小获取量应该设置一个合理值
            path,
            address(this),
            block.timestamp + 300
        );
    }

    function processRewards(
        address user,
        uint256 amount,
        uint256 teachAmount
    ) public onlyFomox nonReentrant {
        require(user != address(0), "Invalid address");
        require(amount > 0 || teachAmount > 0, "Invalid amounts");

        // 添加用户的推荐奖励
        userFoMoxFees.push(userFoMoxAmount(user, amount, teachAmount));
    }

    function setSwapCount(uint256 _swapCount) public onlyOwner {
        swapCount = _swapCount;
    }
    
    
    // 修改处理推荐奖励函数，添加访问控制和防重入保护
    function processReferralRewards() public nonReentrant {
        // require(tx.origin == msg.sender || msg.sender == address(this) || msg.sender == owner(), "Unauthorized");
        
        uint256 count = userFoMoxFees.length;
        uint256 processedCount = 0;
        uint256 maxProcessPerCall = swapCount; // 限制每次处理的数量
        
        while (count > userFoMoxFeeIndex && processedCount < maxProcessPerCall) {
             processedCount++;
            
            userFoMoxAmount memory item = userFoMoxFees[userFoMoxFeeIndex];
            if (item.addr == address(0)) {
                userFoMoxFeeIndex++;
                continue;
            }
            
            uint256 totalAmount = item.amount + item.teachAmount;
            if (totalAmount == 0) {
                userFoMoxFeeIndex++;
                continue;
            }
            
            uint256 usdtBefore = usdtContract.balanceOf(address(this));
            
            // 安全调用swap函数
                swapUSDTTokens(totalAmount);
                uint256 usdtAfter = usdtContract.balanceOf(address(this));
                uint256 usdtAmount = usdtAfter > usdtBefore ? usdtAfter - usdtBefore : 0;
                
                if (usdtAmount == 0) {
                    userFoMoxFeeIndex++;
                    continue;
                }
                
                _distributeReferralRewards(item.addr, usdtAmount, item.amount, totalAmount);
             
            
            // 安全删除处理过的记录
            delete userFoMoxFees[userFoMoxFeeIndex];
            userFoMoxFeeIndex++;
        }
    }

    function cleanUserFoMoxFees(uint256 index) public onlyOwner {
        require(index < userFoMoxFees.length, "Index out of bounds");
        delete userFoMoxFees[index];
    }
    
    // 分离出奖励分发逻辑
    function _distributeReferralRewards(address user, uint256 usdtAmount, uint256 amount, uint256 totalAmount) internal {
        uint256 distributedFee = 0;
        uint256 currentLevel = 1;
        address currentRef = referrers[user];
        uint256 directFee = usdtAmount * amount / totalAmount / maxReferralLevels;
        
        // 处理直推奖励
        if (
            currentRef != address(0) &&
            !isExemptFromTransferRestrictions[currentRef]
        ) {
            if (checkAddressEffect(currentRef, currentLevel)) {
                bool success = usdtContract.transfer(currentRef, directFee);
                if (success) {
                    distributedFee = distributedFee + directFee;
                }
            }
            
            // 处理间接推荐奖励
            currentRef = referrers[currentRef];
            currentLevel++;
            
            while (
                currentRef != address(0) &&
                currentLevel <= maxReferralLevels
            ) {
                if (
                    referralCount[currentRef] >= currentLevel - 1 &&
                    checkAddressEffect(currentRef, currentLevel)
                ) {
                    bool success = usdtContract.transfer(currentRef, directFee);
                    if (success) {
                        distributedFee = distributedFee + directFee;
                    }
                }

                currentRef = referrers[currentRef];
                currentLevel++;
            }
        }
        
        // 剩余未分配的奖励发送给社区奖励地址
        if (usdtAmount > distributedFee) {
            usdtContract.transfer(
                fomoxContract.getCommunityRewardAddress(),
                usdtAmount - distributedFee
            );
        }
    }

    // 设置FoMox合约地址，避免无限授权
    function setFoMoxAddress(address _fomoxAddress) public onlyOwner {
        require(_fomoxAddress != address(0), "Invalid address");
        
        // 先撤销之前的授权
        if(address(fomoxContract) != address(0)) {
            usdtContract.approve(address(fomoxContract), 0);
        }
        
        fomoxContract = IFoMox(_fomoxAddress);
        
        // 使用有限度的授权，或在需要时授权
        uint256 approvalAmount = 1000000 * 10**18; // 设置一个合理的上限
        usdtContract.approve(_fomoxAddress, approvalAmount);
    }

    // 处理社区长费用，添加安全检查
    function processCommunityLeaderFee(
        address seller,
        uint256 leaderFee
    ) public onlyFomox nonReentrant {
        if (leaderFee > 0) {
            address leader = communityLeaderOf[seller];
            uint256 leaderUSDTFee = leaderFee;
            
            if (leader != address(0)) {
                bool success = usdtContract.transfer(leader, leaderUSDTFee);
                if (success) {
                    emit CommunityLeaderFeeDistributed(
                        seller,
                        leader,
                        leaderUSDTFee
                    );
                }
            } else {
                // 如果用户没有社区长，转给社区奖励地址
                address communityReward = fomoxContract.getCommunityRewardAddress();
                require(communityReward != address(0), "Invalid community reward address");
                usdtContract.transfer(communityReward, leaderUSDTFee);
            }
        }
    }

    // 处理推荐关系和社区长继承
    function _processReferralRelationship(
        address referrer,
        address user
    ) private {
        // 防止自我推荐
        require(referrer != user, "Cannot refer yourself");
        // 建立推荐关系
        referrers[user] = referrer;
        referrals[referrer].push(user);
        referralCount[referrer]++;
        hasReferrer[user] = true;

        emit ReferralRegistered(referrer, user);

        // 处理社区长属性继承
        _assignCommunityLeader(user, referrer);
    }

    // 分配社区长
    function _assignCommunityLeader(address user, address referrer) private {
        // 检查推荐人是否是社区长
        if (isCommunityLeader[referrer]) {
            // 如果推荐人是社区长，直接设置
            communityLeaderOf[user] = referrer;
            communityMembers[referrer].push(user);
            emit CommunityLeaderAssigned(user, referrer);
        } else if (communityLeaderOf[referrer] != address(0)) {
            // 如果推荐人有社区长，继承相同的社区长
            address leader = communityLeaderOf[referrer];
            communityLeaderOf[user] = leader;
            communityMembers[leader].push(user);
            emit CommunityLeaderAssigned(user, leader);
        }
        // 否则用户暂时没有社区长，不发出错误
    }

    // 增发代币
    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    // 注册社区长
    function registerCommunityLeader(address leader) public onlyOwner {
        require(leader != address(0), "Invalid address");
        isCommunityLeader[leader] = true;
    }

    function checkAddressEffect(
        address addr,
        uint256 level
    ) public view returns (bool) {
        bool hasAmount = fomoxContract.balanceOf(addr) > 0 ||
            foPoolContract.getUserAmount(addr) > 0 ||
            moPoolContract.getUserAmount(addr) > 0;

        uint256 dictCount = referrals[addr].length;
        uint256 effectCount = 0;
        while (dictCount > 0 && effectCount < level) {
            dictCount--;
            address referral = referrals[addr][dictCount];
            if (
                fomoxContract.balanceOf(referral) > 0 ||
                foPoolContract.getUserAmount(referral) > 0 ||
                moPoolContract.getUserAmount(referral) > 0
            ) {
                effectCount++;
            }
        }

        if (hasAmount && effectCount >= level) {
            return true;
        }
        return false;
    }

    // 撤销社区长身份
    function unregisterCommunityLeader(address leader) public onlyOwner {
        require(isCommunityLeader[leader], "Not a community leader");
        isCommunityLeader[leader] = false;
    }

    // 手动设置用户的社区长
    function setCommunityLeader(address user, address leader) public onlyOwner {
        require(user != address(0) && leader != address(0), "Invalid address");
        require(isCommunityLeader[leader], "Not a registered community leader");

        // 移除用户与旧社区长的关系（如果有）
        address oldLeader = communityLeaderOf[user];
        if (oldLeader != address(0)) {
            _removeFromCommunityLeader(user, oldLeader);
        }

        // 设置新社区长
        communityLeaderOf[user] = leader;
        communityMembers[leader].push(user);

        emit CommunityLeaderAssigned(user, leader);
    }

    // 从社区长成员列表中移除用户
    function _removeFromCommunityLeader(address user, address leader) internal {
        address[] storage members = communityMembers[leader];
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == user) {
                // 找到用户，将其与列表最后一个元素交换，然后移除最后一个元素
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
    }

    // 手动设置推荐关系
    function setReferrer(address user, address referrer) public onlyOwner {
        require(
            user != address(0) && referrer != address(0),
            "Invalid address"
        );
        require(user != referrer, "Cannot refer yourself");
        require(!hasReferrer[user], "User already has a referrer");

        // 建立推荐关系
        referrers[user] = referrer;
        referrals[referrer].push(user);
        referralCount[referrer]++;
        hasReferrer[user] = true;

        emit ReferralRegistered(referrer, user);

        // 处理社区长属性继承
        _assignCommunityLeader(user, referrer);
    }

    // 获取用户的直接推荐
    function getReferrals(address user) public view returns (address[] memory) {
        return referrals[user];
    }

    // 获取社区长的成员
    function getCommunityMembers(
        address leader
    ) public view returns (address[] memory) {
        return communityMembers[leader];
    }

    function checkIsExemptFromTransferRestrictions(
        address account
    ) public view returns (bool) {
        return isExemptFromTransferRestrictions[account];
    }

    function setIsExemptFromTransferRestrictions(
        address[] calldata accounts,
        bool exempt
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            require(account != address(0), "Invalid address");
            isExemptFromTransferRestrictions[account] = exempt;
        }
    }

    // 设置USDT合约地址
    function setUSDTAddress(address _usdtAddress) public onlyOwner {
        require(_usdtAddress != address(0), "Invalid address");
        usdtContract = ERC20Upgradeable(_usdtAddress);
    }

    // 设置FoPool合约地址
    function setFoPoolAddress(address _foPoolAddress) public onlyOwner {
        require(_foPoolAddress != address(0), "Invalid address");
        foPoolContract = IPoolBase(_foPoolAddress);
    }

    // 设置MoPool合约地址
    function setMoPoolAddress(address _moPoolAddress) public onlyOwner {
        require(_moPoolAddress != address(0), "Invalid address");
        moPoolContract = IPoolBase(_moPoolAddress);
    }

    function deleteUserFoMoxFees(uint256 index) public onlyOwner {
        require(index < userFoMoxFees.length, "Index out of bounds");
        delete userFoMoxFees[index];
    }

    function setUserFoMoxFeeIndex(
        uint256 index
    ) public onlyOwner {
        require(index < userFoMoxFees.length, "Index out of bounds");
        userFoMoxFeeIndex = index;
    }

    // 获取社区长成员数量
    function getCommunityMemberCount(
        address leader
    ) public view returns (uint256) {
        return communityMembers[leader].length;
    }

    // 设置直推比例
    function setDirectReferralPercent(
        uint256 _directReferralPercent
    ) public onlyOwner {
        directReferralPercent = _directReferralPercent;
    }

    function getDirectReferralPercent() public view returns (uint256) {
        return directReferralPercent;
    }

    function getmaxReferralLevels() public view returns (uint256) {
        return maxReferralLevels;
    }

    // 设置最大推荐层级
    function setMaxReferralLevels(uint256 _maxReferralLevels) public onlyOwner {
        maxReferralLevels = _maxReferralLevels;
    }

    // UUPS 升级函数
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
