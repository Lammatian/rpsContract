from web3 import Web3
from random import randint

seed = randint(2**128, 2**256)
choice = int(input("Pick a choice: "))

h = Web3.soliditySha3(['uint256', 'uint8'], [seed, choice])
print("Seed:", seed)
print("Hash:", int(h.hex(), 16))