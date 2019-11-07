# Solidity Patterns

This repository contains a collection of design and programming patterns for the smart contract programming language Solidity in version 0.4.20. Note that newer versions might have changed some of the functionalities.
Each pattern consists of a code sample and a detailed explanation, including background, implications and additional information about the patterns.

Have a look at the documentation site: https://fravoll.github.io/solidity-patterns/

## Contents

* **Behavioral Patterns**
  * [**Guard Check**](docs/guard_check.md): Ensure that the behavior of a smart contract and its input parameters are as expected.
  * [**State Machine**](docs/state_machine.md): Enable a contract to go through different stages with different corresponding functionality exposed.
  * [**Oracle**](docs/oracle.md): Gain access to data stored outside of the blockchain.
  * [**Randomness**](docs/randomness.md): Generate a random number of a predefined interval in the deterministic environment of a blockchain.
* **Security Patterns**
  * [**Access Restriction**](docs/access_restriction.md): Restrict the access to contract functionality according to suitable criteria.
  * [**Checks Effects Interactions**](docs/checks_effects_interactions.md): Reduce the attack surface for malicious contracts trying to hijack control flow after an external call.
  * [**Secure Ether Transfer**](docs/secure_ether_transfer.md): Secure transfer of ether from a contract to another address.
  * [**Pull over Push**](docs/pull_over_push.md): Shift the risk associated with transferring ether to the user.
  * [**Emergency Stop**](docs/emergency_stop.md): Add an option to disable critical contract functionality in case of an emergency.
* **Upgradeability Patterns**
  * [**Proxy Delegate**](docs/proxy_delegate.md): Introduce the possibility to upgrade smart contracts without breaking any dependencies.
  * [**Eternal Storage**](docs/eternal_storage.md): Keep contract storage after a smart contract upgrade.
* **Economic Patterns**
  * [**String Equality Comparison**](docs/string_equality_comparison.md): Check for the equality of two provided strings in a way that minimizes average gas consumption for a large number of different inputs.
  * [**Tight Variable Packing**](docs/tight_variable_packing.md): Optimize gas consumption when storing or loading statically-sized variables.
  * [**Memory Array Building**](docs/memory_array_building.md): Aggregate and retrieve data from contract storage in a gas efficient way.
  

## Disclaimer

This repository is not under active development anymore and some (if not most) sections might be outdated. There is no liability for any damages caused by the use of one of these patterns.
