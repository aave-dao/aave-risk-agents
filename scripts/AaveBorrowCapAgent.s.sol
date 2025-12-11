// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveBorrowCapAgent} from '../src/contracts/agent/AaveBorrowCapAgent.sol';

library DeployBorrowCapAgent {
  function deploy(
    address agentHub,
    address rangeValidationModule,
    string memory updateTypeSuffix,
    address pool
  ) internal {
    new AaveBorrowCapAgent(agentHub, rangeValidationModule, updateTypeSuffix, pool);
  }
}
