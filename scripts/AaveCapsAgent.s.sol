// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveCapsAgent} from '../src/contracts/agent/AaveCapsAgent.sol';

library DeployCapsAgent {
  function deploy(
    address agentHub,
    address rangeValidationModule,
    address pool
  ) internal {
    new AaveCapsAgent(agentHub, rangeValidationModule, pool);
  }
}
