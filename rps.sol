pragma solidity ^0.4.16;

contract rpsContract {

    address owner;
    mapping(address => uint256) hashed_choices;
    mapping(address => uint8) choices;
    mapping(address => bool) paid;
    // Count if both players got paid (in terms of a tie)
    uint paidCount;
    address[2] players;
    uint gameWinner;
    GamePhase gamePhase;
    uint256 gameStake;
    // How many players revealed their choices
    uint revealed;
    
    enum Shape { Rock, Paper, Scissors }
    // Idle - waiting for new players
    // Started - one player started the game
    // Reveal - waiting for the players to reveal
    // Finished - ready to claim the Ether
    enum GamePhase { Idle, Started, Reveal, Finished }
    
    constructor () public {
        owner = msg.sender;
        gamePhase = GamePhase.Idle;
        gameStake = 0;
        revealed = 0;
        paidCount = 0;
    }

    /**
    Start a new game or get into an existing one by sending a hashed (sha3)
    value of the choice and a random (chosen by the player) seed
     */
    function play(uint256 hashed_choice) public payable returns (string) {
        require (msg.value >= 10 wei, "Stakes need to be at least 10 Wei");

        if (gamePhase == GamePhase.Started) {
            require (msg.value == gameStake, "Stake needs to be equal to the other player's stake");
            gamePhase = GamePhase.Reveal;
            players[1] = msg.sender;
            paid[msg.sender] = false;
        } else {
            gameStake = msg.value;
            gamePhase = GamePhase.Started;
            players[0] = msg.sender;
            paid[msg.sender] = false;
        }

        hashed_choices[msg.sender] = hashed_choice;

        return "Ok";
    }

    function reveal(uint256 seed, uint8 choice) public returns (string) {
        bytes memory reveal_val = abi.encodePacked(seed, choice);

        if (uint256(keccak256(reveal_val)) != hashed_choices[msg.sender]) {
            return "Invalid seed and/or choice";
        } else if (uint256(keccak256(reveal_val)) == hashed_choices[msg.sender]) {
            choices[msg.sender] = choice;
            revealed += 1;

            if (revealed == 2) {
                gamePhase = GamePhase.Finished;
                gameWinner = getWinner(int8(choices[players[0]]), int8(choices[players[1]]));
            }

            return "Ok";
        }
    }

    function claim() public {
        require(gamePhase == GamePhase.Finished, "Game not finished yet");

        if (gameWinner == 0 && !paid[msg.sender]) {
            paid[msg.sender] = true;
            msg.sender.transfer(gameStake);
            paidCount += 1;

            if (paidCount == 2) {
                reset();
            }
        } else if (msg.sender == players[gameWinner - 1]) {
            msg.sender.transfer(2*gameStake);
            reset();
        }
    }

    function reset() private {
        delete paid[players[0]];
        delete paid[players[1]];
        gameWinner = 0;
        gamePhase = GamePhase.Idle;
        gameStake = 0;
        revealed = 0;
        paidCount = 0;
    }
    
    function getWinner(int8 a, int8 b) public view returns (uint8) {
        require(gamePhase == GamePhase.Finished, "Game not finished yet");

        if (a - b == 1) {
            return 1;
        } else if (a - b == -1) {
            return 2;
        } else if (a - b == 2) {
            return 2;
        } else if (a - b == -2) {
            return 1;
        } else if (a - b == 0) {
            return 0;
        }
    }

    function getGamePhase() public view returns (string) {
        if (gamePhase == GamePhase.Idle) {
            return "Waiting for players";
        } else if (gamePhase == GamePhase.Started) {
            return "Waiting for player 2";
        } else if (gamePhase == GamePhase.Reveal) {
            return "Waiting for the players to reveal their choices";
        } else if (gamePhase == GamePhase.Finished) {
            if (gameWinner == 1) {
                return "Player 1 won, waiting to claim the prize";
            } else if (gameWinner == 2) {
                return "Player 2 won, waiting to claim the prize";
            } else {
                return "Tie, waiting for the players to claim the money";
            }
        }
    }

    function getStake() public view returns (uint256) {
        return gameStake;
    }
}