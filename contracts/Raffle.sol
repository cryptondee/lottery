// Raffle contract

// Enter lottery paying some amount

// pick random winner

// winner selected every x minutes

// Chain link oracle -> randomness, automated execution (CL keepers)

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatibleInterfaces.sol";

error Raffle__NotEnoughEth();
error Raffle__TransferFailed();

contract Raffle is VRFConsumerBaseV2 {
    /* state variables */

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGaslimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Lottery variables
    address s_recentWinner;

    /* events */

    event RaffelEnter(address indexed player);
    event RequestedRaffleWinner(uint256 requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGaslimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGaslimit = callbackGaslimit;
    }

    function enterRaffle() public payable {
        // require msg.value > i_entranceFee
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEth();
        }
        s_players.push(payable(msg.sender));
        // Events
        //named events with the function name reversed
        emit RaffelEnter(msg.sender);
    }

    /**
     *@dev this is the function that the Chainlink keeper nodes call, they look for the `upKeepNeeded` to be true;
     */
    function checkUpkeep(
        bytes calldata /*checkData*/
    ) external override {}

    function requestRandomWinner() external {
        //request random number
        //once we get it, do something with it
        // VRF is a 2 tx process
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gaslane tells chainlink node the max gas you want to pay
            i_subscriptionId, // contract on chain
            REQUEST_CONFIRMATIONS, // how many confirmations a node must wait
            i_callbackGaslimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        // s_players size 10
        // randomNumber 200
        // using modulo to get the remainder
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // require(success)
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /* view / pure functions */
    function getEntrenceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }
}
