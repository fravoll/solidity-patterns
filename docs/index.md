# Solidity Patterns

This document contains a collection of design and programming patterns for the smart contract programming language Solidity.
Each pattern consists of a code sample and a detailed explanation, including background, implications and additional information about the patterns.

## Contents


* **Behavioral Patterns**
  * [**Guard Check**](./guard_check.md): Ensure that the behavior of a smart contract and its input parameters are as expected.
  * [**State Machine**](./state_machine.md): Enable a contract to go through different stages with different corresponding functionality exposed.
  * [**Oracle**](./oracle.md): Gain access to data stored outside of the blockchain.
  * [**Randomness**](./randomness.md): Generate a random number of a predefined interval in the deterministic environment of a blockchain.
* **Security Patterns**
  * [**Access Restriction**](./access_restriction.md): Restrict the access to contract functionality according to suitable criteria.
  * [**Checks Effects Interactions**](./checks_effects_interactions.md): Reduce the attack surface for malicious contracts trying to hijack control flow after an external call.
  * [**Secure Ether Transfer**](./secure_ether_transfer.md): Secure transfer of ether from a contract to another address.
  * [**Pull over Push**](./pull_over_push.md): Shift the risk associated with transferring ether to the user.
  * [**Emergency Stop**](./emergency_stop.md): Add an option to disable critical contract functionality in case of an emergency.
* **Upgradeability Patterns**
  * [**Proxy Delegate**](./proxy_delegate.md): Introduce the possibility to upgrade smart contracts without breaking any dependencies.
  * [**Eternal Storage**](./eternal_storage.md): Keep contract storage after a smart contract upgrade.
* **Economic Patterns**
  * [**String Equality Comparison**](./string_equality_comparison.md): Check for the equality of two provided strings in a way that minimizes average gas consumption for a large number of different inputs.
  * [**Tight Variable Packing**](./tight_variable_packing.md): Optimize gas consumption when storing or loading statically-sized variables.
  * [**Memory Array Building**](./memory_array_building.md): Aggregate and retrieve data from contract storage in a gas efficient way.

## Help me evaluate!

Right now, the patterns are in the evaluation stage. To help me evaluate the patterns, feel free to open issues or pull requests, to point out possible improvements or fix any errors I may have overlooked.

## Bibliography

The sources used in this document can be found in this [bibliography](./bibliography.md).

## Disclaimer

All patterns in this document are still in development and should only be used under own responsibility. There is no liability for any damages caused by the use of one of these patterns.
