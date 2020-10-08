# Smarts Finance Contracts

# Addresses 

## Mainnet
Token: Coming soon
Sale: Coming soon

## Ropsten
Token: 0xe350e7d7fced05c6712564218c3cab0a1d86b83d
Sale: 0xd0371c7647b9fdcf8b3ee9c7c98d17af655da283

# State of the art

### Smarts.sol
ERC20 Token


### Sale.sol
ERC20 Token sale

## Instructions
* Deploy the two contracts.
* Call Smarts.issue to generate 890.000 tokens for the team.
* Call Sale.transferOwnership and give the Smarts address.
* Call Sale.start

# Setup

Install project deps

```bash
$ npm install
```

# Test

Run tests
```bash
$ npm test
```

# Compile

```bash
$ npm run build
```

You can find the generated abis at ./build/contracts/
