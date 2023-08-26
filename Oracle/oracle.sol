// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.

pragma solidity ^0.4.20;
import "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol";

contract Oracle is usingOraclize {

    string public EURUSD;

    function updatePrice() public payable {
        if (oraclize_getPrice("URL") > this.balance) {
            //Handle out of funds error
        } else {
            oraclize_query("URL", "json(https://api.exchangeratesapi.io/latest?symbols=USD).rates.USD");
        }
    }

    function __callback(bytes32 myid, string memory result) public {
        require(msg.sender == oraclize_cbAddress());
        EURUSD = result;
    }
}
