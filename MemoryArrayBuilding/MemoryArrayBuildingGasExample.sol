pragma solidity ^0.4.20;

contract MemoryArrayBuildingCheap {

    struct Item {
        string name;
        string category;
        address owner;
        uint32 zipcode;
        uint32 price;
    }

    Item[] public items;

    mapping(address => uint) public ownerItemCount;

    function getItemsbyOwner(address _owner) public view returns (uint[]) {
        uint[] memory result = new uint[](ownerItemCount[_owner]);

        uint counter = 0;
        for (uint i = 0; i < items.length; i++) {
            if (items[i].owner == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function initialize() public {
        Item memory tempItem = Item("test1", "house", 0xca35b7d915458ef540ade6068dfe2f44e8fa733c, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0xca35b7d915458ef540ade6068dfe2f44e8fa733c]++;

        tempItem = Item("test2", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;

        tempItem = Item("test3", "house", 0xca35b7d915458ef540ade6068dfe2f44e8fa733c, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0xca35b7d915458ef540ade6068dfe2f44e8fa733c]++;

        tempItem = Item("test4", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;

        tempItem = Item("test5", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;

        tempItem = Item("test6", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;

        tempItem = Item("test7", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;

        tempItem = Item("test8", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;

        tempItem = Item("test9", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;

        tempItem = Item("test10", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;
    }
}

contract MemoryArrayBuildingExpensive {

    struct Item {
        string name;
        string category;
        address owner;
        uint32 zipcode;
        uint32 price;
    }

    Item[] public items;

    mapping(address => uint) public ownerItemCount;

    function getItemsbyOwner(address _owner) public returns (uint[]) {
        uint[] memory result = new uint[](ownerItemCount[_owner]);

        uint counter = 0;
        for (uint i = 0; i < items.length; i++) {
            if (items[i].owner == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function initialize() public {
        Item memory tempItem = Item("test1", "house", 0xca35b7d915458ef540ade6068dfe2f44e8fa733c, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0xca35b7d915458ef540ade6068dfe2f44e8fa733c]++;

        tempItem = Item("test2", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;

        tempItem = Item("test3", "house", 0xca35b7d915458ef540ade6068dfe2f44e8fa733c, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0xca35b7d915458ef540ade6068dfe2f44e8fa733c]++;

        tempItem = Item("test4", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;

        tempItem = Item("test5", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;

        tempItem = Item("test6", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;

        tempItem = Item("test7", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;

        tempItem = Item("test8", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;

        tempItem = Item("test9", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;

        tempItem = Item("test10", "house", 0x0ad04da547702b9ca134f929e3c3009424b7da70, 80331, 212);
        items.push(tempItem);
        ownerItemCount[0x0ad04da547702b9ca134f929e3c3009424b7da70]++;
    }
}
