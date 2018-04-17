# Tight Variable Packing

## Intent
Optimize gas consumption when storing or loading statically-sized variables. 

## Motivation

As with all patterns in this category the main goal of implementing them is the reduction of gas requirement. This pattern in special is easily applied and does not change any contract logic. All that has to be done is writing suitable state variables in the correct order. To reduce the amount of gas used for deploying a contract, and later on calling his functions, we make use of the way the EVM allocates storage. Storage in Ethereum is a key-value store with keys and values of 32 bytes each. When storage is allocated, all statically-sized variables (everything besides mappings and dynamically-sized arrays) are written down one after another, in the order of their declaration, starting at position 0. The most commonly used data types (e.g. `bytes32`, `uint`, `int`) take up exactly one 32 byte slot in storage. This pattern describes how to save gas by using smaller data types (e.g. `bytes16`, `uint32`) when possible, as the EVM can then pack them together in one single 32 byte slot and therefore use less storage. Gas is then saved because the EVM can combine multiple reads or writes into one single operation. The underlying behavior is also referred to as "tight packing" and is unfortunately, until the time of writing, not automatically achieved by the optimizer.

## Applicability

Use the Tight Variable Packing pattern when
* you want to reduce contract interaction costs.
* you are using more than one statically-sized state variable and can afford to use variables of smaller sizes.
* you are using a struct consisting of more than one variable and can afford to use variables of smaller sizes.
* you are using a statically-sized array and can afford to use a variable of a smaller size.

## Participants & Collaborations

In general, the only participant in this pattern is the contract implementing it. All other entities interacting with said contract will not be influenced in any way, as the changes only affect how data gets stored.

## Implementation

As hinted in the Applicability section, this pattern can be used for state variables, inside structs and for statically-sized arrays. The implementation of this pattern is quite straight forward and can be separated into two tasks:
1. Using the smallest possible data type that still guarantees the correct execution of the code. For example postal codes in Germany have at most 5 digits. Therefore, the data type `uint16`(`uint16` can hold numbers until 2^16-1 = 65535) would not suffice and we would use a variable of the type `uint24`(`uint24` can hold numbers until 2^24-1 = 16777215) allowing us to store every possible postal code.
2. Grouping all data types that are supposed to go together into one 32 byte slot, and declare them one after another in your code. It is important to group data types together as the EVM stores the variables one after another in the given order. This is only done for state variables and inside of structs. Arrays consist of only one data type, so there is no ordering necessary.

It is possible to store as many variables into one storage slot, as long as the combined storage requirement is equal to or less than the size of one storage slot, which is 32 bytes. For example, one `bool` variable takes up one byte. A `uint8` is one byte as well, `uint16` is two bytes, `uint32` four bytes, and so on. The storage requirement of the `bytes` data type is easy to remember, since for example `bytes4` takes exactly four bytes. So theoretically 32 `uint8` variables can be stored in the same space as one `uint256` can. This only works if the variables are declared one after another in the code, because if one bigger data type has to be stored in between, a new slot in storage is used.

## Sample Code

As an example we show how to use the pattern in the context of a struct.
```Solidity
// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.
contract StructPackingExample {
    
    struct CheapStruct {
        uint8 a;
        uint8 b;
        uint8 c;
        uint8 d;
        bytes1 e;
        bytes1 f;
        bytes1 g;
        bytes1 h;
    }
    
    CheapStruct example;
    
    function addCheapStruct() public {
        CheapStruct memory someStruct = CheapStruct(1,2,3,4,"a","b","c","d");
        example = someStruct;
    }
}
```

In line 3 we describe a struct object that makes use of the Tight Variable Packing pattern. The eight variables need one byte of storage each and are not interrupted by a bigger type, so they can be packed into one storage slot, where they use 8 of the available 32 bytes. That means we could add more variables into the same storage slot. In line 17 we first initialize a struct object in memory before we write it to storage in line 18.

## Gas Analysis
To quantify the potential reduction in required gas, a test has been conducted using the online solidity compiler Remix. The sample code presented above is compared to a solution that stores the exact same input data but does not use the smallest possible data types, and orders the variables in a way that prevents the EVM to use tight packing. So instead of writing all eight variables into one slot, eight slots are used. The code of the experiment can be found on [GitHub](https://github.com/fravoll/solidity-patterns/blob/master/TightVariablePacking/TightVariablePackingGasExample.sol). The results are shown in the following table:

|         | Tightly Packed Struct | Struct without Tight Packing |
| :------------- |-------------:| -----:|
| Contract Creation      | 133172 | 116560 |
| Saving Struct to Storage      | 57821      |   161636 |

It can be seen that the gas cost of contract creation is approximately 12% cheaper, when not using smaller data types. This can be explained because the EVM usually operates on 32 bytes at a time. It has to use additional operations in order to reduce the size of an element from its original to its reduced size, in our case from `bytes32` to `bytes1`, which costs extra gas. This cost pays off after saving one of our structs to storage. In our example we save 7 storage slots which amounts to saved gas of around 64%. This considerable amount of gas is not only saved once, but every time a new instance of this struct is stored.

## Consequences

Consequences of the use of the Tight Variable Packing pattern have to be evaluated before implementing it blindly. The big benefit comes from the substantial amount of gas that can potentially be saved over the lifetime of a contract. But it is also possible to achieve the opposite, higher gas requirements, when not implementing it correctly. The positive effect on gas requirements only works for statically-sized storage variables. Function parameters or dynamically-sized arrays do not benefit from it. On the contrary, as seen in the contract creation costs in the Gas Analysis section, it is even more costly for the EVM to reduce the size of a data type compared to leaving it in its initial state. Another issue may arise when reordering variables to optimize storage usage, which is decreased readability. Usually variables are declared in a logical order. Changing this order could make it harder to audit the code and confuse users as well as developers.

## Known Uses
Implementation of this pattern is difficult to observe because it is hard to differentiate if variable types and ordering is chosen with storage packing in mind or because of different reasons. Up until writing no contract could be observed that seemed to have implemented this pattern completely deliberate. One noteworthy example is [Roshambo](https://etherscan.io/address/0xad01fab133e6b9a3308a68931f768ec86e1ad281\#code), a   rock-paper-scissors game that stores each game in a struct. Moves as well as tiebreakers are stored in `uint8` variables, which allow for tight packing. But it looks like this design decision was made without tight packing in mind, as it could be further optimized.

Another example can be found in the [Etherization contract](https://etherscan.io/address/0x3f593a15eb60672687c32492b62ed3e10e149ec6\#code), a DApp that provides a civilization like game on the Ethereum blockchain. In this contract every player is stored in a struct. This time no smaller data types are used, even it would be possible without breaking the logic of the game. By doing this, the gas requirement of storing a new player could be reduced significantly. 

[**< Back**](https://fravoll.github.io/solidity-patterns/)
