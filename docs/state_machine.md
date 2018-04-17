# State Machine

## Intent

Enable a contract to go through different stages with different corresponding functionality exposed.

## Motivation

Consider a contract that has to transition from an initial state, over several intermediate states, to its final state over his lifetime. At each of the states the contract has to behave in a different way and provide different functionality to its users. The described behavior can be observed in a multitude of use cases: auctions, gambling, crowdfunding, and many more. Even the [Solidity documentation](http://solidity.readthedocs.io/en/v0.4.21/common-patterns.html#state-machine) acknowledges its conventionality by listing it as one of the common patterns. There are different ways one state can transition into another. Sometimes a state ends with the end of a function, another time the state is supposed to transition after a specified amount of time. The different possibilities will be described in greater detail in the Implementation section.

A pattern with the functionality described above has already been formulated by Gamma et al. (1995), but its implementation on a blockchain is especially interesting. This is because a blockchain itself is a state transition system where an initial state in combination with a transaction has a new state as an output. To avoid confusion between the states of a blockchain (i.e. the condition before and after a transaction) and the states, the contract is going through, we will call the explicitly defined states of contracts stages from here on.

## Applicability

Use the State Machine pattern when
* a smart contract has to transition several stages during its life cycle.
* functions of a smart contract should only be accessible during certain stages.
* stage transitions should be clearly defined and not preventable for all participants.

## Participants & Collaborations

There are two participants in the State Machine pattern. The first participant is the implementing contract that will transition through the predefined stages and guarantees that only the intended functions in the respective stage can be called. The other participant is the contract owner or interacting users, which are able to initiate a stage transition, either directly or indirectly through timed transitions.

## Implementation

The implementation of the State Machine pattern covers three main components: **representation of the stages**, **interaction control for the functions** and **stage transitions**.

To model the different stages in Solidity we can make use of enums. Enums are user-defined data types. After one enum containing all possible stages is declared, an instance of that enum can be used to store the current stage and transition to the next one by assigning it a new stage. Since enums are explicitly convertible to and from all integer types, a transition to the next stage can be accomplished by adding the integer 1 to the stage instance.

The restriction of function access to certain stages can be achieved by using the [Access Restriction pattern](./access_restriction.md). A function modifier checks if the contract stage is equal to the required stage before executing the called function. In case the function is called at an improper stage, the transaction is reverted using the [Guard Check pattern](./guard_check.md).

There are several ways to transition from one stage to the next one, in order to accommodate for different situations and needs. One way is the transition in a function call. Either the function exists exclusively for the stage transition, or it executes business logic and the stage transition is a natural part of the process. For example in a roulette contract, the house could call a function to pay out all winnings, which ends with a stage transition from `GameEnded` to `WinnersPaid`. In cases like this, the stage change is either implemented directly by assigning a new stage to the state variable, by using a modifier initiating the transition at the end of the function, or by a helper function. The helper function would be an internal function that increments the stage by 1, every time it is called. Another option that does not rely on direct function calls are automatic timed transitions. The duration a stage is supposed to last, or rather a point of time in the future at which the stage transition should be executed, is stored in the contract. A modifier that is called with every involved function call, checks for the current timestamp and transitions to the next stage, in case that point in time is already reached. It is important to mention that the order of the modifiers in Solidity matters. With this knowledge in mind, the modifier for the timed transition should be mentioned before the modifier that checks for the current stage, to make sure that the potential timed stage change is already considered in the stage check.

After the implementation is done, heavy testing is necessary to rule out any possibilities for unexpected stage changes by malicious entities that could try to benefit from unintended behavior or just break the contract.

## Sample Code

This sample contract showcases the state machine for a blind auction and is inspired by the example code provided in the [Solidity documentation](http://solidity.readthedocs.io/en/v0.4.21/common-patterns.html#state-machine). It features stage transitions in functions, as well as timed transitions. As this is an extensive use case, only the code relevant for the state machine is presented. Any logic dealing with the auction, including the storage of bids, is omitted.

```Solidity
// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.
contract StateMachine {
    
    enum Stages {
        AcceptingBlindBids,
        RevealBids,
        WinnerDetermined,
        Finished
    }

    Stages public stage = Stages.AcceptingBlindBids;

    uint public creationTime = now;

    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }
    
    modifier transitionAfter() {
        _;
        nextStage();
    }
    
    modifier timedTransitions() {
        if (stage == Stages.AcceptingBlindBids && now >= creationTime + 6 days) {
            nextStage();
        }
        if (stage == Stages.RevealBids && now >= creationTime + 10 days) {
            nextStage();
        }
        _;
    }

    function bid() public payable timedTransitions atStage(Stages.AcceptingBlindBids) {
        // Implement biding here
    }

    function reveal() public timedTransitions atStage(Stages.RevealBids) {
        // Implement reveal of bids here
    }

    function claimGoods() public timedTransitions atStage(Stages.WinnerDetermined) transitionAfter {
        // Implement handling of goods here
    }

    function cleanup() public atStage(Stages.Finished) {
        // Implement cleanup of auction here
    }
    
    function nextStage() internal {
        stage = Stages(uint(stage) + 1);
    }
}
```

In line 3 the enum `Stages`, which contains the four stages the auction will be going through, is defined. A state variable is initialized with the initial stage in line 10. The time of creation is stored in line 12 and will be important for the timed transitions. The function modifier defined in line 14 is checking the current stage versus the allowed stage of a function. The stage provided as a parameter is the stage that the contract has to be in, in order to be able to execute the function logic. If a function implements the modifier `transitionAfter()`, the internal method `nextStage()` is called at the end of the function and the contract transitions in the next stage. Timed transitions are handled by using the modifier specified in line 24. The individual if-clauses check if the contract should already be in the next stage by comparing the current time with the time the transition is supposed to happen (e.g. `creationTime + 6 days`), while also taking the current stage into account.

The four public methods starting from line 34 are only callable in their respective stages, which is achieved by the `atStage()` modifier provided with the concrete stage. Transitions for the first two stages are timely. Notice that the `timedTransitions` modifier is included in the first three functions and not only in the first two. This is because the actual transition is happening when calling the function of the next stage. For example: calling the `bid()` function 8 days after contract creation will first transition to the next stage, because the `timedTransitions` modifier triggers. Afterwards, however, the `atStage()` modifier will detect that the stage is not matching anymore and will revert the whole transaction, including the stage transition. In this case the `timedTransitions` modifier is making sure that `bid()` cannot be called after 6 days have passed. The persisting stage transition is happening the first time the function of the next stage is called, in this case `reveal()`. The process is the same as before only that this time the stage is recognized as correct and the transaction is not reverted. This complex behavior is why the order of the modifiers mentioned in the Implementation section is so important.

The transition from stage three to four is done with the `transitionAfter` modifier used in the function in line 42. After the execution of the function, the contract automatically goes into the next and final stage, which only allows the `cleanup()` method to be called.

## Consequences

One consequence of applying the State Machine Pattern is the partitioning of contract behavior into the distinct stages. It allows functions to be only called at the intended times. Additionally the pattern guides the contract through its different stages by providing several options for initiating stage transitions that can be used depending on the context.

Some consequences that should be kept in mind, emerge from the different options for stage transitioning. While timed transitions have the benefit of a clear policy for every participant, the usage of block numbers or timestamps is not entirely harmless. Miners have the potential ability to influence timestamps to a certain degree. It should therefore be avoided to use timed transitions for very time sensitive cases. To be completely safe, a contract should be robust against a timestamp deviating by up to 900 seconds from the actual time. But also the manual transition of stages by the contract owner is prone to manipulation, as the owner can simply decide to change stages in his favor or abandon the contract and freeze all invested funds.      

## Known Uses

Several contracts applying this pattern in some form or another could be observed. One example is the betting contract from [Ethorse](https://github.com/ethorse/ethorse-core/blob/master/contracts/Betting.sol), which allows bets on the price development of cryptocurrencies. In this example, the stages are stored in a struct in the form of booleans, with the current stage being set to `true`. Transitions are made in a timely fashion via timestamps. A different implementation that relies mostly on manual transitions is the auction contract of [Pocketinns](https://github.com/pocketinns/PocketinnsContracts/blob/master/DutchAuction.sol), a community driven marketplace ecosystem. In this contract the owner has the ability to change stages at his own will. Even though it is described as an emergency measure in the contract, it opens the door for severe manipulation and any transaction with such a contract should be done with care. 

[**< Back**](https://fravoll.github.io/solidity-patterns/)
