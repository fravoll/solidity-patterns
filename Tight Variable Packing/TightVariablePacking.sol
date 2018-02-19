pragma solidity ^0.4.20;
contract CheapStructPackingExample {

    struct CheapStruct {
        uint64 a;
        uint64 b;
        uint32 c;
        uint8 d;
        bytes8 e;
        bytes8 f;
        bytes8 g;
        bytes8 h;
    }

    CheapStruct example;

    function addCheapStruct() {
        CheapStruct memory someStruct = CheapStruct(1,2,3,4,"a","b","c","d");
        example = someStruct;
    }
}

contract ExpensiveStructPackingExample {

    struct ExpensiveStruct {
        uint64 a;
        bytes32 e;
        uint64 b;
        bytes32 f;
        uint32 c;
        bytes32 g;
        uint8 d;
        bytes32 h;
    }

    ExpensiveStruct example;

    function addExpensiveStruct() {
        ExpensiveStruct memory someStruct = ExpensiveStruct(1,"a",2,"b",3,"c",4,"d");
        example = someStruct;
    }
}
