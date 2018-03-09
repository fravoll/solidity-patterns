pragma solidity ^0.4.20;
contract CheapStructPackingExample {

    struct CheapStruct {
        uint8 a; //uses 1 byte writes in new slot
        uint8 b; //uses 1 byte writes in previous slot
        uint8 c; //uses 1 byte writes in previous slot
        uint8 d; //uses 1 byte writes in previous slot
        bytes1 e; //uses 1 byte writes in previous slot
        bytes1 f; //uses 1 byte writes in previous slot
        bytes1 g; //uses 1 byte writes in previous slot
        bytes1 h; //uses 1 byte writes in previous slot
    }

    CheapStruct example;

    function addCheapStruct() public {
        CheapStruct memory someStruct = CheapStruct(1,2,3,4,"a","b","c","d");
        example = someStruct;
    }
}

contract ExpensiveStructPackingExample {

    struct ExpensiveStruct {
        uint64 a; //uses 8 bytes
        bytes32 e; //uses 32 bytes writes in new slot
        uint64 b; //uses 8 bytes writes in new slot
        bytes32 f; //uses 32 bytes writes in new slot
        uint32 c; //uses 4 bytes writes in new slot
        bytes32 g; //uses 32 bytes writes in new slot
        uint8 d; //uses 1 byte writes in new slot
        bytes32 h; //uses 32 bytes writes in new slot
    }

    ExpensiveStruct example;

    function addExpensiveStruct() public {
        ExpensiveStruct memory someStruct = ExpensiveStruct(1,"a",2,"b",3,"c",4,"d");
        example = someStruct;
    }
}
