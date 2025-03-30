// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title FToken
 * @dev 用于绑定推荐关系的代币，可增发
 */
contract FToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    address public foMoxAddress; // FoMox合约地址
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev 初始化合约
     * @param _initialSupply 初始供应量
     */
    function initialize(uint256 _initialSupply) public initializer {
        __ERC20_init("F Token", "F");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        
        // 铸造初始代币给部署者
        _mint(msg.sender, _initialSupply);
    }
    
    /**
     * @dev 设置FoMox合约地址
     * @param _foMoxAddress FoMox合约地址
     */
    function setFoMoxAddress(address _foMoxAddress) external onlyOwner {
        require(_foMoxAddress != address(0), "Invalid FoMox address");
        foMoxAddress = _foMoxAddress;
    }
    
    /**
     * @dev 铸造新的代币
     * @param _to 接收者地址
     * @param _amount 铸造数量
     */
    function mint(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Mint to zero address");
        _mint(_to, _amount);
    }
    
    /**
     * @dev 代币转移后执行的钩子函数，用于处理推荐关系的注册
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        address from = _msgSender();
        bool result = super.transfer(to, amount);

        // 当转账恰好1个代币且FoMox地址已设置时，调用FoMox合约注册推荐关系
        if (amount == 1 * 10**18 && foMoxAddress != address(0)) {
            // 创建调用FoMox合约的接口
            bytes memory callData = abi.encodeWithSignature(
                "transferAndRegisterReferral(address,address)", 
                from, 
                to
            );
            
            // 调用FoMox合约
            (bool success, ) = foMoxAddress.call(callData);
            // 允许调用失败，不影响转账成功
            if (!success) {
                revert("Failed to register referral");
            }
        }

        return result;
    }
    
    /**
     * @dev 授权升级权限
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
