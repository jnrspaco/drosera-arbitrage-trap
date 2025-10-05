# Arbitrage Trap for Drosera

An automated arbitrage monitoring trap that detects price discrepancies between two DEXs on Ethereum.

## Features

- Monitors price spreads between two DEXs every block
- Triggers when spread exceeds 2% for 2+ consecutive blocks
- Automated response execution via Drosera operators
- Fully tested with Foundry

## Contracts

- `ArbitrageTrap.sol` - Main trap contract with collect() and shouldRespond()
- `ArbitrageResponse.sol` - Response contract triggered when arbitrage detected
- `MockDEX.sol` - Mock DEX for testing

## Setup
```bash
# Install dependencies
forge install

# Compile
forge build

# Run tests
forge test -vvv
