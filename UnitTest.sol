/**
 *Submitted for verification at Etherscan.io on 2019-12-12
*/

pragma solidity >=0.5.3;

contract UnitTest {
    address private _owner;
    string private _words;

    constructor() public {
        _owner = msg.sender;
        _words = "HelloWorld";
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function helloWorld() public view returns (string memory) {
        return _words;
    }
    function addressZero() public pure returns (address) {
        return address(0);
    }
    function addressTwo() public pure returns (address) {
        return address(1);
    }
    function addressThree() public pure returns (address) {
        return address(2);
    }
}
