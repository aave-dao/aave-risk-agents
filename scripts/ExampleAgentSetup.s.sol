// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {IRangeValidationModule} from 'chaos-agents/src/interfaces/IRangeValidationModule.sol';
import {IAgentHub, IAgentConfigurator} from 'chaos-agents/src/interfaces/IAgentHub.sol';

import {ExampleAgent} from '../src/contracts/agent/ExampleAgent.sol';

library SetupExampleAgent {
  function _deployAndSetupExampleAgent(
    address agentHub,
    address rangeValidationModule,
    address owner,
    address riskOracle,
    address[] memory markets
  ) internal {
    // Deploy the protocol-specific agent contract.
    // The agent must be constructed with the AgentHub address and any shared modules it relies on.
    address agentContract = address(new ExampleAgent(agentHub, rangeValidationModule));

    // Register agent on the hub with initial configuration.
    // Notes:
    // - admin: becomes the on-chain admin for this agent (can change flags/configs)
    // - riskOracle: the Chaos RiskOracle that supplies updates for this agent
    // - isAgentEnabled: must be true to allow execution
    // - isAgentPermissioned: when true, only `permissionedSenders` can execute
    // - isMarketsFromAgentEnabled: when true, AgentHub calls `agent.getMarkets()`, using allowedMarkets otherwise
    // - agentContext: encoded custom config which your agent decodes in validate/inject
    // - allowedMarkets: used instead of `agent.getMarkets()`, when isMarketsFromAgentEnabled == false
    // - restrictedMarkets: markets which will not be updated by the agent when enabled
    // - expirationPeriod/minimumDelay: global timing safety rails
    uint256 agentId = IAgentHub(agentHub).registerAgent(
      IAgentConfigurator.AgentRegistrationInput({
        admin: owner,
        riskOracle: riskOracle,
        isAgentEnabled: true,
        isAgentPermissioned: false,
        isMarketsFromAgentEnabled: false,
        agentAddress: agentContract,
        expirationPeriod: 12 hours,
        minimumDelay: 1 days,
        updateType: 'ExampleUpdateType',
        agentContext: '',
        allowedMarkets: markets,
        restrictedMarkets: new address[](0),
        permissionedSenders: new address[](0)
      })
    );

    // Configure default range bounds for this (hub, agentId, updateType).
    // This enables common relative step checks that your agent can reuse.
    IRangeValidationModule(rangeValidationModule).setDefaultRangeConfig(
      agentHub,
      agentId,
      'ExampleUpdateType',
      _getDefaultRangeValidationModuleConfig()
    );
  }

  function _getDefaultRangeValidationModuleConfig()
    internal
    pure
    returns (IRangeValidationModule.RangeConfig memory config)
  {
    return
      IRangeValidationModule.RangeConfig({
        maxIncrease: 30_00,
        maxDecrease: 30_00,
        isIncreaseRelative: true,
        isDecreaseRelative: true
      });
  }
}

// make deploy-ledger contract=scripts/ExampleAgentSetup.s.sol:DeployEthereum chain=mainnet
contract DeployEthereum is EthereumScript {
  // address of the protocol-specific agentHub proxy, should be deployed per protocol.
  address public constant AGENT_HUB = address(0);
  // address of the common range validation modules, could be shared across protocols.
  address public constant RANGE_VALIDATION_MODULE = address(0);

  address public constant TRANSPARENT_PROXY_FACTORY = 0xEB0682d148e874553008730f0686ea89db7DA412;
  address public constant RISK_ORACLE = address(10);
  address public constant OWNER = address(20);
  address public constant MARKET = address(30);

  function run() external broadcast {
    // Prepare initial markets for this example agent.
    address[] memory markets = new address[](1);
    markets[0] = MARKET;

    // Deploy agent implementation and register/configure it on the AgentHub.
    SetupExampleAgent._deployAndSetupExampleAgent(
      AGENT_HUB,
      RANGE_VALIDATION_MODULE,
      OWNER,
      RISK_ORACLE,
      markets
    );
  }
}
