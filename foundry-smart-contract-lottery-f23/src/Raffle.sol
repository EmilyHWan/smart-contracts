//  Layout of Contract: 
//  Version (pragma)
//  Imports
//  Interfaces, libraries, contracts

//  Inside of Contract:
//  Custom errors
//  Type declarations
//  State variables
//  Events
//  Modifiers
//  Functions

//  Layout of Functions:
//  Constructor
//  Receive function (if exists)
//  Fallback function (if exists)
//  External 
//  Public 
//  Internal
//  Private
//  View and pure functions

// Development Best Practice: Checks, Effects, Interactions (CEI)
// Check first for errors, revert early in a function call to save gas
// Effect our own contract
// Interact with other contracts

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title Sample Raffle Contract 
 * @author Emily Wan
 * @notice This contract creates a sample raffle
 * @dev Implements Chainlink VRFv2 
 */

contract Raffle is VRFConsumerBaseV2 {
    // Use custom errors instead of require() to save gas 
    // Use contract name as prefix when naming errors as dev best practice 
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance, 
        uint256 numPlayers, 
        uint256 raffleState
    );
    
    /** Type declarations */
    enum RaffleState { 
        OPEN,
        CALCULATING
    }

    /** State variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Make variable immutable to save gas
    uint256 private immutable i_entranceFee;
    // Each interval or duration of the lottery is set in seconds
    uint256 private immutable i_interval;
    // Call Chainlink external contract to get random numbers
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    // Look up variable type in VRF docs
    bytes32 private immutable i_gasLane;
    // Look up variable type in VRF docs
    uint64 i_subscriptionId;
    // Look up variable type in VRF docs
    uint32 private immutable i_callbackGasLimit;
    // Use dynamic array to add, store, and pick a winner among players
    address payable[] private s_players;
    // Store each snapshot for tracking block time to pick next winner 
    uint256 private s_lastTimeStamp;
    // Track most recent winner and payout
    address private s_recentWinner;
    // Permit or restrict new players 
    RaffleState private s_raffleState;

    /** Events */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);
    
    constructor(
        uint256 entranceFee, 
        uint256 interval, 
        address vrfCoordinator, 
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    } 

    // Make function external instead of public to save gas 
    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }   
        if (s_raffleState != RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        // Emit makes migration easier
        // Make front-end "indexing" easier
        emit EnteredRaffle(msg.sender);
    }

    /** @dev This Chainlink automation function is timed to check and perform upkeep
     * by Chainlink's nodes.
     * Below conditions should be true for function to return true:
     * 1. Specified time interval has passed between raffle runs
     * 2. The raffle is in the OPEN state
     * 3. The contract contains ETH (players)
     * 4. (Implicit) The subscription is funded with LINK
     */
    function checkUpkeep(
        bytes memory /* check data */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");   
    }

    // Function will request a random number from Chainlink contract
    // Use random number to pick a winner
    // Can be called automatically
    function performUpkeep(bytes calldata /* perform data */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");    
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        
        s_raffleState = RaffleState.CALCULATING;
        // RNG requires two functions/transactions
        // Generate a random number
        // Call back the number
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
        // Keyhash
        i_gasLane,
        // Funded Chainlink account ID
        i_subscriptionId,
        // Number of block confirmations
        REQUEST_CONFIRMATIONS,
        // Set a gas spend limit
        i_callbackGasLimit,
        // How many numbers to return
        NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    } 

    // Function will retrieve one random number from array
    // Chainlink node will call internal override function on base contract 
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {     
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner);
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /** Getter Function */
    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns(address) {
        return s_players[indexOfPlayer];
    }

    function getRecentWinner() external view returns(address) {
        return s_recentWinner;
    }

    function getLengthOfPlayers() external view returns(uint256) {
        return s_players.length;
    }

    function getLastTimestamp() external view returns(uint256) {
        return s_lastTimeStamp;
    }

}
