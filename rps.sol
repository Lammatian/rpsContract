pragma solidity ^0.4.16;

contract rpsContract {

    uint value;
    address owner;
    mapping(address => uint256[]) stakes;
    mapping(address => Shape[]) shapes;
    mapping(uint256 => address[]) play_addresses;
    mapping(uint256 => Shape[]) play_shapes;
    
    struct Player {
        address add;
        Shape shape;
    }
    
    enum Shape { Rock, Paper, Scissors }
    
    constructor () public {
        owner = msg.sender;
    }

    function play(Shape shape) payable {
        require (msg.value >= 10 wei);
        stakes[msg.sender].push(msg.value);
        shapes[msg.sender].push(shape);
        //players[msg.value].push(Player(msg.sender, shape));
        play_addresses[msg.value].push(msg.sender);
        play_shapes[msg.value].push(shape);
    }
    
    function challenge(address add, uint256 value, Shape shape) {
        require (msg.value == value);
        require (msg.sender != add);
    }
    
    function getWinner(Shape s_a, Shape s_b) constant returns (uint8) {
        int8 a = int8(s_a);
        int8 b = int8(s_b);
        
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

    function setNP(uint _n) {
        value = _n;
    }

    function getStake (address adr) constant returns (uint256) {
        return stakes[adr][stakes[adr].length - 1];
    }
    
    function getShape (address adr) constant returns (Shape) {
        return shapes[adr][shapes[adr].length - 1];
    }
    
    function getPlayers (uint256 value) constant returns (address[]) {
        return play_addresses[value];
    }
}