// SPDX-License-Identifier: MIT
// 兼容 OpenZeppelin Contracts ^5.0.0 版本
pragma solidity ^0.8.20;

// 引入所需的 OpenZeppelin 合约
import "@openzeppelin/contracts@5.0.2/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts@5.0.2/access/Ownable.sol";
import "@openzeppelin/contracts@5.0.2/utils/Strings.sol";

/// @custom:security-contact 安全联系邮箱
contract AscCatSamurai is ERC721, ERC721Enumerable, ERC721Pausable, Ownable {
    using Strings for uint256; // 使用 Strings 库为 uint256 类型提供更多功能

    uint256 private _nextTokenId; // 下一个代币的ID
    string private _baseTokenURI; // 基础 URI
    uint256 maxSupply = 500; // 最大供应量
    bool public publicMintOpen = false; // 是否开放公开铸造
    bool public allowListMintOpen = false; // 是否开放白名单铸造
    mapping(address => bool) public allowList; // 白名单列表
    address[] public allowListAddresses; // 白名单地址数组，用于记录白名单用户

    // 构造函数，设置合约的初始拥有者和名称
    constructor(address initialOwner)
        ERC721("asc cat samurai", "acs")
        Ownable(initialOwner)
    {}

    // 返回基础URI的内部函数
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // 允许合约拥有者更新基础URI
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    // 覆盖`tokenURI`函数以添加`.json`扩展名
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        // 如果基础 URI 不为空，则返回完整的代币 URI，否则返回空字符串
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
            : "";
    }

    // 暂停合约功能，仅合约拥有者可调用
    function pause() public onlyOwner {
        _pause();
    }

    // 恢复合约功能，仅合约拥有者可调用
    function unpause() public onlyOwner {
        _unpause();
    }

    // 修改铸造窗口设置
    function editMintWindows(bool _publicMintOpen, bool _allowListMintOpen) external onlyOwner {
        publicMintOpen = _publicMintOpen;
        allowListMintOpen = _allowListMintOpen;
    }

    // 设置白名单
    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (!allowList[addresses[i]]) {
                allowList[addresses[i]] = true;
                allowListAddresses.push(addresses[i]); // 添加到白名单地址数组
            }
        }
    }

    // 白名单铸造功能
    function allowListMint() public payable {
        require(allowListMintOpen, "Allowlist Mint Closed");
        require(allowList[msg.sender], "You are not on the allow list");
        require(msg.value == 0 ether, "Not Enough Funds");
        internalMint(); // 调用内部铸造函数
        allowList[msg.sender] = false; // 从白名单中移除
    }

    // 公开铸造功能
    function publicMint() public payable {
        require(publicMintOpen, "Public Mint Closed");
        require(msg.value == 20 ether, "You are not on the allow list");
        // 铸造逻辑暂未实现
    }

    // 内部铸造函数，处理铸造逻辑
    function internalMint() internal {
        require(totalSupply() < maxSupply, "We Sold Out!"); // 检查是否达到最大供应量
        uint256 tokenId = _nextTokenId++; // 获取下一个代币ID
        _safeMint(msg.sender, tokenId); // 安全铸造
    }

    // Solidity 要求的重写函数

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable, ERC721Pausable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // 提取合约中的余额，仅合约拥有者可调用
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
