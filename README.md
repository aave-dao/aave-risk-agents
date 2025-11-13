# Aave Agents

Repository containing Aave Agent contracts to be used by the [Chaos Agents](https://github.com/ChaosLabsInc/chaos-agents) middleware to consume automated risk param updates from Chaos Risk Oracle to inject into the Aave protocol. These agent contracts are designed to be lightweight and only contain validation / injection logic specific to the aave risk param update. To know more about the Chaos Agents middleware, please check [this](https://github.com/ChaosLabsInc/chaos-agents).

This repository hosts the following Aave-specific agent implementations:

- [AaveCapoAgent](src/contracts/agent/AaveCapoAgent.sol): Agent contract to validate / update CAPO feeds params (snapshot ratio, maxGrowthPercent).
- [AaveCapsAgent](src/contracts/agent/AaveCapsAgent.sol): Agent contract to validate / update supply and borrow cap for assets.
- [AaveDiscountRateAgent](src/contracts/agent/AaveDiscountRateAgent.sol): Agent contract to validate / update discount-rate on pendle pt feeds.
- [AaveEModeAgent](src/contracts/agent/AaveEModeAgent.sol): Agent contract to validate / update E-Mode category parameters.
- [AaveRatesAgent](src/contracts/agent/AaveRatesAgent.sol): Agent contract to validate / update interest rate strategy updates.

## Overview

- `Chaos Risk Oracle` publishes automated risk parameter updates (caps, rates, ltv, …) on-chain.
- `Chaos Agents` middleware pulls the oracle payloads, runs protocol-defined checks, and forwards updates to agent contracts.
- `Aave Agent Contracts` (this repo) validate the payload against Aave-specific rules and execute state changes on the target protocol components.

The diagrams below provide a high-level view of the message flow and the Aave-specific deployment:

<img src="./agent-diagram-aave.svg" alt="Aave integration diagram" width="100%" height="100%">

## License

This project is released under the [MIT license](./LICENSE). Copyright © 2025 BGD Labs.
