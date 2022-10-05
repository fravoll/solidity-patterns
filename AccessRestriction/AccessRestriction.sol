// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.

pragma solidity ^0.4.21;

contract AccessRestriction {

    address public owner = msg.sender;
    uint public creationTime = block.timestamp;

    modifier onlyBy(address _account) {
        require(msg.sender == _account,   // when we give comma here means check below if this fails.
        'Sender not authorized!'
        );
        _;
    }

    modifier onlyAfter(uint _time) {

        require(block.timestamp >= _time,
        'FUnction is called too early!');
        _;

    }

    function changeOenerAddress(address _newAddress) onlyBy(owner) public {
        owner = _newAddress;
    }

    // function that can disown the current owner.

    function disOwn(address _new) public {
        require(msg.sender == _new);
        owner != msg.sender;
    }

    function disOwn() onlyBy(owner) onlyAfter(creationTime + 4 weeks) public {
        delete owner;
    }

}

