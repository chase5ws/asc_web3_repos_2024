// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.2/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts@5.0.2/access/Ownable.sol";

/// @custom:security-contact chase5ws@gmail.com
contract AscCatSamurai is ERC721, ERC721Enumerable, ERC721Pausable, Ownable {
    uint256 private _nextTokenId;
    string private _baseTokenURI;
    //最大供應數量
    uint256 maxSupply = 500;
    bool public publicMintOpen = false;
    bool public allowListMintOpen = false;
    mapping(address => bool) public allowList;
    address[] public allowListAddresses; // This array will keep track of the addresses


    //設定擁有者
    constructor(address initialOwner)
        ERC721("asc cat samurai", "acs")
        Ownable(initialOwner)
    {}
    //設定ipfs位置
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // 允许合约所有者更新基本 URI
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    //暫停合約
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Modify the mint windows 管理mint方式
    function editMintWindows(
        bool _publicMintOpen,
        bool _allowListMintOpen
    ) external onlyOwner {
        publicMintOpen = _publicMintOpen;
        allowListMintOpen = _allowListMintOpen;
    }

    // Populate the Allow List 上傳白名單功能
    function setAllowList(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++){
            if (!allowList[addresses[i]]) { // Check if the address is not already in the allowList
                allowList[addresses[i]] = true;
                allowListAddresses.push(addresses[i]); // Add to the allowListAddresses array
            }
        }
    }

    //白名單mint
    // require only the allowList people to mint
    // Add publicMint and allowListMintOpen Variables
    function allowListMint() public payable {
        require(allowListMintOpen, "Allowlist Mint Closed");
        require(allowList[msg.sender], "You are not on the allow list");
        require(msg.value == 0 ether, "Not Enough Funds");
        internalMint();
        // 鑄造成功後，直接將地址從允許列表中移除
        allowList[msg.sender] = false;
    }

    // Add Payment
    // Add limiting of supply
    function publicMint() public payable {
        require(publicMintOpen, "Public Mint Closed");
        require(msg.value == 20 ether, "You are not on the allow list");
    }

    //初始化mint方式
    function internalMint() internal {
        require(totalSupply() < maxSupply, "We Sold Out!");
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    //合約收益抽出
    function withdraw() public payable onlyOwner 
    {
    //withdraw money
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    }
}
