// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface IFoMox {
    function isCommunityLeader(address leader) external view returns (bool);
    function communityLeaderOf(address user) external view returns (address);
    function isExemptFromTransferRestrictions(address addr) external view returns (bool);
    function referrers(address user) external view returns (address);
    function getDirectReferralPercent() external view returns (uint256);
     function getIndirectReferralPercent() external view returns (uint256);
     function getMaxReferralLevels() external view returns (uint256);
    function getBuyReferralPercent() external view returns (uint256);
    function getCommunityRewardAddress() external view returns (address);
    function checkAddressEffect(address addr) external view returns (bool);
}

contract FToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    // FoMox合约接口
    IFoMox public fomoxContract;
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
    
    // 事件
    event ReferralRegistered(address indexed referrer, address indexed referee);
     event CommunityLeaderAssigned(address indexed user, address indexed leader);
    event TokensMinted(address indexed to, uint256 amount);
    event CommunityLeaderFeeDistributed(address indexed user, address indexed leader, uint256 amount);

       modifier onlyFomox() {
        require(msg.sender == address(fomoxContract) || msg.sender == owner(), "Ownable: caller is not the owner");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        string memory name,
        string memory symbol,
        address _fomoxAddress,
        address usdtAddress
    ) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        
        fomoxContract = IFoMox(_fomoxAddress);
        usdtContract = ERC20Upgradeable(usdtAddress);
        // 初始铸造一些代币给部署者
        _mint(msg.sender, 1000000 * 10**decimals());
    }
    
    // 重写transfer函数，添加推荐关系逻辑
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        // 检查是否是1个代币的转账，如果是则处理推荐关系
        if (amount == 1 * 10**decimals() && !fomoxContract.isExemptFromTransferRestrictions(recipient)) {
            _processReferralRelationship(msg.sender, recipient);
        }
        
        return super.transfer(recipient, amount);
    }
    
    // 重写transferFrom函数，添加推荐关系逻辑
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        // 检查是否是1个代币的转账，如果是则处理推荐关系
        if (amount == 1 * 10**decimals() && !hasReferrer[recipient] && !fomoxContract.isExemptFromTransferRestrictions(recipient)) {
            _processReferralRelationship(sender, recipient);
        }
        
        return super.transferFrom(sender, recipient, amount);
    }
    
    // 处理推荐关系和社区长继承
    function _processReferralRelationship(address referrer, address user) private {
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
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }
    
    // 注册社区长
    function registerCommunityLeader(address leader) external onlyOwner {
        require(leader != address(0), "Invalid address");
        isCommunityLeader[leader] = true;
    }
    
    // 撤销社区长身份
    function unregisterCommunityLeader(address leader) external onlyOwner {
        require(isCommunityLeader[leader], "Not a community leader");
        isCommunityLeader[leader] = false;
    }
    
    // 手动设置用户的社区长
    function setCommunityLeader(address user, address leader) external onlyOwner {
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
    function setReferrer(address user, address referrer) external onlyOwner {
        require(user != address(0) && referrer != address(0), "Invalid address");
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
    function getReferrals(address user) external view returns (address[] memory) {
        return referrals[user];
    }
    
    // 获取社区长的成员
    function getCommunityMembers(address leader) external view returns (address[] memory) {
        return communityMembers[leader];
    }
    
    // 设置FoMox合约地址
    function setFoMoxAddress(address _fomoxAddress) external onlyOwner {
        require(_fomoxAddress != address(0), "Invalid address");
        fomoxContract = IFoMox(_fomoxAddress);
    }
    

  // 处理推荐奖励
    function processReferralRewards(address user, uint256 totalReferralFee) internal nonReentrant {
        if (totalReferralFee == 0) return;
        
        address currentRef = referrers[user];
        uint256 directFee = totalReferralFee * (fomoxContract.getDirectReferralPercent()) / (fomoxContract.getBuyReferralPercent());
        uint256 indirectFeePerLevel = totalReferralFee *(fomoxContract.getIndirectReferralPercent()) / (fomoxContract.getBuyReferralPercent()) / (fomoxContract.getMaxReferralLevels() - 1);
        
        uint256 distributedFee = 0;
        uint256 currentLevel = 1;
        
        // 处理直推奖励
        if (currentRef != address(0) && !fomoxContract.isExemptFromTransferRestrictions(currentRef)) {
            if (fomoxContract.checkAddressEffect(currentRef)) {
                usdtContract.transfer(currentRef, directFee);
                distributedFee = distributedFee + (directFee);
            }
            // 处理间接推荐奖励
            currentRef = referrers[currentRef];
            currentLevel++;
            
            while (currentRef != address(0) && currentLevel <= fomoxContract.getMaxReferralLevels()) {
                if (referralCount[currentRef] >= currentLevel - 1 && fomoxContract.checkAddressEffect(currentRef)) {
                    usdtContract.transfer(currentRef, indirectFeePerLevel);
                    distributedFee = distributedFee + (indirectFeePerLevel);
                 }
                
                currentRef = referrers[currentRef];
                currentLevel++;
            }
        }
        
        // 剩余未分配的奖励发送给社区奖励地址
        uint256 remainingFee = totalReferralFee - (distributedFee);
        if (remainingFee > 0) {
            usdtContract.transfer(fomoxContract.getCommunityRewardAddress(), remainingFee);
        }
    }

        // 辅助函数：处理社区长费用
    function processCommunityLeaderFee(address seller, uint256 leaderFee, uint256 totalFees, uint256 feeUSDTReceived) external onlyFomox {
        if (leaderFee > 0) {
            address leader = communityLeaderOf[seller];
            uint256 leaderUSDTFee = feeUSDTReceived*leaderFee/totalFees;
            if (leader != address(0)) {
                usdtContract.transfer(leader, leaderUSDTFee);
                emit CommunityLeaderFeeDistributed(seller, leader, leaderUSDTFee);
            } else {
                // 如果用户没有社区长，转给社区奖励地址
                usdtContract.transfer(fomoxContract.getCommunityRewardAddress(), leaderUSDTFee);
            }
        }
    }
 
    // 获取社区长成员数量
    function getCommunityMemberCount(address leader) external view returns (uint256) {
        return communityMembers[leader].length;
    }
    // UUPS 升级函数
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
