pragma solidity ^0.4.20;
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
