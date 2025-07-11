// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    
    ExampleExternalContract public exampleExternalContract;

    mapping ( address => uint256 ) public balances;

    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;

    event Stake(address indexed staker, uint256 amount);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
    function stake() public payable {
        require(block.timestamp < deadline, "Staking period has ended");
        require(msg.value > 0, "Must send some ETH");
        
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public {
        require(block.timestamp >= deadline, "Deadline has not passed yet");
        
        // Only execute if threshold is met and not already completed
        if (address(this).balance >= threshold && !exampleExternalContract.completed()) {
            exampleExternalContract.complete{value: address(this).balance}();
        }
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public {
        require(block.timestamp >= deadline, "Deadline has not passed yet");
        require(address(this).balance < threshold, "Threshold was met, cannot withdraw");
        require(balances[msg.sender] > 0, "No balance to withdraw");
        
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }
}
