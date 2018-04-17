# Oracle

## Intent

Gain access to data stored outside of the blockchain.

## Motivation
Every computation on the Ethereum blockchain has to be validated by every participating node in the network. It would not be practical to allow for any kind of external network requests from a contract, since every node would have to make that request on their own to verify its result. Not only would this lead to excessive network usage, which smaller sites could possibly not handle, also a change in the requested information would break the consensus algorithm. Contracts on the blockchain itself are therefore not able to communicate with the outside world, meaning they cannot pull information from sources like the internet. But for many contracts, information about external events is necessary to fulfill their core purpose, especially since the industry is looking for more complex use cases. There are already contracts that rely on information about the result of a sport event, the price of a currency or the status of a flight. One of the first solutions to overcome this limitation was [Orisi](https://github.com/orisi/wiki/wiki/Orisi-White-Paper), a service published in 2014, with the aim of being an intermediary between the Bitcoin blockchain and the outside world. Since then several services for different blockchains with similar concepts have emerged under the term oracle. The oracle acts as an agent living on the blockchain and providing information in the form of responses to queries.

An important point when handling data in the context of a blockchain is the notion of trust. As there is no central authority, trust has to be built from concepts like immutability and a working consensus algorithm. When relying on externally introduced information it is necessary to find a way to build up trust for that information as well. 

## Applicability

Use the Oracle pattern when
* you rely on information that can not be provided from within the blockchain.
* you trust the provider of the necessary information. 

## Participants \& Collaborations

The oracle pattern consists of three entities: the contract requesting information, the oracle and the data source. The process begins with a contract requesting information, which he cannot retrieve from within the blockchain. Therefore a transaction is sent to the oracle contract, which lives on the blockchain as well. This transaction contains a request that the contract wishes to be fulfilled. Optional parameters can be the desired data source, or a certain time in the future, at which the answer should be delivered.

Afterwards the oracle forwards the request to the agreed data source. Because the data source is off-chain, this communication is not conducted via blockchain transactions, but through other forms of digital communication.

When the request reaches the data source it is processed and the reply is sent back to the oracle. From there on the oracle either sends it back to the requesting contact or waits until the time stated in the request. The initial contract receives the data via a function call in which the contract can then execute any logic on the data.

## Implementation

In this section we will only focus on the implementation of the pattern in the requesting contract. The implementation of the oracle itself is done mainly off-chain and is therefore not covered here. There are several resources on the internet that cover how to implement your own oracle customized for the needs of your smart contract and your business model. However, people thinking about interacting with your contract might be turned away by seeing that self-provided data is being used for the execution of contract logic. They would have to trust the contract creator, who in this scenario is the same entity as the oracle operator, to not manipulate the data on the way from the data-source to the contract. This reintroduces the need for trust, which we try to get rid of by using a blockchain.

The more commonly used alternative to this is using an independent service as an oracles. The market leader in this domain at this point is the British company [Oraclize](https://docs.oraclize.it/). Other oracle services are for example [Town Crier](http://www.town-crier.org/), working with trusted hardware, or [Reality Keys](https://www.realitykeys.com/).

Whether or not the oracle is self implemented or an external service is used, it is necessary for the requesting contract to implement at least two methods:
1. The first method assembles a query to let the oracle know which data is requested and sends it in a transaction to the oracle contract. Depending on the implementation of the oracle additional parameters can be added to the request. It is common, that the oracle returns an ID that can be stored for future reference.
2. The second method is a so called callback function. This is the function called by the oracle contract to deliver the result of the query. The callback function either stores the result of the query or triggers any internal logic. The incoming calls can be associated by the ID returned in the first method. It makes sense to include a check in the callback function to make sure that only the oracle is able to call it. Otherwise a malicious entity could provide wrong information to do harm or benefit from it.

## Sample Code

As the service Oraclize is used in almost every case an oracle is needed, the following sample will showcase the code needed to interact with the Oraclize oracle to receive the current EUR to USD exchange rate. Other oracles are integrated in a similar fashion. Information about the accurate syntax needed can be found in the respective documentation.

```Solidity
// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract OracleExample is usingOraclize {

    string public EURUSD;

    function updatePrice() public payable {
        if (oraclize_getPrice("URL") > this.balance) {
            //Handle out of funds error
        } else {
            oraclize_query("URL", "json(http://api.fixer.io/latest?symbols=USD).rates.USD");
        }
    }
    
    function __callback(bytes32 myid, string result) public {
        require(msg.sender != oraclize_cbAddress());
        EURUSD = result;
    }
}
```

In line 2 the API of Oraclize is imported from GitHub. In case the compiler is not supporting the direct import from sources like GitHub it is necessary to replace the import statement with a local import of the API. The API is needed to give access to addresses and the functions needed to interact with the oracle. In line 4 it is specified that the contract inherits from the API by using the keyword `is`. The function `updatePrice()` is sending out the query to the oracle. The `payable` modifier is used, which allows the transaction to have a value (some amount of Ether) attached. This is necessary because the usage of the Oraclize service is not for free. The applying rates can be found in the [Oraclize documentation](https://docs.oraclize.it/). Line 9 asserts that the contract has sufficient funds to pay for the service. If this is not the case the user should be notified, for example by triggering an event. If the balance is sufficient, the query is sent to the Oraclize contract in line 12. The first parameter tells the oracle that we want to query a URL while the second parameter contains the URL of the API and the part of the response JSON object we are interested in, namely the USD value. Any API on the internet can be accessed by this way.

The `__callback(bytes32 myid, string result)` function is used by the oracle to send the result to the contract. The first paramter `myid` could have been saved in the first function and now be used to link the result to a previous request. Line 17 makes sure the calling entity is indeed the oracle. The result is then saved to storage in line 18.

## Consequences

The most important consequences of applying the oracle pattern is gaining access to data otherwise not being available on the blockchain, and therefore allowing business models and use cases with whole new functionality. Besides providing arbitrary data from the web, oracles can be used to automatically trigger a function at a specified time in the future, by providing a time delay parameter in the query. This can solve the often encountered problem of how to schedule function calls on a blockchain. It is also often used for generating random numbers, a difficult task, as described in the [Randomness pattern](./randomness.md). From a developer standpoint it is fairly easy to implement the oracle pattern, especially when using one of the already existing services. Another benefit of using an existing solution is the fact that these solutions are heavily audited, reducing the risk of errors.

A negative consequence of the usage of oracles is the introduction of a single point of failure. The contract creator as well as the users interacting with the contract rely heavily on the information provided by the oracle. Oracles or their data sources have reported wrong data in the past and it is likely that there will be errors in the future again. Not only errors but even small changes in the form of the provided data can break a smart contract like it happened in a [case published on reddit](https://www.reddit.com/r/ethtrader/comments/6w5wcn/important_update_mayweathermcgregor_smart_contract/). A data source changed the formatting of its outputs for a boxing fight from lowercase to uppercase characters, which the immutable smart contract could not handle anymore. Another negative consequence is the trust that has to be put into both, oracles and data sources. In an environment that strives towards decentralization, relying on a single external entity seems contradictory. This issue could potentially be mitigated by forwarding the request to a couple of independent oracles. The results would then be compared and evaluated. A possible strategy could be using M independent oracles and only accepting a result reported by at least N (with N < M) of the M agents.  A drawback of this approach is the cost that increases with every additional oracle. Also the time it takes to come to a conclusion is increasing in most of the cases, since you will have to wait for at least N responses. Another method of mitigating trust from the oracles is beeing used at Oraclize: [TLSNotary proofs](https://tlsnotary.org/). Using TLSNotary, Oraclize can prove that they visited the specified website at a certain time and indeed recieved the provided result. While this would not prevent Oraclize from querying random numbers until they get the desired result, it is trustworthy in case the requested data does not fluctuate over small periods of time.

Further trust issues could be resolved in the future with the adoption of decentralized oracles, on which a lot of work is done during the time of writing. 

## Known Uses
 
Usage of the oracle pattern can be observed in a variety of contracts on the blockchain. An example using the service Oraclize is the contract of [Etherisc](https://github.com/etherisc/flightDelay/blob/master/contracts/FlightDelayPayout.sol) where the oracle is used to get access to flight delay data. The contract then pays out insurance to their users in case of a delayed flight.

Another oracle implementation can be observed in [Ethersquares](https://github.com/ethersquares/ethersquares-contracts/blob/master/contracts/OwnedScoreOracle.sol), a sports betting contract. In this case the owner of the contract acts as an oracle himself. Users are able to verify if the results provided by the owner are correct, with the help of a voting mechanism.

[**< Back**](https://fravoll.github.io/solidity-patterns/)
