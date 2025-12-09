// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveSupplyCapAgent} from '../src/contracts/agent/AaveSupplyCapAgent.sol';

library DeploySupplyCapAgent {
  function deploy(
    address agentHub,
    address rangeValidationModule,
    string memory updateType,
    address pool
  ) internal {
    new AaveSupplyCapAgent(agentHub, rangeValidationModule, updateType, pool);
  }
}
