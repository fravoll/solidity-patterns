pragma solidity ^0.4.19;
contract StringEqualityComparisonGasExample {

    function hashCompareInternal(string a, string b) internal returns (bool) {
        return keccak256(a) == keccak256(b);
    }

    function utilCompareInternal(string a, string b) internal returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        }
        for (uint i = 0; i < bytes(a).length; i ++) {
            if(bytes(a)[i] != bytes(b)[i]) {
                return false;
            }
        }
        return true;
    }

    function hashCompareWithLengthCheckInternal(string a, string b) internal returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(a) == keccak256(b);
        }
    }

    function hashCompare(string a, string b) public returns (bool) {
        return hashCompareInternal(a, b);
    }

    function utilCompare(string a, string b) public returns (bool) {
        return utilCompareInternal(a, b);
    }

    function hashCompareWithLengthCheck(string a, string b) public returns (bool) {
        return hashCompareWithLengthCheckInternal(a, b);
    }
}
