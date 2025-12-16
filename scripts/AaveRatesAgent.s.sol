// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveRatesAgent} from '../src/contracts/agent/AaveRatesAgent.sol';

library DeployRatesAgent {
  function deploy(
    address agentHub,
    address rangeValidationModule,
    string memory updateTypeSuffix,
    address pool
  ) internal {
    new AaveRatesAgent(agentHub, rangeValidationModule, updateTypeSuffix, pool);
  }
}
