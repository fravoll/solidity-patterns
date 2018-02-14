pragma solidity ^0.4.19;
contract SeedRNG {

    bytes32 encryptedSeed;
    bool seedSet = false;
    bool betMade = false;
    uint blockNumber;
    address trustedParty = 0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF;

    function setEncryptedSeed(bytes32 _encryptedSeed) public {
        require(!seedSet);
        require (msg.sender == trustedParty);
        encryptedSeed = _encryptedSeed;
        blockNumber = block.number;
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
        require(keccak256(msg.sender, _seed) == encryptedSeed);
        uint random = uint(keccak256(_seed, block.blockhash(blockNumber)));
        // Insert logic for usage of random number here;
        seedSet = false;
        betMade = false;
    }
}
