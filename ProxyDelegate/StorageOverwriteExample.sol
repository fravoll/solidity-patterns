/*
    This example shows how storage has to be in the same order in the proxy
    as well as in the delegate contract. This is not the case here, as the
    delegate declares the uint n and the proxy declares an address before the
    uint.
    To test the behavior proceed as follows:
      1. Deploy the Delegate contract
      2. Deploy the Proxy contract with the address of Delegate as input parameter
      3. Deploy the Caller contract with the address of Proxy as input parameter
      4. Call the go() function of the Caller contract
      5. Check value of delegate variable in Proxy, which is now the address
         0x0000000000000000000000000000000000000005
*/

pragma solidity ^0.4.21;

contract Proxy {

    // The delegate address will be overwritten with the
    // value that was supposed to be stored in n
    address public delegate;
    uint public n = 1;

    function Proxy(address _delegateAdr) public {
        delegate = _delegateAdr;
    }

    function() external payable {

        assembly {
            let _target := sload(0)
            calldatacopy(0x0, 0x0, calldatasize)
            let result := delegatecall(gas, _target, 0x0, calldatasize, 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize)
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize)}
        }
    }
}

contract Delegate {

    // Storage is not in the same order as in the Proxy contract
    uint public n = 1;

    function adds() public {
        n = 5;
    }
}

contract Caller {

    Delegate proxy;

    function Caller(address _proxyAdr) public {
        proxy = Delegate(_proxyAdr);
    }

    function go() public {
       proxy.adds();
    }
}
