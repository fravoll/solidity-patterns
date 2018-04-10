function getBalance(address balanceHolder) public view returns(uint) {
    return eternalStorageAdr.getUint(keccak256("balances", balanceHolder));
}

function setBalance(address balanceHolder, uint amount) internal {
    eternalStorageAdr.setUint(keccak256("balances", balanceHolder), amount);
}

function addBalance(address balanceHolder, uint amount) internal {
    setBalance(balanceHolder, getBalance(balanceHolder) + amount);
}
