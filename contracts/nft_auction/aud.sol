// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";



contract MultiNFTAuction  is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    // 定义拍卖结构体
    struct Auction {
        ERC721Upgradeable nft; // 拍卖的NFT合约地址
        uint256 nftId; // NFT的唯一ID
        uint256 lastPrice; // 金额
        address lastBidder; // 最后出价者
        uint256 expiredTime; // 创建时间
        mapping(address => uint256) bids; // 每个出价者的出价金额
    }
    // 用户与推荐人的关系映射 (每个用户只能绑定一个推荐人)
    mapping(address => address) public userReferrer;
    mapping(uint256 => Auction) public auctions; // 所有拍卖的映射
    uint256 public auctionCounter; // 拍卖计数器
    string public baseURI;

    address public FOUNDATION_RECEIVE_ADDRESS = 0x1CDe2d7d9d160b2299A87A3B335DD74D87B9f948; // 基金会收款地址
    address public TEAM_RECEIVE_ADDRESS = 0x1CDe2d7d9d160b2299A87A3B335DD74D87B9f948; // 基金会收款地址
    address public TOP10_RECEIVE_ADDRESS = 0x1CDe2d7d9d160b2299A87A3B335DD74D87B9f948; // 基金会收款地址
    address public LUCKY_POOL_RECEIVE_ADDRESS = 0x1CDe2d7d9d160b2299A87A3B335DD74D87B9f948; // 幸运奖池

    uint256 public NFT_PRICE_INCR = 110; // 每次10%增加
    uint256 public constant NFT_EXPIRED_TIME = 8*60*60; // 8x60x60 = 8小时
    uint256 public constant LAST_PERCENT = 945; // 推荐人分配比例 1%
    uint256 public constant REFERRER_FEE_PERCENT = 100; // 推荐人分配比例 1%
    uint256 public constant TOP10_FEE_PERCENT = 100; // 最后10名最高出价 1%
    uint256 public constant FOUNDATION_FEE_PERCENT = 300; // 基金会分配比例 3%
    uint256 public constant TEAM_FEE_PERCENT = 50; // 团队分配比例 0.5%
    

    // 用户相关映射
    mapping(address => address[]) public userReferrals; // 用户与推荐人关系映射 (支持多个推荐人)
    mapping(address => uint256) public lastParticipationDay; // 用户最后参与竞拍的日期

    // 事件定义
    event AuctionCreated(uint256 auctionId, address nft, uint256 nftId); // 创建拍卖事件
    event BidPlaced(uint256 auctionId, address indexed bidder, uint256 amount); // 出价事件
    event UserBound(address user, address referrer); // 用户绑定推荐人事件
    event LuckyPoolDistributed(uint256 day, uint256 totalAmount); // 幸运奖池分配事件

    // 创建拍卖
    function createAuction(
        address _nft,
        uint256 _nftId,
        uint256 _price
    ) external onlyOwner {
        Auction storage auction = auctions[auctionCounter++];
        auction.nft = ERC721Upgradeable(_nft);
        auction.nftId = _nftId;
        auction.lastPrice = _price;
        auction.lastBidder = msg.sender;
        auction.expiredTime = block.timestamp+NFT_EXPIRED_TIME;
        emit AuctionCreated(auctionCounter - 1, _nft, _nftId);
    }


function safeMint(address to, uint256 tokenId) public onlyOwner {
    _safeMint(to, tokenId);
}

// 绑定用户和推荐人
function bindUser(address _referrer) external {
    require(_referrer != msg.sender, "Cannot refer yourself"); // 防止用户推荐自己
    require(userReferrer[msg.sender] == address(0), "Referrer already set"); // 每个用户只能绑定一个推荐人
    require(_referrer != address(0), "Referrer address cannot be zero"); // 推荐人地址不能为空

    userReferrer[msg.sender] = _referrer; // 记录推荐人
    emit UserBound(msg.sender, _referrer);
}


function getDayStart() public view returns (uint256) {
    return block.timestamp - (block.timestamp % 86400);
}

// 用户出价
function placeBid(uint256 auctionId) external payable {
    Auction storage auction = auctions[auctionId];
    require(auction.lastPrice > 0, "nft price must gt 0"); // 检查出价是否符合规则
    require(auction.lastBidder != address(0), "nft address must not null"); // 检查出价是否符合规则
    require(auction.expiredTime >= block.timestamp, "nft has end"); // 检查出价是否符合规则

    auction.lastPrice = auction.lastPrice * NFT_PRICE_INCR / 100; // 每次出价增加10%
    // 如果有之前的最高出价者，返还其奖励 
    payable(auction.lastBidder).transfer((auction.lastPrice * LAST_PERCENT) / 1000);// 94.5% 返还给上一最高出价者
    payable(TOP10_RECEIVE_ADDRESS).transfer((auction.lastPrice * TOP10_FEE_PERCENT) / 1000);
    payable(FOUNDATION_RECEIVE_ADDRESS).transfer((auction.lastPrice * FOUNDATION_FEE_PERCENT) / 1000);
    payable(LUCKY_POOL_RECEIVE_ADDRESS).transfer((auction.lastPrice * TEAM_FEE_PERCENT) / 1000);

    //当天参与过竞拍的推荐人1%分成
    if ((userReferrer[msg.sender] != address(0)) && lastParticipationDay[userReferrer[msg.sender]] >=getDayStart()) {
        payable(userReferrer[msg.sender]).transfer((auction.lastPrice * REFERRER_FEE_PERCENT) / 1000);
    }

    // 更新拍卖信息
    auction.lastBidder = msg.sender;
    auction.bids[msg.sender] += auction.lastPrice; // 更新用户出价金额
    // 直接转移NFT所有权给当前最高出价者
    auction.nft.transferFrom(auction.lastBidder, msg.sender, auction.nftId);
    // 更新用户当天的参与状态
    lastParticipationDay[msg.sender] = block.timestamp;
    emit BidPlaced(auctionId, msg.sender, msg.value);
}


    function initialize(address initialOwner) initializer public {
        __ERC721_init("MyToken", "MTK");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function setBaseURI(string calldata  _url ) public onlyOwner{
        baseURI = _url;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
