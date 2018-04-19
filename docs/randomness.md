# Randomness

## Intent
Generate a random number of a predefined interval in the deterministic environment of a blockchain.

## Motivation
Randomness in computer systems and especially in Ethereum is notoriously difficult to achieve. While it is hard or even impossible to generate a truly random number via software, the need for randomness in Ethereum is high. This stems from the fact that a high percentage of smart contracts on the Ethereum blockchain can be classified as games, which often rely on some kind of randomness to determine a winner. The problem with randomness in Ethereum is that Ethereum is a deterministic Touring machine, with no inherent randomness involved. A majority of miners have to obtain the same result when evaluating a transaction to reach consensus. Consensus is one of the pillars of blockchain technology and randomness would imply that mutual agreement between all nodes is impossible. Another problem is the public nature of a blockchain. The internal state of a contract, as well as the entire history of a blockchain, is visible to the public. Therefore, it is difficult to find a secure source of entropy. One of the first sources of randomness in Ethereum that came to mind were block timestamps. The problem with block timestamps is, that they can be influenced by the miner, as long as the timestamp is not older than its parent block. Most of the time the timestamps will be close to correct, but if a miner has an incentive to benefit from wrong timestamps, he could use his mining power, in order to mine his blocks with incorrect timestamps to manipulate the outcome of the random function to his favor.

Several workarounds have been developed that overcome this limitations in one way or the other. They can be differentiated into the following groups, each with their respective benefits and downsides:
* **Block hash PRNG** - the hash of a block as source of randomness
* **Oracle RNG** - randomness provided by an oracle, see [Oracle pattern](./oracle.md)
* **Collaborative PRNG** - collaborative generation of a random number within the blockchain

