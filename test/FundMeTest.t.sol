// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    uint256 public constant SENT_USD = 0.1 ether;
    uint256 public constant GAS_PRICE = 1;
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 USER_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, USER_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMessageSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersion() public view {
        uint256 getVersion = fundMe.getVersion();
        assertEq(getVersion, 4);
    }

    function testFundfails() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesSuccessful() public {
        vm.prank(USER);
        fundMe.fund{value: SENT_USD}();
        uint256 amountFunded = fundMe.s_addressToAmountFunded(USER);
        assertEq(amountFunded, SENT_USD);
    }

    function testAddsFunder() public {
        vm.prank(USER);
        fundMe.fund{value: SENT_USD}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SENT_USD}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingOwnerBalance - startingOwnerBalance, SENT_USD);
        assertEq(endingFundMeBalance, 0);
        uint256 gasUsed = (gasStart - gasleft()) * tx.gasprice;
        console.log("Gas used: ", gasUsed);
    }

    function testWithDrawWithMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SENT_USD);
            fundMe.fund{value: SENT_USD}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(
            endingOwnerBalance - startingOwnerBalance,
            SENT_USD * numberOfFunders
        );
        assertEq(endingFundMeBalance, 0);
    }

    function testWithDrawWithMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SENT_USD);
            fundMe.fund{value: SENT_USD}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(
            endingOwnerBalance - startingOwnerBalance,
            SENT_USD * numberOfFunders
        );
        assertEq(endingFundMeBalance, 0);
    }
}
