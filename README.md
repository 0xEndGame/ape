[![CircleCI](https://circleci.com/gh/ape-fi/ape-finance/tree/ape.svg?style=svg)](https://circleci.com/gh/ape-fi/ape-finance/tree/ape)

Ape Finance
===

Ape Finance is building DeFi tools for metaverse dwellers, proud PFP owners, and digital collectible enthusiasts in all of us. We appreciate culture, art, and games. Ape Finance begins with the creation of the ApeUSD.

## Installation

```
git clone https://github.com/ape-fi/ape-finance
cd ape-finance
yarn install --lock-file # or `npm install`
```

## Building

```
yarn compile
```

## Testing
Jest contract tests are defined under the tests directory. To run the tests run:

```
yarn test
```

## Important features

1. Borrow Fee: All borrows include a borrow fee.
2. Liquidation Fee: Liquidation incentive will be split into two parts. 50% will go to the liquidator and the other 50% will go to Ape Finance.
3. Support helper: Support helper contract to help minting, borrowing, redeeming, and repaying.

