// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 < 0.9.0 ;

// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
contract OracleExample is usingOraclize{

    string public EURUSD;

    function updatePrice() public payable {
        if (oraclize_getPrice("URL") > address(this).balance) {
            //Handle out of funds error
        } else {
            oraclize_query("URL", "json(http://api.fixer.io/latest?symbols=USD).rates.USD");
        }
    }
    
    function __callback(bytes32  myid, string memory result) public {
        require(msg.sender == oraclize_cbAddress());
        EURUSD = result;
    }
}