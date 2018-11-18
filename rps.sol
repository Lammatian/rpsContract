pragma solidity ^0.4.16;

contract rpsContract {

    // This should be self-explanatory
    struct Player {
        address add;
        bool revealed;
        bool got_paid;
        uint256 hashed_choice;
        uint8 choice;
    }

    address owner;
    // Count if both players got paid (in terms of a tie)
    Player[2] players;
    // 0 - player 0, 1 - player 1, 2 - tie
    uint gameWinner;
    // Used to reset the game in case of inactivity
    uint256 timer;
    GamePhase gamePhase;
    uint256 gameStake;
    
    // Idle - waiting for new players
    // Started - one player started the game
    // Reveal - waiting for the players to reveal
    // Finished - ready to claim the Ether
    enum GamePhase { Idle, Started, Reveal, Finished }
    
    constructor () public {
        owner = msg.sender;
        gamePhase = GamePhase.Idle;
        gameStake = 0;
        players[0] = Player(0, false, false, 0, 0);
        players[1] = Player(0, false, false, 0, 0);
    }

    /**
    Start a new game or get into an existing one by sending a hashed (sha3)
    value of the choice and a random (chosen by the player) seed
     */
    function play(uint256 hashed_choice) public payable {
        require (gamePhase == GamePhase.Idle || gamePhase == GamePhase.Started, "Game is currently on");
        require (msg.value >= 1 ether, "Stakes need to be at least 1 ether");
        require (msg.value % 2 == 0, "Stakes need to be divisible by 2");

        if (gamePhase == GamePhase.Idle) { // first player starting the game
            // half of what you put in is treated as deposit
            // and half as the game prize pool
            gameStake = msg.value / 2;
            gamePhase = GamePhase.Started;
            players[0] = Player(msg.sender, false, false, hashed_choice, 0);
        } else { // second player joining the game
            require (msg.value / 2 == gameStake, "Stake needs to be equal to the other player's stake");
            gamePhase = GamePhase.Reveal;
            // start the timer to enable resetting the game
            // in case of inactivity
            timer = now;
            players[1] = Player(msg.sender, false, false, hashed_choice, 0);
        }
    }

    /**
    Reveal your choice by providing the nonce and choice
     */
    function reveal(uint256 nonce, uint8 choice) public {
        require(gamePhase == GamePhase.Reveal, "Game not in reveal phase yet");
        bytes memory reveal_val = abi.encodePacked(nonce, choice);
        uint8 p = determinePlayer(msg.sender);
        require(p != 2, "You are not taking part in the game");
        require(uint256(keccak256(reveal_val)) == players[p].hashed_choice, "Invalid seed and/or choice");

        // save the choice and mark that
        // the player have revealed the value
        players[p].choice = choice;
        players[p].revealed = true;

        if (players[0].revealed == true && players[1].revealed == true) {
            // both players revealed
            // determine winner and allow claiming winnings
            gamePhase = GamePhase.Finished;
            gameWinner = getWinner(int8(players[0].choice), int8(players[1].choice));
        } else {
            // reset the timer due to activity
            timer = now;
        }
    }

    /**
    Claim money or reset the game in case of inactivity
     */
    function claim() public {
        if (now - timer > 2 minutes && gamePhase == GamePhase.Reveal) {
            // prevent reentrancy attack
            reset();

            // 2 minutes have passed since last activity
            // allow anyone to reset the game
            if (players[0].revealed == true) {
                // first player revealed, gets all
                players[0].got_paid = true;
                players[0].add.transfer(4*gameStake);
            } else if (players[1].revealed == true) {
                // second player revealed, gets all
                players[1].got_paid = true;
                players[1].add.transfer(4*gameStake);
            } else {
                // no player revealed, split 50/50
                players[0].got_paid = true;
                players[1].got_paid = true;
                players[0].add.transfer(2*gameStake);
                players[1].add.transfer(2*gameStake);
            }

            return;
        }

        require(gamePhase == GamePhase.Finished, "Game not finished yet");
        uint8 p = determinePlayer(msg.sender);
        require(p != 2, "You are not taking part in the game");
        require(!players[p].got_paid, "You already have your money");

        if (gameWinner == p) {
            players[p].got_paid = true;
            // transfer 75% of total to winner
            msg.sender.transfer(3*gameStake);
        } else if (gameWinner != p && gameWinner != 2) {
            players[p].got_paid = true;
            // transfer 25% of total to loser
            msg.sender.transfer(gameStake);
        } else if (gameWinner == 2) {
            players[p].got_paid = true;
            // transfer each player 50% of total
            msg.sender.transfer(2*gameStake);
        }

        if (players[0].got_paid && players[1].got_paid) {
            reset();
        }
    }

    /**
    Determine the player based on the address.
    Returns 2 if player is unknown 
     */
    function determinePlayer(address add) private view returns(uint8) {
        if (players[0].add == add) {
            return 0;
        } else if (players[1].add == add) {
            return 1;
        } else {
            return 2;
        }
    }

    /**
    Reset the game state to idle to allow new games
    to be played
     */
    function reset() private {
        gamePhase = GamePhase.Idle;
    }
    
    /**
    Determine the winner given choices of both players
    0 + 3k means 'rock'
    1 + 3k means 'paper'
    2 + 3k means 'scissors'
     */
    function getWinner(int8 a, int8 b) public view returns (uint8) {
        require(gamePhase == GamePhase.Finished, "Game not finished yet");

        if ((a - b) % 3 == 1) {
            return 0;
        } else if ((a - b) % 3 == -1) {
            return 1;
        } else if ((a - b) % 3 == 2) {
            return 1;
        } else if ((a - b) % 3 == -2) {
            return 0;
        } else if ((a - b) % 3 == 0) {
            return 2;
        }
    }

    /**
    Helper function to be able to see what state
    the game is currently in
     */
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

    /**
    Helper function to be able to see what is the
    stake you need to put in to compete
     */
    function getStake() public view returns (uint256) {
        return gameStake;
    }
}