Because the use of an oracle has already been discussed in the [respective pattern](./oracle.md) and the most renown example of collaborative PRNG, [Randao](https://github.com/randao/randao), is not being actively developed anymore, we will focus on the generation of pseudorandom numbers with the help of block hashes in this chapter. Considerations between the use of oracle RNG versus block hash PRNG will be discussed in the Consequences section.

## Applicability

Use the Randomness pattern when
* you want to generate a random number that is not predictable by the users.
* you do not want to use any external services for randomness.
* you have a trusted entity that is able to reliably provide seeds for the generation of randomness.

## Participants & Collaborations

The participating entities in this pattern are the calling contract, a trusted entity and a miner, mining the block of which we are using the block hash as source of entropy. The contract makes use of the  globally available variable of the hash of a block and uses it together with a seed, provided by the trusted entity, to internally compute a number that should be unknown to anyone until the block is mined. 

## Implementation

The simplest implementation of this pattern would be just using the most recent block hash:

```Solidity
// Randomness provided by this is predicatable. Use with care!
function randomNumber() internal view returns (uint) {
    return uint(blockhash(block.number - 1));
}
```

Implemented like this there are two problems, making this solution impractical:
1. a miner could withhold a found block, if the random number derived from the block hash would be to his disadvantage. By withholding the block, the miner would of course lose out on the block reward. This problem is therefore only relevant in cases the monetary value relying on the random number is at least comparatively high as the current block reward.
2. the more more concerning problem is that since `block.number` is a variable available on the blockchain, it can be used as an input parameter by any user. In case of a gambling contract, a user could use `uint(blockhash(block.number - 1)` as the input for his bet and always win the game.

To get rid of the possibility of interference by miners and prediction of random numbers, Bonneau et al. proposed a solution applied on the Bitcoin blockchain \cite{cryptoeprint:2015:1015}: a trusted party provides a seed, which will be hashed together with a future block hash, to make it impossible for the miner to predict the outcome of his block hash on the random number. We are using this idea in this pattern to avoid interference by malicious miners.

The trusted party can be chosen by the contract creator and is stored in the contract. In the beginning users can make their interaction with the contract (like placing bets) in the first stage. With the submission of the sealed seed by the trusted party, bets are closed and the current block number + 1 is stored, which will come in handy later. The seed can be sealed by hashing it together with the address of the trusted party. This allows for easy validation in the next step.

After the seed has been stored, the trusted party has to wait for at least onw block until it can reveal the seed. Of course it has to be validated, that the committed hash was the result of a hash of the now provided seed, by comparing the sealed seed with the hash of the actual seed and the address of the trusted party. If this is the case, the seed is accepted and can be hashed together with the stored block number to generate a pseudorandom number. We use the block number stored in the previous step, because using the current block number would allow for interference by withholding from the miner again, as the seed is sent in plaintext. With the incrementation the block number before storing it, we are making sure a future block hash is used as source of entropy, making it impossible for the trusted party to predict it. 

In case the random number is supposed to be of a special interval, the modulo function can be utilized. Depending on the desired length, only the last part of the obtained hash is used.

## Sample Code

The provided sample showcases the implementation of a pseudorandom number generator with the use of a trusted entity in the context of a betting contract. Any logic regarding the betting process is omitted for the sake of clarity. 
```Solidity
// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.
contract Randomness {

    bytes32 sealedSeed;
    bool seedSet = false;
    bool betsClosed = false;
    uint storedBlockNumber;
    address trustedParty = 0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF;

    function setSealedSeed(bytes32 _sealedSeed) public {
        require(!seedSet);
        require (msg.sender == trustedParty);
        betsClosed = true;
        sealedSeed = _sealedSeed;
        storedBlockNumber = block.number + 1;
        seedSet = true;
    }

    function bet() public {
        require(!betsClosed);
        // Make bets here
    }

    function reveal(bytes32 _seed) public {
        require(seedSet);
        require(betMade);
        require(storedBlockNumber < block.number);
        require(keccak256(msg.sender, _seed) == sealedSeed);
        uint random = uint(keccak256(_seed, blockhash(storedBlockNumber)));
        // Insert logic for usage of random number here;
        seedSet = false;
        betsClosed = false;
    }
}
```
The trusted party is hard-coded into the contract in line 7. It would be an option to allow for the change of the trusted party by the owner with the help of a setter function protected against unauthorized access by the [Access Restriction pattern](./access_restriction.md). Users can make their bets by calling the function `bet()`. The hashed seed can be set by the trusted party, and only the trusted party (line 11), by calling `setSealedSeed(bytes32 _sealedSeed)`. With the function execution, the sealed seed as well as the incremented current block number is stored and the `seedSet` boolean is set to true, to avoid the seed being overwritten by a second function call. Additionally bets are closed, to avoid that the trusted party or the miner can push their bets after learning about the seed or the block hash used to generate the random number. 

After at least one block has passed after providing the sealed seed, the trusted entity can reveal the seed by calling `reveal(bytes32 _seed)` in line 23. The lines 24-27 implement the [Guard Check pattern](./guard_check.md) and assure that the seed can only be revealed after the sealed seed was set (line 24), the relying action has been performed (line 25) and the block we are referencing has already been mined (line 26). An access restriction for the trusted party could be implemented, but is not mandatory, as the trusted party should be the only entity that can provide a seed which matches the sealed seed. This is verified in line 27, where it is checked , if the seed provided by the trusted party was indeed the same, as the one committed in the step before. The actual random number is generated in line 28 by hashing the seed together with the hash of the block at the previously stored number. Next steps could be the formatting of the number into the desired interval and the execution of any logic using the random number, like the payout of the winners.

## Consequences

The consequences of the Randomness Pattern can be evaluated after the following criteria inspired by Kofler (2016):
* **Randomness** - how good is the achieved randomness? Is it pseudo or true randomness?
* **Security** - how secure is the used method to generate randomness?
* **Cost** -  how high are the costs associated with generating randomness?
* **Delay** - how big is the time delay between request and reception of the random number?

The **randomness** generated by the proposed method is pseudorandom. The block hash as well as the seed are provided in a deterministic way and if both input parameters were known, the result could be predicted. However, due to the combination of block hash and seed from two different sources, and both sources having to commit their inputs before learning of the other, it is practically impossible to influence the random number for your benefit.

Once a random number is obtained, we can assume that it is **secure**. The only form of insecurity is introduced by the trusted party. The name trusted party does not mean that we have to trust the party blindly. On the contrary, the measures taken, make it impossible to manipulate the random number, even for the trusted party. We only have to trust it to reveal the provided seed. As the seed is sealed in a cryptographically secure way, there is currently no possibility to obtain the seed without the trusted party. Additionally, the Ethereum blockchain only allows access to the 256 most recent blocks, meaning that the trusted entity has to reveal the seed before the stored block number is not retrievable anymore. A revert mechanism for this case, which lets the users retrieve their funds, should be implemented. In summary that means, that the only way of cheating, with this pattern implemented, would be for the trusted party to withhold the revealed seed, or if the trusted party could influence the block creation of the block of which we are using the hash (either by mining itself or colluding with miners). Nevertheless, this is an improvement over the previous solution, as there is now only one single potential threat, compared to several miners as before.

The **costs** of this method are relatively low, as no external service has to be payed. The gas requirements using a trusted entity are higher, compared to the simple case, as more transactions and storage is needed.

Due to the commitment to a seed and the use of a future block hash, the generation of the random number comes with a little **delay**. In the fastest case a result can be expected after two blocks.

When we compare these consequences with the ones of the [Oracle pattern](./oracle.md), we can work out their differences. The randomness provided by the Oracle can be true randomness, as we can query numbers from services providing true random numbers. While we only have to trust one party in our example, two parties have to be trusted when interacting with oracles: the data provider as well as the oracle service. Another difference is that the oracle service has to be paid for each request. The delay experienced with the oracle solution is comparable to the one proposed above.

It can be concluded, that in simple contracts with no financial impact, a simple implication of block hash randomness without a seed is sufficient. For use cases with higher stakes an oracle service or the showcased solution with a seed can be used, depending on the trust one is willing to put into other parties.
 
## Known Uses
Randomness is often used in contracts with a gaming or gambling context. Implementation of randomness via a future block hash and a seed can be observed in the [Cryptogs contract](https://etherscan.io/address/0xeFabE332D31c3982B76F8630a306C960169bD5b3\#code), a DApp that provides a version of the game of pogs on the Ethereum blockchain. A commit/reveal scheme is used to avoid the use of an oracle. However, [they claim](https://medium.com/coinmonks/is-block-blockhash-block-number-1-okay-14a28e40cc4b) that the added security, compared to a simpler implementation without a commit/reveal mechanic is not worth it for their use case. The additional time and costs related to the extra transactions is not in relation to the monetary value they are handling.

Even though trust is an issue, a lot of contracts seem to be using the services of oracles to access random numbers. All of the observed ones were using Oraclize as their service. The actual source of randomness that Oraclize is getting its numbers from is more heterogeneous. An example for a contract using Oraclize in combination with random.org is [vDice](https://etherscan.io/address/0x7DA90089A73edD14c75B0C827cb54f4248D47eCc\#code), which claims  to be the most popular Ether betting game with over 70.000 bets played. Another contract relying on the services of Oraclize is [Pray4Prey](https://etherscan.io/address/0xe648ae88a6d9b3373e115e3414be91b7cf12de4c\#code). In contrast to vDice, random numbers are generated at WolframAlpha.

The general impression is that simpler contracts tend to rely on block hashes and therefore avoid external communications, while more sophisticated contracts and the ones dealing with larger stakes seem to be more likely to use the services of oracles.

[**< Back**](https://fravoll.github.io/solidity-patterns/)
