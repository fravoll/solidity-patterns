pragma solidity ^0.4.20;

contract GuardCheck {

    function donate(address addr) payable public {

        require(addr != 0);
        require(msg.value != 0);
        uint balanceBeforeTransfer = this.balance;
        uint transferAmount;

        if(addr.balance == 0) {
            transferAmount = msg.value;
        } else if(addr.balance < msg.sender.balance) {
            transferAmount = msg.value / 2;
        } else {
            revert();
        }

        addr.transfer(transferAmount);
        assert(this.balance == balanceBeforeTransfer - transferAmount);

    }
}
