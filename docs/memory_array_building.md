# Memory Array Building

## Intent

Aggregate and retrieve data from contract storage in a gas efficient way.  

## Motivation

Interacting with the storage of a contract on the blockchain is among the most expensive operations of the EVM. Therefore, only necessary data should be stored and redundancy should be avoided if possible. This is in contrast to conventional software architecture, where storage is cheap and data is stored in a way that optimizes performance. While most of the times the only relevant cost of queries in those systems is time, in Ethereum even simple queries can cost a substantial amount of gas, which has a direct monetary value. One way to mitigate gas costs is declaring a variable public. This leads to the creation of a getter in the background allowing free access to the value of the variable. But what if we want to aggregate data from several sources? This would require a lot of reading from storage and would therefore be particularly costly.

By using this pattern we are making use of the `view` function modifier in Solidity, which allows us to aggregate and read data from contract storage without any associated costs. Everytime a lookup is requested, an array is rebuilt in memory, instead of saving it to storage. This would be inefficient in conventional systems. In Solidity the proposed solution is more efficient because functions declared with the `view` modifier are not allowed to write to storage and therefore do not modify the state of the blockchain (the [Solidity documentation](http://solidity.readthedocs.io/en/v0.4.21/index.html) gives an overview over what is considered modifying the state). All data necessary for the execution of these functions can be fetched from the local node. Since the blockchain state stays the same, there is no need to broadcast a transaction to the network. No transaction means no consumed gas, making the call of a view function free, as long as it is called externally and not from another contract. In that case, a transaction would be necessary and gas would be consumed. 

## Applicability

Use the Memory Array Building pattern when
* you want to retrieve aggregated data from storage.
* you want to avoid paying gas when retrieving data.
* your data has attributes that are subject to changes.

## Participants & Collaborations

Participants in this pattern are the implementing contract itself as well as an entity requesting the stored data. To achieve a completely free request, the request has to be made externally, meaning not from another contract inside the network, as this would lead to the need for a gas intensive transaction.

## Implementation

The implementation of this pattern can be divided into two parts. Part one covers the way the requested data is stored, whereas part two explains the actual aggregation and retrieval of the data:
1. To make data retrieval convenient it makes sense to chose a data structure that is easy to iterate over. In Solidity this is achieved by an array. In cases where aggregation is necessary, the data usually has more than one attribute. This characteristic can be implemented by a custom data type in the form of a struct. Combining these requirements, we end up with an array of structs, with the struct containing all attributes of an item. Another indispensable part is a mapping, which keeps track of the number of expected data entries for every possible aggregation instance. This mapping will come into play in part two.
2. The aggregation is then performed in a view function, so that no gas is consumed. A problem that makes the task a little more difficult is the fact that Solidity does not allow an array of structs as a return value of a function [yet](https://github.com/ethereum/solidity/issues/2948). We therefore propose a workaround that only returns the IDs of the desired items. It is then the task of the requesting entity to use these IDs to query the structs one by one. As the state is not changed by these additional operations, the queries are free as well. To gather the IDs of the desired items we first create an array to store them. Since we are not allowed to change the contract state in a view function we will create this array in memory. In Solidity it is not possible to create dynamic arrays in memory, so we can now make use of the mapping containing the number of expected entries from part one, and use it as the length for our array. The actual aggregation is done via a for-loop over all stored items. The IDs of all items that fit into the aggregation schema are saved into the memory array and returned after all items have been checked. Since all this computation is performed on the local node and not by every node on the network it is no problem to do such an otherwise expensive iteration over a dynamical array, since we can not run out of gas.

## Sample Code

In this sample we show how a collection of items can be aggregated over its owners.
```Solidity
// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.
contract MemoryArrayBuilding {

    struct Item {
        string name;
        string category;
        address owner;
        uint32 zipcode;
        uint32 price;
    }

    Item[] public items;

    mapping(address => uint) public ownerItemCount;

    function getItemIDsByOwner(address _owner) public view returns (uint[]) {
        uint[] memory result = new uint[](ownerItemCount[_owner]);
        uint counter = 0;
        
        for (uint i = 0; i < items.length; i++) {
            if (items[i].owner == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
}
```

In line 3 an example struct is defined containing several attributes, including the owner over which we will aggregate later on. The array in line 11 contains all existing instances of items. In line 13 we store the amount of items every address holds, which is necessary to initialize the memory array in line 16. The function to retrieve all IDs of items belonging to a certain address in line 15 contains the `view` modifier. In the for-loop starting in line 19 we iterate over all items and check if their owner corresponds to the one we are aggregating over (line 20). If the owners match, we store the ID in our array. After all items have been checked the array is returned. It is now possible for the requesting entity to query the items by their respective IDs without the need for a transaction, since the `items` array in line 11 is public.

## Gas Analysis

The analysis of gas consumption in this pattern is fairly easy. Again the Solidity online compiler Remix is used to compute the required gas. The code of the experiment can be found on [GitHub](https://github.com/fravoll/solidity-patterns/blob/master/MemoryArrayBuilding/MemoryArrayBuildingGasExample.sol). In our experiment we use the setting presented in the Sample Code section and initialize it with ten items of which two belong to the examined address. We then call the `getItemIDsByOwner(address _owner)` function twice from an external account as well as from another contract. One of the two times the function contains the `view` modifier and one time it does not. The results can be found in the following table and show how only a combination from an external call and the view function leads to a free query, while the other combinations cost gas like a regular function call would, because an actual transaction is broadcasted to the network.

|         | View Function           | Regular Function  |
| :------------ | -------------:| -----:|
| External Call      | 0 | 32623 |
| Internal Call      | 32623      |   32623 |

## Consequences
The most obvious consequence of applying the Memory Array Building pattern is the complete circumvention of transaction costs, a benefit that can save a substantial amount of money in case the function is used frequently. An alternative to the proposed way would be to store one array for every instance we would want to aggregate over (e.g. for every owner). This would lead to significant gas requirements as soon as we wanted to change the owner of one item. We would have to remove the item from one array, add it to another array, shift every element in the first array to fill the empty space as well as reducing the length of the array. All of this are expensive operations on contract storage. To change an attribute in the proposed solution, only the actual attribute and the mapping that keeps track of the length would have to be changed.

But the pattern does not only come with benefits. By implementing it, we increase complexity. It is unintuitive to store all items in one array compared to having separate arrays. Also the concept of doing aggregation on every single call instead of aggregating once and storing it that way might be confusing in the beginning.

## Known Uses
An inplementation of this pattern can be found in the infamous [CryptoKitties contract](https://etherscan.io/address/0x06012c8cf97bead5deae237070f9587f8e7a266d\#code). In line 651 we find a function called `\lstinline|tokensOfOwner(address _owner)` which returns the IDs of all Kitties that belong to a given address.

Another example is the now closed, Ethereum based slot machine [Slotthereum](https://etherscan.io/address/0xda8fe472e1beae12973fa48e9a1d9595f752fce0\#code). In this contract, the pattern was used in a similar fashion as in our example, to retrieve the IDs of all games. 

[**< Back**](https://fravoll.github.io/solidity-patterns/)
