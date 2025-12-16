// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveDiscountRateAgent} from '../src/contracts/agent/AaveDiscountRateAgent.sol';

library DeployDiscountRateAgent {
  function deploy(
    address agentHub,
    address rangeValidationModule,
    string memory updateTypeSuffix,
    address pool,
    address aaveOracle
  ) internal {
    new AaveDiscountRateAgent(agentHub, rangeValidationModule, updateTypeSuffix, pool, aaveOracle);
  }
}
