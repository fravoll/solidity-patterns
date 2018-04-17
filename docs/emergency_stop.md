# Emergency Stop

## Intent

Add an option to disable critical contract functionality in case of an emergency.

## Motivation

Even heavily audited and tested code may contain bugs or defective code segments. Smart contracts are no exception to this. Oftentimes these bugs do not get discovered until they are used for an attack by an adversary. Once a critical flaw is discovered, it is hard to fix, because immutability is one of the core principles of the blockchain. While several patterns allow for upgradeable code to a certain degree (like the [Proxy pattern](./proxy.md)), these solutions usually take a substantial amount of time to implement and come into play. During this window of time, the attackers could continue with their hack, possibly draining all available funds from the contract before the fix is broadcast to the network.

With the help of this pattern, we provide the possibility to pause a contract by blocking calls of critical functions, preventing attackers from continuing their work. Of course, this pattern can be used to prevent the exploit of any kind of bug, regardless if it was discovered by an attacker or a benign entity, until the smart contract is fixed, or other countermeasures have been taken.  

## Applicability

Use the Emergency Stop pattern when
* you want to have the ability to pause your contract.
* you want to guard critical functionality against the abuse of undiscovered bugs.
* you want to prepare your contract for potential failures.

## Participants & Collaborations

There are three major participants in this pattern: The central component is a state variable that indicates, if the contract is currently stopped or not. This variable is referenced in the individual functions that are either not accessible, or only accessible, while the contract is stopped. The third participant consists of the group of entities that have the clearance to issue the emergency stop. This could for example be the contract owner, or a certain majority of users. 

## Implementation

If the contract is currently stopped or not is stored in a state variable in the form of a Boolean, which is initialized as `false` during contract creation. To stop the contract in case of an emergency, this state variable has to be set to `true`. The proposed way to do this is via a function call. To avoid the exploitation of the stopping functionality by random persons, only authorized entities (e.g. the contract owner) should be able to invoke this function. The [Access Restriction pattern](./access_restriction.md) can be used for this task. Another option to prevent misuse, while keeping up the notion of decentralization at the same time, would be to implement a rule set, which has to be fulfilled in order to trigger the stopping mechanism. A variety of possible rules could be applied, depending on the respective use case (e.g. 10% of the contracts balance have been withdrawn in the last hour).

Once the state variable can be activated by setting it to `true`, we can again use the [Access Restriction pattern](./access_restriction.md) to make sure that the functions identified as critical can not be called anymore, as soon as the contract is stopped. This is achieved with the help of a function modifier that throws an exception, in case the state variable indicates that emergency stop has been triggered. Functions that should be available during the stop, because they can help resolve the situation, like letting users withdraw their deposits, can be made available in the same way. 

Another design decision that is dependent on the use case of the contract is, if the emergency stop should be revertible or not. In case the contract is supposed to be resumable, for example because precautions for upgradability have been taken, the resumption of the contract is initiated by setting the state variable that indicates the stopping status of the contract, back to `false`. The function for this task can be implemented in the same way as the function to initiate the emergency stop and should also be guarded against unauthorized calls.

## Sample Code

The concrete implementation of this pattern is highly dependent on the context of the underlying smart contract. Important issues, like the recovery after an emergency stop, or which functions to make available and which not, should be assessed and carefully tested before deploying the contract.

The following code shows the basic framework of the Emergency Stop pattern and provides two exemplary methods that are influenced by a stop. For the sake of clarity, any further contract logic is omitted.  

```Solidity
// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.
contract EmergencyStop {

    bool isStopped = false;

    modifier stoppedInEmergency {
        require(!isStopped);
        _;
    }

    modifier onlyWhenStopped {
        require(isStopped);
        _;
    }

    modifier onlyAuthorized {
        // Check for authorization of msg.sender here
        _;
    }

    function stopContract() public onlyAuthorized {
        isStopped = true;
    }

    function resumeContract() public onlyAuthorized {
        isStopped = false;
    }

    function deposit() public payable stoppedInEmergency {
        // Deposit logic happening here
    }

    function emergencyWithdraw() public onlyWhenStopped {
        // Emergency withdraw happening here
    }
}
```

The Boolean `isStopped` in line 3 is the state variable carrying the information, if the contract is currently stopped or not. This variable is checked by the two modifiers `stoppedInEmergency` (line 5) and `onlyWhenStopped` (line 10) in order to restrict access to the functions utilizing them. The third modifier `onlyAuthorized` in line 15 checks if the caller of a method has authorization to do so. This could for example be restricted to the owner, by adding `require(msg.sender == owner)`, or a voting mechanism. The two functions in line 20 and 24 use this modifier and allow an authorized caller to stop and resume the contract, by setting the state variable `isStopped` to either `true` or `false` respectively.

The `deposit()` function from line 28 is an example for a critical method that should be inaccessible, once the contract is stopped. This restriction is achieved by appending the `stoppedInEmergency` modifier to the function header. An exception would be thrown, if the function would be called during a stop. The `emergencyWithdraw()` function in line 32 works the other way around. It is only accessible during the emergency stop, due to the `onlyWhenStopped` modifier. An emergency function like this should be implemented to give contract users an option to access their funds during a shutdown. Otherwise, users would have to trust the contract owner not to arbitrarily freeze their funds without the possibility to get them back.

## Consequences
Applying the Emergency Stop pattern to a contract adds a fast and reliable method to halt any sensitive contract functionality, as soon as a bug or another security issue is discovered. This leaves enough time to weigh all options and possibly upgrade the contract in order to fix the security breach.

The negative consequence of having an emergency stop mechanism from a users point of view is, that it adds unpredictable contract behavior. Unless a cogent rule set has to be fulfilled before triggering the stopping mechanism is possible, there is always the possibility that the stop is abused in a malicious way by the authorized entity. Therefore, the emergency stop implemented by this pattern, should only be triggered as a last resort, and not be seen as a pausing mechanism for predictable events. The [State Machine pattern](./state_machine.md) with timed transitions can be used for such cases, in order to keep contract behavior predictable for users, and minimize the trust that has to be put into the system.    
 
## Known Uses

The most prevalent application of the Emergency Stop pattern is the [Pausable contract](https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/lifecycle/Pausable.sol) from the OpenZeppelin library. This straightforward contract is implementing the pattern and every contract wanting to use it can inherit from it. Several applications could be observed making use of this technique: one example is [OmiseGO](https://etherscan.io/address/0xd26114cd6EE289AccF82350c8d8487fedB8A0C07\#code), a token with the aim to enable financial inclusion and interoperability through a decentralized network. The contract utilizes an older version of the Pausable contract starting from line 274.

Another, though less common, possibility is implementing the pattern on your own. One example for this approach is the [contract of the Million Ether Homepage](https://etherscan.io/address/0x15dbdB25f870f21eaf9105e68e249E0426DaE916\#code). In this case the Emergency Stop pattern is implemented inside the main contract and gives the owner of the contract to ability to stop execution of several functions at any given time.        
     
[**< Back**](https://fravoll.github.io/solidity-patterns/)
