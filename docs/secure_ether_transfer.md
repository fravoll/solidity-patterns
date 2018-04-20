# Secure Ether Transfer

## Intent

Secure transfer of ether from a contract to another address.

## Motivation

Even though the transfer of currency is not the main application of Ethereum, as it is for Bitcoin, it is still a necessary and heavily used feature. While the ether transfer from an external account can simply be done via a network transaction, the transfer of ether from a contract account is not as straight forward.

In the early days of Solidity, the intended way to transfer currency from one contract to another address, whether it is an external account or a contract itself, has been the `<address>.send(amount)` function. It sends the specified amount to the address, the function is called on. However, the `send` method does not propagate errors and only sends a small stipend of gas with it. People resorted to workarounds like the `<address>.call.value(amount)()` function, to overcome this limitation, as the amount of gas can be specified, using this approach, by appending `.gas(amountOfGas)` to the `call.value` method. Soon, people discovered that this method opens the door for a new attack vector, not known until then, the re-entrancy attack, which led to a substantial amount of ether being stolen. To give this workaround a name and also include the propagation of exceptions, a new function for the address type was introduced with [Solidity version 0.4.13](https://github.com/ethereum/solidity/issues/610): `transfer(amount)`. In the end, the intended option to specify the amount of forwarded gas was not implemented for the `transfer` method, making it more similar to the `send` function than to the `call.value` function, contrary to what it was supposed to be.

After all, the user is left with three different options to transfer ether from a contract address, each with different attributes and application areas. The aim of this pattern is to delimit the different options from each other and give recommendations on when to use which method, according to the given requirements.

## Applicability

Use the Secure Ether Transfer pattern when
* you want to transfer ether from a contract address to another address in a secure way.
* you are not sure which method of ether transfer is the most suitable for your needs.
* you want to guard your contract against re-entrancy attacks.

## Participants & Collaborations

The participating entities for this pattern are the contract sending the ether, as well as the address receiving it. The receiving end can either be another contract or an external account. The pattern is implemented at the sending contract. The receiving address, however, also plays a crucial role, especially if it is another contract, because there is the possibility to reenter the sending contract with malicious intent, in case enough gas is forwarded.  

## Implementation

To make a decision on which method to use in a specific scenario, it is important to first understand the differences in the behavior of the three methods. There are two dimensions to consider when evaluating the characteristics: the **amount of forwarded gas** and **exception propagation**. Both `send` and `transfer` forward a stipend of 2300 gas, which is just enough to log an event at the receiving contract. In case the receiver requires a larger amount of gas to handle the reception of ether, `call.value` has to be used, as it forwards all remaining gas, unless specified otherwise with the help of the `.gas()` parameter. Regarding the propagation of exceptions, `send` and `call.value` are similar to each other, as both of them do not bubble up exceptions but rather return `false` in case of an error. The `transfer()` method, however, propagates every exception that is thrown at the receiving address to the sending contract, leading to an automatic revert of all state changes. Exception propagation for the first two methods can be achieved with a workaround using the [Guard Check pattern](./guard_check.md). For example: `require(<address>.send(amount))` is equal to `<address>.transfer(amount)`. An overview over the differences of the three methods is given in the following table:

| Function       | Amount of Gas Forwarded | Exception Propagation  |
| :------------- |-------------:| -----:|
| send      | 2300 (not adjustable) | `false`on failure |
| call.value      | all remaining gas (adjustable)      |   `false`on failure |
| transfer | 2300 (not adjustable)      |    throws on failure |

There are also similarities between the three functions: All three of them are special functions of the `address` data type, meaning that they have to be appended to an address, where the address is the recipient and the executing contract is the sender. Another similarity is that the amount to be transferred is specified in wei (1  wei = 10^-18 ether}, which has to be taken into account in order to avoid accounting errors. Lastly it should be pointed out that all three methods are translated into the `CALL` opcode by the Solidity compiler, showing that they share the same internal process.

## Sample Code

The following fictitious sample showcases two contracts: the first contract receives ether, while the second one uses the three presented methods to send ether to the first one and shows different ways to handle exception propagation at the same time.

```Solidity
// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.
contract EtherReceiver {

    function () public payable {}
}

contract EtherSender {

    EtherReceiver private receiverAdr = new EtherReceiver();

    function sendEther(uint _amount) public payable {
        if (!address(receiverAdr).send(_amount)) {
            //handle failed send
        }
    }

    function callValueEther(uint _amount) public payable {
        require(address(receiverAdr).call.value(_amount).gas(35000)());
    }

    function transferEther(uint _amount) public payable {
        address(receiverAdr).transfer(_amount);
    }
}
```

The only job of the first contract `EtherReceiver` is to receive ether. Therefore, the fallback function carries the `payable` modifier. This fallback function would be the place to implement malicious code in order to carry out a re-entrancy attack. As this attack would require more than the stipend of 2300 gas, only fallback functions triggered by the `call.value` method are able to carry out the attack. The second contract `EtherSender`, starting from line 6, has access to an instance of the `EtherReceiver` in the form of `receiverAdr` (line 8). The instance is used as the target address for the ether transfer.

Each of the three following functions uses one of the three different methods to transfer ether from a contract and carries the `payable` modifier, in order to provide for the ether to be sent in the process. Additionally, each of them takes an amount in wei to be transferred to the receiver as an input parameter. The amount provided with the transaction should be at least the amount to be transferred to the receiving contract. The `sendEther` function from line 10 uses the `send` function of the address type. As  exceptions for possible errors (e.g. the balance of the contract is lower than the amount to be transferred) are not propagated, we are able to handle the return value, for example in an if-clause.

The second function `callValueEther` from line 16, is encapsulated in a `require` statement to show how exception propagation can be implemented, even for methods not supporting it innately. In this example we specified that the arbitrary amount of 35000 gas should be forwarded to the fallback function of the receiving contract by appending `.gas(35000)` to the method. This can be useful in case the fallback function has some advanced logic implemented.

The `transferEther` function in line 20 has a straight forward implementation and does not need any further statements, as exceptions are automatically propagated.

## Consequences

While both methods, `transfer` and `send`, are considered safe against re-entrancy, because they only forward 2300 gas, `transfer` should be the go-to method to transfer ether in most cases. This is because it reverts automatically in case of any errors. The `send` method can be seen as the low level counterpart of `transfer`. It should be used in cases where it is important that the error is handled in the contract without reverting all state changes. The low level `call.value` method should only be used as a last resort, as it breaks the type-safety of Solidity. One of its application fields is sending ether to fallback functions that require more than the stipend of gas. With its adjustable parameters it can provide great flexibility for honest and experienced users, but also for malicious ones.

On one hand the differentiation into three methods used for the same task provides for flexibility, because the simple `transfer` function can be used for most use cases while the more complicated `call.value` can be adjusted and and used for specialized tasks. On the other hand the differentiation can be confusing for developers and users alike, as there are no real semantic clues between the naming of the different options, as to where their differences could be.

Another consequence that should be kept in mind are the effects that a limitation on the amount of forwarded gas can have on the surrounding logic. If, for example a state machine (see [State Machine pattern](./state_machine.md) relies on the successful transfer of ether to a specific contract in order to proceed to the next stage, it should be made sure that the recipients are able to receive the ether. Fallback functions requiring more gas then the stipend could otherwise freeze a contract, which is using the `transfer` method. This concept affected the King of the [Ether Throne contract](http://www.kingoftheether.com/postmortem.html), which would have been put into an unresolvable state if it had used `transfer` instead of `send`. To overcome this limitation the [Pull Over Push pattern](./pull_over_push.md) can be used, which lets the users request payments instead of proactively sending it, in order to avoid unexpected behavior.
 
## Known Uses

An example of the different possible implementations of this pattern can be seen in this [MultiSend contract](https://github.com/Alonski/MultiSendEthereum/blob/master/contracts/MultiSend.sol) that lets you send ether to multiple addresses with only one initial transaction. The contract then issues several internal transactions to the recipients on his own and uses either the `transfer` or the `call.value` method, depending on the users call.
Another case is the [Crypto Sprites contract](https://etherscan.io/address/0xf3C8Ed6C721774C022c530E813a369dFe78a6E85\#code), a third party game built off Crypto Kitties. This time only the `transfer` method is used throughout the whole contract, as it is safe and easy to use, and no special functionality was required.       
 
[**< Back**](https://fravoll.github.io/solidity-patterns/)
