// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveEModeAgent} from '../src/contracts/agent/AaveEModeAgent.sol';

library DeployEModeAgent {
  function deploy(
    address agentHub,
    address rangeValidationModule,
    string memory updateTypeSuffix,
    address pool
  ) internal {
    new AaveEModeAgent(agentHub, rangeValidationModule, updateTypeSuffix, pool);
  }
}
