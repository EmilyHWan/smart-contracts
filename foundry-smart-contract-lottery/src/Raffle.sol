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

/** Named Imports */
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
                                    
/**
 * @title Sample Raffle Contract 
 * @author Emily Wan
 * @notice This contract creates a sample raffle
 * @dev Implements Chainlink VRFv2 
 */

contract Raffle is VRFConsumerBaseV2 {
    /** Custom Errors */
    // Name an error with its contract source as prefix to make it more traceable
    error Raffle__NotEnoughEthSent();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
    error Raffle__TransferFailed();

    /** Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    } 

    /** State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    // Setting variables private and immutable save gas 
    uint256 private immutable i_entranceFee;
    // @dev Note duration of lottery is set in seconds
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    // Since the list of players will grow, a dynamic array of storage variables should be used 
    // Add, store, and pick a winner among players
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
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

    // Use an external variable here since no internal function will call this function
    function enterRaffle() external payable {
        // Use custom error with the if statement to save gas
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        // Each address is made payable once it's pushed to our array
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /** @dev This Chainlink automation function is timed to check and perform upkeep
     * by Chainlink's nodes
     * Below conditions should be TRUE for function to return true:
     * 1. Specified time interval has passed between raffle runs
     * 2. The raffle is in the OPEN state
     * 3. The contract contains ETH (players)
     * 4. (Implicit) The subscription is funded with LINK
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* perform data */) {
        // Condition 1 is satisfied/true here
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        // Condition 2 is satisfied/true here
        bool isOpen = RaffleState.OPEN == s_raffleState;
        // Condition 3 is satisfied/true here
        bool hasBalance = address(this).balance > 0;
        // Condition 4 is satisfied/true here
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (! upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,  
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 requestId,
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

    /** Getter Functions (for Private Variables) */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }  

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayers) external view returns (address) {
        return s_players[indexOfPlayers];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLengthOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}




