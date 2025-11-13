// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAgentConfigurator} from 'chaos-agents/src/interfaces/IAgentHub.sol';
import {BaseAgentTest} from 'chaos-agents/tests/agent/BaseAgentTest.sol';
import {RangeValidationModule, IRangeValidationModule} from 'chaos-agents/src/contracts/modules/RangeValidationModule.sol';
import {ExampleAgent} from '../../src/contracts/agent/ExampleAgent.sol';

contract ExampleAgent_Test is BaseAgentTest('ExampleUpdateType') {
  RangeValidationModule internal _rangeValidationModule;

  address public constant MARKET = address(10);

  function setUp() public override {
    super.setUp();
  }

  function _customiseAgentConfig(
    IAgentConfigurator.AgentRegistrationInput memory config
  ) internal pure override returns (IAgentConfigurator.AgentRegistrationInput memory) {
    // Add custom agent configuration here. Common options:
    // - Agent address:      set when deploying the agent; handled by the base test.
    // - Update type:        provided by BaseAgentTest constructor.
    // - Markets behavior:   choose between hub-configured markets vs. agent-provided markets.
    // - Agent context:      encode protocol-specific data that your agent will decode in `validate()`/`_processUpdate()`.
    // - Permissioning:      optional allow-list of senders who can call `execute()`.
    // - Timing controls:    expiration window and minimum delay between updates per (agent, market).

    // Example: Use markets configured on the hub
    config.isMarketsFromAgentEnabled = false;
    config.allowedMarkets = _addressToArray(MARKET);

    // Example: Use dynamic markets from agent contract instead of hub
    // config.isMarketsFromAgentEnabled = true;
    // config.allowedMarkets = new address[](0); // ignored when MarketsFromAgentEnabled = true

    // Example: Provide agent-specific context (decoded by the agent)
    // address target = address(0x1234);
    // config.agentContext = abi.encode(target);

    // Example: Configure permissioned execution (only allowlisted senders can execute)
    // address allowedAutomation = address(0xBEEF);
    // config.isAgentPermissioned = true;
    // config.permissionedSenders = _addressToArray(allowedAutomation);

    // Example: Set timing controls
    // config.expirationPeriod = 12 hours; // update must be injected within this window from oracle publish time
    // config.minimumDelay = 1 days;       // min interval between injections for a given (agent, market)

    return config;
  }

  function _deployAgent() internal override returns (address) {
    // Deploy any shared modules first
    // RangeValidationModule holds per-agent range configs and exposes `validate()`
    _rangeValidationModule = new RangeValidationModule();

    // Deploy the agent under test. Pass the AgentHub address and any modules
    // the agent needs to reference during validation/injection.
    // Note: In production, ensure the deployed agent receives the necessary protocol roles.
    return address(new ExampleAgent(address(_agentHub), address(_rangeValidationModule)));
  }

  function _postSetup() internal override {
    // Post-setup actions after agent registration. Typical steps include:
    // - Granting protocol roles/permissions to the agent contract (e.g., RISK_ADMIN).
    // - Seeding module configs (e.g., default ranges, caps) for this agentId.

    // Configure default range bounds used by RangeValidationModule for this agentId/updateType.
    // Relative maxIncrease/maxDecrease are in basis points (e.g., 100_00 == 100%).
    _rangeValidationModule.setDefaultRangeConfig(
      address(_agentHub),
      _agentId,
      'ExampleUpdateType',
      IRangeValidationModule.RangeConfig({
        maxIncrease: 100_00,
        maxDecrease: 100_00,
        isIncreaseRelative: true,
        isDecreaseRelative: true
      })
    );

    // Example: grant protocol role to agent (pseudo-code)
    // IACLManager(PROTOCOL_ACL).grantRole(RISK_ADMIN, address(_agent));
  }

  function test_updateInjection() public {
    _addUpdateToRiskOracle();
    assertTrue(_checkAndPerformAutomation(_agentId));
  }

  function _addUpdateToRiskOracle() internal {
    // Publish a mock update into the RiskOracle as the oracle owner.
    // Tests can vary any of these fields to exercise validation paths:
    // - referenceId:     off-chain correlation ID (free-form)
    // - value (bytes32): new target value; encode as needed (e.g., uint256)
    // - updateType:      must match the agent's configured updateType
    // - market:          the asset/market the update applies to
    // - extraData:       optional aux data consumed by the oracle/agent
    vm.startPrank(_riskOracleOwner);
    _riskOracle.publishRiskParameterUpdate(
      'referenceId',
      abi.encodePacked(uint256(0)), // mock value
      _updateType,
      MARKET, // mock market
      'additionalData'
    );
    vm.stopPrank();
  }
}
