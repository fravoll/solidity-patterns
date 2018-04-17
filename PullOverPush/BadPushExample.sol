// This code contains deliberate errors. Do not use.

pragma solidity ^0.4.21;

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
