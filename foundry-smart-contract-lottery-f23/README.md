# Proveably Random Raffle Contracts

## About This Code

## What This Code Will Do
1. Users can enter the raffle by purchasing a ticket in ETH
    1. Collected ticket fees will be paid to each draw's winner during the draw
2. After x time passes, the lottery will automatically draw the next winner
    1. The drawing will be done programmatically
3. Chainlink VRF and Chainlink Automation will perform the drawing and timekeeping functions
    1. VRF -> Randomness
    2. Automation -> Time-based trigger

## Tests
1. Deploy scripts
2. Tests 
    1. Work on local chain
    2. Forked testnet
    3. Forked mainnet