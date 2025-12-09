// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveCapoAgent} from '../src/contracts/agent/AaveCapoAgent.sol';

library DeployCapoAgent {
  function deploy(
    address agentHub,
    address rangeValidationModule,
    string memory updateType,
    address pool,
    address aaveOracle
  ) internal {
    new AaveCapoAgent(agentHub, rangeValidationModule, updateType, pool, aaveOracle);
  }
}
