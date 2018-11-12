pragma solidity ^0.4.16;

contract rpsContract {

    address owner;
    mapping(address => uint256) hashed_choices;
    mapping(address => uint8) choices;
    mapping(address => bool) paid;
    // Count if both players got paid (in terms of a tie)
    uint paidCount;
    Player[2] players;
    // 0 - player 0, 1 - player 1, 2 - tie
    uint gameWinner;
    GamePhase gamePhase;
    uint256 gameStake;
    // How many players revealed their choices
    uint revealed;

    struct Player {
        address add;
        bool revealed;
        bool got_paid;
        uint256 hashed_choice;
        uint8 choice;
    }
    
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
        players[0] = Player(0, false, false, 0, 0);
        players[1] = Player(0, false, false, 0, 0);
    }

    /**
    Start a new game or get into an existing one by sending a hashed (sha3)
    value of the choice and a random (chosen by the player) seed
     */
    function play(uint256 hashed_choice) public payable returns (string) {
        require (gamePhase == GamePhase.Idle || gamePhase == GamePhase.Started, "Game is currently on");
        require (msg.value >= 1 ether, "Stakes need to be at least 10 Wei");
        require (msg.value % 2 == 0, "Stakes need to be divisible by 2");

        if (gamePhase == GamePhase.Idle) {
            gameStake = msg.value / 2;
            gamePhase = GamePhase.Started;
            players[0] = Player(msg.sender, false, false, hashed_choice, 0);
        } else {
            require (msg.value / 2 == gameStake, "Stake needs to be equal to the other player's stake");
            gamePhase = GamePhase.Reveal;
            players[1] = Player(msg.sender, false, false, hashed_choice, 0);
        }

        return "Ok";
    }

    function reveal(uint256 nonce, uint8 choice) public returns (string) {
        require(gamePhase == GamePhase.Reveal, "Game not in reveal phase yet");
        bytes memory reveal_val = abi.encodePacked(nonce, choice);
        uint8 p = determinePlayer(msg.sender);
        require(p != 2, "You are not taking part in the game");
        require(uint256(keccak256(reveal_val)) == players[p].hashed_choice, "Invalid seed and/or choice");

        players[p].choice = choice;
        players[p].revealed = true;

        if (players[0].revealed == true && players[1].revealed == true) {
            gamePhase = GamePhase.Finished;
            gameWinner = getWinner(int8(players[0].choice), int8(players[1].choice));
        }
    }

    function claim() public {
        require(gamePhase == GamePhase.Finished, "Game not finished yet");
        uint8 p = determinePlayer(msg.sender);
        require(p != 2, "You are not taking part in the game");

        if (gameWinner == p) {
            players[p].got_paid = true;
            msg.sender.transfer(3*gameStake);
        } else if (gameWinner != p && gameWinner != 2) {
            players[p].got_paid = true;
            msg.sender.transfer(gameStake);
        } else if (gameWinner == 2) {
            players[p].got_paid = true;
            msg.sender.transfer(gameStake);
        }

        if (players[0].got_paid && players[1].got_paid) {
            reset();
        }
    }

    function determinePlayer(address add) private view returns(uint8) {
        if (players[0].add == add) {
            return 0;
        } else if (players[1].add == add) {
            return 1;
        } else {
            return 2;
        }
    }

    function reset() private {
        gamePhase = GamePhase.Idle;
    }
    
    function getWinner(int8 a, int8 b) public view returns (uint8) {
        require(gamePhase == GamePhase.Finished, "Game not finished yet");

        if (a - b == 1) {
            return 0;
        } else if (a - b == -1) {
            return 1;
        } else if (a - b == 2) {
            return 1;
        } else if (a - b == -2) {
            return 0;
        } else if (a - b == 0) {
            return 2;
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
            if (gameWinner == 0) {
                return "Player 1 won, waiting to claim the prize";
            } else if (gameWinner == 1) {
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