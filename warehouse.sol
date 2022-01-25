// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
    Task:
    The building materials store keeps records of goods.
    Purchase of goods is carried out by purchasing managers,
    release of goods - sellers. Each item is supplied by a single supplier,
    although each supplier may supply a store with multiple items.
 */
contract Storage {

    uint managerRole = 1;
    uint sellerRole = 2;
    uint adminRole = 3;
    
    struct User {
        uint role; // 0 - nobody, 1 - manager, 2 - seller, 3 - admin
    }

    struct Item {
        string name;
        uint count;
        address supplier;
        uint requiredCount;
    }

    mapping (address => User) public users;
    mapping (uint => Item) public warehouse;

    constructor() {
        users[msg.sender] = User(adminRole);
    }

    modifier isAdmin {
        require(users[msg.sender].role == adminRole, "You are not admin");
        _;
    }

    modifier isManager {
        require(users[msg.sender].role == managerRole, "You are not manager");
        _;
    }

    modifier isSeller {
        require(users[msg.sender].role == sellerRole, "You are not seller");
        _;
    }

    modifier isAuthorizedUser(address userAddress) {
        require(users[userAddress].role != 0, "User is not authorized");
        _;
    }

    modifier isOtherAddress(address userAddress) {
        require(msg.sender != userAddress, "Sender address same as specified address");
        _;
    }

    modifier isItemExists(uint itemId) {
        require(hash(warehouse[itemId].name) != hash(""), "Item is not exists");
        _;
    }

    modifier isItemSupplier(uint itemId) {
        require(msg.sender == warehouse[itemId].supplier, "You are not item supplier");
        _;
    }

    modifier isItemRequireSupply(uint itemId) {
        require(warehouse[itemId].requiredCount > 0, "Item not require supply");
        _;
    }

    modifier isItemSupplyCountSuitable(uint itemId, uint count) {
        require(count > 0, "Item supply count can't be zero or negative");
        uint finalRequiredCount = warehouse[itemId].requiredCount - count;
        require(finalRequiredCount >= 0 && finalRequiredCount <= warehouse[itemId].requiredCount, "Item supply count more than required");
        _;
    }

    modifier isItemNotExists(uint itemId) {
        require(hash(warehouse[itemId].name) == hash(""), "Item is exists");
        _;
    }

    modifier isItemSellCountSuitable(uint itemId, uint count) {
        require(count > 0, "Item sell count can't be zero or negative");
        uint finalCount = warehouse[itemId].count-count;
        require(finalCount >= 0 && finalCount <= warehouse[itemId].count, "Item sell count more than available");
        _;
    }

    function setUserRole(address userAddress, uint roleId) public isAdmin isOtherAddress(userAddress){
        users[userAddress].role = roleId;
    }

    function supply(uint itemId, uint count) public isItemExists(itemId) isItemSupplier(itemId) isItemRequireSupply(itemId) isItemSupplyCountSuitable(itemId, count){
        warehouse[itemId].count += count;
        warehouse[itemId].requiredCount -= count;
    }

    function sellItem(uint itemId, uint count) public isSeller isItemExists(itemId) isItemSellCountSuitable(itemId, count){
        warehouse[itemId].count -= count;
    }

    function regItem(uint itemId, string memory name) public isAdmin isItemNotExists(itemId){
        warehouse[itemId] = Item(name, 0, address(0), 0);
    }

    function setItemSupplier(uint itemId, address supplierAddress) public isAdmin isItemExists(itemId){
        warehouse[itemId].supplier = supplierAddress;
    }

    function requestItemSupply(uint itemId, uint count) public isManager isItemExists(itemId){
        assert(count>0);
        warehouse[itemId].requiredCount = warehouse[itemId].requiredCount+count;
    }
    function requestItemStatus(uint itemId) public view isItemExists(itemId) returns (string memory name, uint count, address supplier, uint requiredCount){    
        return (warehouse[itemId].name, warehouse[itemId].count, warehouse[itemId].supplier, warehouse[itemId].requiredCount);
    }

    function hash(string memory str) private pure returns (bytes32){
        return keccak256(abi.encodePacked(str));
    }
}