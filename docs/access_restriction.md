# Access Restriction

## Intent

Restrict the access to contract functionality according to suitable criteria.

## Motivation

Due to the public nature of the blockchain it is not possible to guarantee complete privacy for your contract. You will not be able to prevent someone from reading the state of your contract from the blockchain, since everything is publicly visible for everyone. What can be done, is restricting read access to the state of your contract by other contracts. This is achieved by declaring your state variables as `private`. Also functions can be declared `private`, however doing so would prevent everyone outside the contract scope from calling it under any circumstances. Simply declaring them `public`, however, would open up access to every participant in the network. Most of the times it is desired to allow access to functionality in case certain rules are met. Often the access is supposed to be restricted to a defined set of entities, like the administrators of a contract. Other restrictions should only allow access at a special point in time or if the accessing entity is willing to pay a price for access. All these restrictions, and many more, can be realized by the implementation of the Access Restriction pattern and therefore grant security against unauthorized access to smart contract functionality.

## Applicability

Use the Access Restriction pattern when
* your contract functions should only be callable under certain circumstances.
* you want to apply similar restrictions to several functions.
* you want to increase security of your smart contract against unauthorized access.

## Participants & Collaborations

The participants in this pattern are the calling entity of the function to be restricted, and the contract the function belongs to. The calling entity can either be a user or another contract and invokes the function by sending a transaction to the respective contract address. The actors involved in the called contract are the restricted function as well as an additional component that is responsible for the actual access control. 

## Implementation

For the implementation of the Access Restriction pattern we are using the [Guard Check pattern](./guard_check.md). The functionality provided by the Guard Check pattern allows us to check for the required circumstances once a function is called, and throws an exception, in case they are not met. One could argue that the checks could be placed at the beginning of the corresponding function aswell. However, since these checks are often reused for more than one function, we recommend to outsource the job to modifiers, which can then be applied to the functions needing them. Modifiers can take arguments from the input parameters of the respective function, be provided with their own arguments, or have the condition hard-coded in their body, which limits reusability.

The structure of these modifiers usually follows the same pattern: In the beginning the required condition is checked. Afterwards the execution jumps back to the initial function. This behavior is indicated by an underscore (`_;`) in the code of the modifier. If there is extra behavior that should be executed after the function, it is possible to insert additional code following the underscore in the modifier. This pattern, in particular the condition check in the beginning of the modifier, can be adapted in many ways to provide a variety of different access restrictions.  

## Sample Code

The following code features three different kinds of access restrictions in an example contract owned by an owner and is influenced by the [example from the Solidity documentation](http://solidity.readthedocs.io/en/v0.4.21/common-patterns.html#restricting-access). Ownership can either be transferred by the current owner himself or be bought by anybody for 1 ether, after a month has passed since the last change in ownership.  
```Solidity
// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.
pragma solidity ^0.4.21;

contract AccessRestriction {

    address public owner = msg.sender;
    uint public lastOwnerChange = now;
    
    modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }
    
    modifier onlyAfter(uint _time) {
        require(now >= _time);
        _;
    }
    
    modifier costs(uint _amount) {
        require(msg.value >= _amount);
        _;
        if (msg.value > _amount) {
            msg.sender.transfer(msg.value - _amount);
        }
    }
    
    function changeOwner(address _newOwner) public onlyBy(owner) {
        owner = _newOwner;
    }
    
    function buyContract() public payable onlyAfter(lastOwnerChange + 4 weeks) costs(1 ether) {
        owner = msg.sender;
        lastOwnerChange = now;
    }
}
```

In line 5-6 the state variables `owner` and `lastOwnerChange` are initialized at contract creation time with the creator of the contract and the current timestamp. The first modifier `onlyBy(address _account)` in line 8 is attached to the `changeOwner(..)` function from line 26 and makes sure that the initiator of the function (`msg.sender`) is equal to the variable provided in the modifier call, which in this case is `owner`. The usage of this modifier leads to an exception being thrown, every time the guarded function is called by anybody besides the current owner.

The second modifier `onlyAfter(uint _time)` works in the same way, with the difference that it throws if the function it is attached to is called before the specified time. It is used in line 30 and is provided with the time of the last change of ownership plus four weeks (Four weeks are added instead of one month because Solidity does not support months as a unit of time.). Therefore, guaranteeing that the function call can only be successful after at least four months have passed since the last change.

The third and last modifier `costs(uint _amount)` in line 18 takes an amount of currency as an input and makes sure that the value provided with the calling transaction is at least as high as the specified amount, before jumping into the execution of the guarded function. This modifier differs from the other two, as it has code implemented after the function execution, which is triggered by the underscore in line 20. The additional if-clause starting in line 21, checks if more money than necessary was provided in the transaction and transfers the surplus amount back to the sender. This is a good example for the various possibilities modifiers can provide. Combined with the previous modifier the contract can only be bought by a new owner, after four weeks have passed since the last change in ownership, and if the transaction contains at least one ether. The `payable` modifier of the `buyContract()` function in line 30 is needed in order to be able to receive money with a transaction.

It should be noted that in this simple example, we could have omitted the modifiers and implement their code directly in the respective function bodies, without loosing any functionality and even reducing complexity. The benefit of outsourcing the functionality into modifiers becomes apparent, as soon as two or more functions share the same, or similar, requirements (like in the [State Machine pattern](./state_machine.md)), as the modifier allows for easy reusability.

## Consequences

Several consequences have to be taken into account when applying the Access Restriction pattern. One controversial point is the readability of code. On the one hand, modifiers can make the code easier to understand, because the restriction criterion is clearly recognizable in the function header, especially if the modifiers are given meaningful names like in the provided sample code. On the other hand, execution flow is jumping from one line in the code to a completely different one, which makes it harder to follow and audit the code, and therefore simplifies the introduction of misleading (malicious) code. Because of this reason, the new smart contract programming language [Vyper](https://viper.readthedocs.io/en/latest/) is giving up on modifiers.

The advantages of the pattern are drawn from the fact that it is easy to adapt to different situations and highly reusable, while still providing a secure way to limit the access to functionality and therefore increase smart contract security altogether.
 
## Known Uses
The most prominent example of this pattern is probably the [Ownable contract by OpenZeppelin](https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/ownership/Ownable.sol).

Another example is the [core contract of the CrytoKitties DApp](https://etherscan.io/address/0x06012c8cf97bead5deae237070f9587f8e7a266d\#code), where there is not only one owner, but three. Namely the CEO, CFO and COO, who have different security levels and therefore different functions they are allowed to access.   

[**< Back**](https://fravoll.github.io/solidity-patterns/)
