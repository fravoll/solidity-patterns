# Pull over Push

## Intent

Shift the risk associated with transferring ether to the user. 

## Motivation
Sending ether to another address in Ethereum involves a call to the receiving entity. There are several reasons why this external call could fail. If the receiving address is a contract, it could have a fallback function implemented that simply throws an exception, once it gets called. Another reason for failure is running out of gas. This can happen in cases where a lot of external calls have to be made within one single function call, for example when sending the profits of a bet to multiple winners. Because of these reasons developers should follow a simple principle: never trust external calls to execute without throwing an error. Most of the times this is not an issue, because it could be argued that it is the responsibility of the receiver to make sure that he is able to receive his money, and in case he does not, it is only to his disadvantage. The following example code of an auction contract inspired by [this example](https://consensys.github.io/smart-contract-best-practices/known_attacks/#dos-with-unexpected-revert), illustrates how even a single receiver could potentially freeze a whole contract.

```Solidity
// THis code contains deliberate errors. Do not use.
contract BadAuction {

    address highestBidder;
    uint highestBid;

    function bid() public payable {
        require(msg.value >= highestBid);

        if (highestBidder != 0) {
            highestBidder.transfer(highestBid);
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }
}
```

Once an address, which is not able to receive ether via the `transfer` method (for example because the fallback function requires more than the forwarded gas; see the [Secure Ether Transfer pattern](./secure_ether_transfer.md) for more detailed information) takes the position of the highest bidder, the contract will be in an unsolvable state. Every new attempt to overbid the current highest bidder will trigger the ether transfer in line 10, which will result in an exception and therefore, make it impossible to overbid the current leader.

Another potential problem arises when trying to send ether to multiple recipients with one function call. It only needs one of the transfers to fail in order to revert all transfers that already happened and stop the following transfers from executing.

To overcome these limitations a [technique](https://blog.zeppelin.solutions/onward-with-ethereum-smart-contract-security-97a827e47702) has been proposed that isolates each external call and shifts the risk of failure from the contract to the user. Due to the isolation of the transfers, no other transfers or contract logic have to rely on its successful execution.

## Applicability

Use the Pull over Push pattern when
* you want to handle multiple ether transfers with one function call.
* you want to avoid taking the risk associated with ether transfers.
* there is an incentive for your users to handle ether withdrawal on their own.

## Participants & Collaborations

The Pull over Push pattern consists of three participants. First, the entity responsible for the initiation of the transfer (e.g. the owner of a contract, or the contract itself) starts the process. Secondly, the smart contract has the responsibility of keeping track of all balances. The third participant is the receiver, who will not simply receive his funds via a transaction, but has to actively request a withdrawal, in order to isolate the process from other payout and contract logic.

## Implementation

In order to isolate all external calls from each other and the contract logic, the Pull over Push pattern shifts the risk associated with the ether transfer to the user, by letting him withdraw (**pull**) a certain amount, which would otherwise have to be sent to him (**push**). A core component of this implementation is a mapping, which keeps track of the outstanding balances of the users. Instead of performing an actual ether transfer from the contract to a recipient, a function is called, which adds an entry to the mapping, stating that the user is eligible to withdraw the specified amount. In case the mapping already contains an entry for this address, the amount is added to the existing one. The user is now responsible to withdraw the funds by issuing a transaction to a withdrawal method of the smart contract that uses the [Checks Effects Interactions pattern](./checks_effects_interactions.md) to update the outstanding balance before actually transferring the ether.

Implemented this way, a thrown exception in one of the transfers would only effect this specific transfer and not a whole series of transfers or even the whole contract, like in the example from above.

## Sample Code
An exemplary implementation of the Pull over Push pattern can be seen in the following code, which contains only the necessary components.  

```Solidity
// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.
contract PullOverPush {

    mapping(address => uint) credits;

    function allowForPull(address receiver, uint amount) private {
        credits[receiver] += amount;
    }

    function withdrawCredits() public {
        uint amount = credits[msg.sender];

        require(amount != 0);
        require(address(this).balance >= amount);

        credits[msg.sender] = 0;

        msg.sender.transfer(amount);
    }
}
```

The `credits` mapping in line 3 is one of the key elements of this pattern and stores the amount of ether (in wei) that each address is allowed to withdraw. The permission for withdrawal happens in the `allowForPull(..)` function in line 5. This function should be used instead of every ether transfer that is supposed to be settled with a pull instead of a push payment. So instead of `<address>.transfer(amount)`, we would now use `allowForPull(<address>, amount)`. The function carries the `private` modifier and can therefore only be called from within the contract. In case the pull permissions should be given directly from the outside via a transaction, the function can be made `public`. The [Access Restriction pattern](./access_restriction.md) should be used in that case, to make sure that only authorized addresses can issue withdrawal credits.

To request a withdrawal the eligible users have to call the `withdrawCredits()` function from line 9. Line 10 stores the amount the caller is allowed to withdraw in memory. Afterwards, line 12 makes sure that the requesting user has been credited an amount to withdraw higher than zero (Since an unsigned integer can not be negative, it is sufficient to check that the amount is not equal zero.). Line 13 requires the contract balance to be high enough to cover the requested amount. An exception would be thrown at the actual transfer later on anyways, if this condition was violated, so this check is not absolutely necessary. However, it is good practice to fail as early as possible. Line 15 sets the allowed withdraw amount in the mapping to zero, before actually transferring it, in order to be conform with the Checks Effects Interactions pattern and avoid re-entrancy. At last, the amount is transferred to the recipient in line 17 via a push. 

## Consequences

The use of the Pull over Push pattern is a good way to mitigate some of the quirks that come with Solidity when sending ether, especially when performing multiple transfers at once. Due to the isolation of the error prone transfer functionality, one failed transfer does not lead to a revert of all successful operations anymore. Additionally, it is now the responsibility of the requesting user to make sure that he is able to receive ether.

However, the negative consequences, coming with the additional steps required, should not be ignored. Interacting with a contract that uses pull instead of push payments requires the users to send one additional transaction, namely the one requesting the withdrawal. This does not only lead to higher gas requirements and therefore higher transaction costs, but also harms the user experience as a whole. Users should not have to interact more with a smart contract than absolutely necessary, as users, especially inexperienced ones, tend to make mistakes. In [one case](https://medium.com/@makoto_inoue/a-smartcontract-best-practice-push-pull-or-give-b2e8428e032a), a smart contract owner reported that more than 10% of the users did not withdraw their funds from the contract in the seven days they were given, before he could have collected the remaining contract balance for himself. This implies that this pattern should only be used if there is a strong incentive for all participants to withdraw their funds. Otherwise, users might consider a competitor or not using the contract at all, if withdrawing is to complicated or simply not worthwhile.

Using this pattern can be considered a trade-off between security and convenience for the users. Before implementing it, one should evaluate if the cutback in user experience is manageable, or if a clever use of the [Secure Ether Transfer pattern](./secure_ether_transfer.md) might be sufficient to rule out any vulnerabilities.

## Known Uses
One popular example of using the Pull over Push pattern is the [PullPayment contract](https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/payment/PullPayment.sol) by OpenZeppelin. The contract implements the pattern in a general way and contracts wanting to use its functionality can inherit from it.

A more specialized implementation can be found in a contract called [BlockParty](https://github.com/makoto/blockparty/blob/master/contracts/Conference.sol), a contract to manage attendance deposits for free events. Users are only getting their deposit back if they showed up at the event they registered for. Attendants are able to request a withdrawal after the contract owner, in most cases the organizer of the event, has confirmed their attendance via a transaction containing their Ethereum address.      
 
[**< Back**](https://fravoll.github.io/solidity-patterns/)
