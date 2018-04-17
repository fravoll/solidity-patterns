// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.

pragma solidity ^0.4.20;

contract Randomness {

    bytes32 sealedSeed;
    bool seedSet = false;
    bool betMade = false;
    uint storedBlockNumber;
    address trustedParty = 0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF;

    function setSealedSeed(bytes32 _sealedSeed) public {
        require(!seedSet);
        require (msg.sender == trustedParty);
        sealedSeed = _sealedSeed;
        storedBlockNumber = block.number + 1;
        seedSet = true;
    }

    function bet() public {
        require(!betMade);
        // Make bets here
        betMade = true;
    }

    function reveal(bytes32 _seed) public {
        require(seedSet);
        require(betMade);
        require(storedBlockNumber < block.number);
        require(keccak256(msg.sender, _seed) == sealedSeed);
        uint random = uint(keccak256(_seed, block.blockhash(storedBlockNumber)));
        // Insert logic for usage of random number here;
        seedSet = false;
        betMade = false;
    }
}
