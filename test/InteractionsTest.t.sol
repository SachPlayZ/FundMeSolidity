// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../script/Interactions.s.sol";

contract FundMeTestIntegration is Test {
    FundMe fundMe;
    uint256 public constant SENT_USD = 0.1 ether;
    uint256 public constant GAS_PRICE = 1;
    uint256 public constant USER_BALANCE = 100 ether;
    address USER = makeAddr("user");

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(USER, USER_BALANCE);
    }

    function testUserCanFundInteractions() public {
        vm.startPrank(USER);
        FundFundMe fundFundMe = new FundFundMe();
        vm.deal(address(fundFundMe), 1 ether);
        fundFundMe.fundFundMe(address(fundMe));
        vm.stopPrank();

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);
    }
}
