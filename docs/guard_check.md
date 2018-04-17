# Guard Check

## Intent

Ensure that the behavior of a smart contract and its input parameters are as expected.

## Motivation

Like in a regular legal contract, it is often the case in smart contracts, that contract logic is only supposed to come into effect after certain requirements are met. For example a heritage should only be paid out to the heirs after the testator is deceased. While we have lawyers and notaries in the real world, on the blockchain, without regulators or mediators, we require some sort of guards or checks in order to assure that smart contract logic is functioning as specified.

The desired behavior of a smart contract would be to check for all required circumstances and only proceed if everything is as intended. In case of any shortcomings, the contract is expected to revert all changes that have been made to its state. To achieve this, Solidity is making use of the way the EVM handles errors: to retain atomicity all changes are reverted and the whole transaction is without effect. Solidity is using exceptions to trigger these errors and revert the state. There are several ways provided by Solidity to trigger such exceptions. This pattern describes their differences and gives an idea on how and when to use each of them.

## Applicability
Use the Guard Check pattern when
* you want to validate user inputs.
* you want to check the contract state before executing logic.
* you want to check invariants in your code.
* you want to rule out conditions that should not be possible.

## Participants & Collaborations

While the pattern can be used to validate data submitted by users as well as data returned from other contracts, the only participant is the implementing contract itself, as all behavior is performed internally.

## Implementation
Prior to Solidity version 0.4.10 checks were commonly implemented with an if-clause that would throw an exception in case the requirement is not met: `if(testator != deceased) { throw; }`. Since version 0.4.13 however, the keyword `throw` is deprecated and the use of one of this three other functions is recommended: `revert()`, `require()` and `assert()`. How and when to use which of them to trigger exceptions will be discussed in this section.

Before the Byzantium update, `require()` and `assert()` behaved identically. Since then the underlying opcodes actually differ. The two methods `require()` and `revert()` use `0xfd` (`REVERT`) while `assert()` uses `0xfe` (`INVALID`). The big difference between the two opcodes is gas return. While `REVERT` is refunding all of the gas that has not been consumed at the time the exception is thrown, `INVALID` uses up all gas included in the transaction. This difference should be kept in mind and already gives an indication for which situations they are intended for.

The [Solidity documentation](http://solidity.readthedocs.io/en/v0.4.21/#) suggests that `require()` "should be used to ensure valid conditions, such as inputs, or contract state variables [..], or to validate return values from calls to external contracts" and `assert()` "should only be used to test for internal errors, and to check invariants". Both methods evaluate the parameters passed to it as a boolean and throw an exception if it evaluates to `false`. The `revert()` throws in every case. It is therefore useful in complex situations, like if-else trees, where the evaluation of the condition can not be conducted in one line of code and the use of 'require()' would not be fitting.

Generally 'require()' should be used towards the beginning of a function for validation and should be used more often than the other two.  The 'assert()' method will be used at the end of a function and should only prevent severe errors. Under normal circumstances and bug free code the 'assert()' statement should never evaluate to 'true'.

Since [Solidity version 0.4.22](https://solidity.readthedocs.io/en/v0.4.22/units-and-global-variables.html#error-handling) it is possible to append an error message to `require(bool condition, string message)` and `revert(string message)`.

## Sample Code
This fictional sample contract is a donation distributor. Users send the address of a charity they want to support and a donation int the form of ether. In case the charity has no ether on their address, the whole amount is forwarded. If they do already own some ether but less than the donor, half the amount of the donation is transferred while the other half stays at the contract for future distribution (this functionality is not implemented for the sake of brevity). In case the charity has more funds than the donor, no money should be donated. This sample contract showcases all three possibilities to implement the Check Guard pattern. 
```Solidity
// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.
contract GuardCheck {
    
    function donate(address addr) payable public {
        require(addr != address(0));
        require(msg.value != 0);
        uint balanceBeforeTransfer = this.balance;
        uint transferAmount;
        
        if (addr.balance == 0) {
            transferAmount = msg.value;
        } else if (addr.balance < msg.sender.balance) {
            transferAmount = msg.value / 2;
        } else {
            revert();
        }
        
        addr.transfer(transferAmount);
        assert(this.balance == balanceBeforeTransfer - transferAmount);      
    }
}
```

In line 4 the `require` statement makes sure that the address provided by the user is not zero as would be the case if the user would have forgotten to specify a charity. Line 5 then checks if the user attached a donation to his transaction. If this is not the case we can stop right there. The if/else construct starting in line 9 determines the amount to be sent to the charity, depending on the charities current balance. In case the charity has more ether than the donor, the `revert` in line 14 makes sure that no money is transferred and the function is reverted. In line 17 the donation is sent to the charity. The final `assert` statement in line 18 assures that the current balance after the donation is equal to the balance before the donation minus the donated amount. Under regular circumstances this should always evaluate to `true`. If this assertion would not hold true the whole transaction, including the donation transfer to the charity would be reverted.

## Consequences

One positive consequence of applying the Guard Check pattern is increased readability. Compared to an if/throw construct the use of a `require` function makes it easier for the reader, who might not be a software engineer, to understand the intention of the operation. Additionally the new expressions look cleaner in general. Another benefit of having several options is that the individual methods allow for future functionality to be implemented, tailored to their purpose. As mentioned, the `revert()` and `require()` methods were equipped with an error message, while `assert()` could be used for evaluation purposes with techniques like static analysis and formal verification, to identify conditions that break contract logic. The availability of three different usable functions allows for a targeted application in various situations and therefore provides flexibility to the developer. 

The wide range of possible methods can be confusing for users without any experience with this pattern, because the names suggest similar behavior but do not offer any explanation on where they differ. Using the wrong statement can lead to undesired behavior, for example users loosing all their provided gas in case they make a typo in the function arguments.

Overall the Guard Check provides a reliable way to handle errors and guard against undesired behavior. It is therefore an essential ingredient in the [Access Restriction pattern](https://fravoll.github.io/solidity-patterns/access_restriction.html). 

## Known Uses

The application of this pattern can be observed in nearly every published contract. A nice example is the contract of [HODLit](https://etherscan.io/address/0x24021d38DB53A938446eCB0a31B1267764d9d63D), a token with the intention to give an incentive to hold ether, because it features all three methods. The `require` expression is used for checks at the beginning of methods and `assert` is used to make sure that arithmetic operations can not over- or underflow. The `revert` method is called in the fallback function in line 269 to avoid the possibility to send ether to the contract without calling one of the functions specified for that purpose.

A negative example can be observed in this simple [casino contract](https://github.com/merlox/casino-ethereum/blob/master/contracts/Casino.sol). The developer used `assert` for every check in the whole contract. This would lead to the loss of all provided gas if one of the checks fails. In case a user wants to make sure his transaction does not run out of gas and therefore provides a very high gas limit, this could result in the loss of a significant amount of money.

[**< Back**](https://fravoll.github.io/solidity-patterns/)
