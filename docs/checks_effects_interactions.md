# Checks Effects Interactions

## Intent

Reduce the attack surface for malicious contracts trying to hijack control flow after an external call.

## Motivation

The Ethereum Virtual Machine does not allow for concurrency. When calling an external address, for example when transferring ether to another account, the calling contract is also transferring the control flow to the external entity. This external entity is now in charge of the control flow and can execute any inherent code, in case it is another contract. Most of the times, this will not cause any problems, but in case the called contract is acting in bad faith, it could alter the control flow and return it in an unexpected state to the initial contract. A possible attack vector is a re-entrancy attack, in which the malicious contract is reentering the initial contract, before the first instance of the function containing the call is finished. This attack can be used to repeatedly invoke functions that should only be executed once and was part of the most prominent hack in Ethereum history: the [DAO exploit](http://hackingdistributed.com/2016/06/18/analysis-of-the-dao-exploit/). The described vulnerability is not present in other software environments, making it hard to avoid for developers not familiar with the quirks of smart contract development. The pattern presented in this section, together with the [Secure Ether Transfer pattern](./secure_ether_transfer.md), aims to provide a safe solution, in order to make functions unassailable against re-entrancy attacks of any form.

## Applicability

Use the Checks Effects Interactions pattern when
* it cannot be avoided to hand over control flow to an external entity.
* you want to guard your functions against re-entrancy attacks.

## Participants & Collaborations

Participating entities in this pattern are the called function, as well as the calling party, which will gain the control flow, for example in the case a value transfer is happening. While the pattern is solely implemented in the called function, the other party is a essential participant, as it has the potential to manipulate the control flow.  

## Implementation

To implement the Check Effects Interactions pattern, we have to be aware about which parts of our function are the susceptible ones. Once we identify that the external call with its insecurities regarding the control flow is the potential cause of vulnerability, we can act accordingly. As stated in the Motivation section of this pattern, a re-entrancy attack can lead to a function being called again, before its fist invocation has been finished. We should therefore not make any changes to state variables, after interacting with external entities, as we cannot rely on the execution of any code coming after the interaction. This leaves us with the only option to update all state variables prior to the external interaction. This method can be described as ["optimistic accounting"](https://ethereum.stackexchange.com/a/12233), because effects are written down as completed, before they actually took place. For example, the balance of a user will be reduced before the money is actually transferred to him. This is not a problem as will be seen in the [Secure Ether Transfer pattern](./secure_ether_transfer.md), because in case something goes wrong with the money transfer, the whole transaction can be reverted, including the reduction of the balance in the state variable. Combined with the [Guard Check pattern](./guard_check.md), which states that checks should be implemented towards the beginning of a function, we get the natural ordering of: checks first, after that effects to state variables and interactions last.
 
This method of ordering function components was first described and named in the [Solidity documentation](http://solidity.readthedocs.io/en/v0.4.21/security-considerations.html#use-the-checks-effects-interactions-pattern). The checks in the beginning assure that the calling entity is in the position to call this particular function (e.g. has enough funds). Afterwards all specified effects are applied and the state variables are updated. Only after the internal state is fully up to date, external interactions should be carried out. In case this order is followed, a re-entrancy attack should not be able to surpass the checks in the beginning of the function, as the state variables used to check for entrance permission have already been updated.

## Sample Code
The following sample code implements a simple banking contract, where users can deposit and withdraw Ether.
```Solidity
// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.
contract ChecksEffectsInteractions {

    mapping(address => uint) balances;

    function deposit() public payable {
        balances[msg.sender] = msg.value;
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount);

        balances[msg.sender] -= amount;

        msg.sender.transfer(amount);
    }
}
```

User balances are stored in a mapping in line 3. The `deposit()` function in line 5 lets the user deposit ether in the contract and stores the respective balances. The actual pattern is implemented in the `withdraw()` function in line 9, which is provided with the amount requested to withdraw. The first step is conducting all necessary **checks**. As this is a small example, there is only one condition to check: if the balance of the user is sufficient for the requested amount, which is done with the help of a `require` statement in line 10. The next step is the application of all **effects**, of which we again have only one: the adjustment of the users balance in line 12. All external **interactions** take place in the last step. We are using the `transfer()` method to further guard the function against re-entrancy, as explained in more detail in the [Secure Ether Transfer pattern](./secure_ether_transfer.md).

In an unsafe implementation of this contract, one disregarding the Checks Effects Interactions pattern, where the order of the effect and interaction in line 12 and 14 are exchanged and not `transfer()` but the unsafe and low level `call.value()` is used, a malicious contract could reenter our function. Because the control flow would pass over to the malicious contract, it would be able to call the `withdraw()` function again, before the first invocation is finished, without being intercepted by our check. This is because the line of code carrying the effect of adjusting the balance would not have been reached yet. Therefore, a second transfer of ether to the attacker would be issued. This circle would keep on draining the contract of ether, until either the transaction runs out of gas or the contracts funds are not sufficient anymore.

## Consequences

The only negative consequence of using the Checks Effects Interactions pattern is, that it is counterintuitive to use, when coming from a different programming paradigm. In other programming languages it is common procedure to apply effects after the interactions already happened. This is because it is good practice to wait for a return, stating that the function execution was successful, before making any further changes relying on the results.

Once this mental hurdle is overcome, the Checks Effects Interactions pattern is a great way to limit the attack surface of a contract, particularly against re-entrancy attacks, because multiple encapsulated function invocations are not possible anymore. Most of the times it is easy to apply the pattern by only taking the functional code order into account, without having to change any logic. It is a good habit to use this pattern in any function making external calls, regardless of whether the other party is trustworthy or not, because even trusted external parties could transfer control to a third party, which could turn out to be malicious.
 
## Known Uses
A short section in the Solidity documentation, as well as the well-known DAO exploit, which showcased the devastating consequences of disregarding its principles, have helped spreading the word about the Checks Effects Interactions pattern. At the time of writing, implementations of it can be observed in a variety of smart contracts. One example is a contract of the [CryptoCountries](https://etherscan.io/address/0x17df117bb806a622d841bd5166a23b5d8746232f\#code) DApp, an interactive game where users can buy and own countries. The `buy(..)` function in line 177 clearly shows the ordering of components: In the beginning several checks are carried out, to assure that the necessary conditions hold true. Only after that the new owner of a country is written to the contract state. At the end of the function the purchase price is transferred to the previous owner.

The same usage of the pattern was applied in the [Own the Day contract](https://etherscan.io/address/0x16d790ad4e33725d44741251f100e635c323beb9\#code), an idea similar to the CryptoCountries, only that instead of countries you are trading calendar days this time. The `claimDay(..)` function from line 399 implements the pattern in the same fashion as explained above.
 
[**< Back**](https://fravoll.github.io/solidity-patterns/)
