// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRangeValidationModule} from 'chaos-agents/src/interfaces/IRangeValidationModule.sol';
import {IRiskOracle} from 'chaos-agents/src/contracts/dependencies/IRiskOracle.sol';
import {BaseAgent} from 'chaos-agents/src/contracts/agent/BaseAgent.sol';

/**
 * @title ExampleAgent
 * @notice Agent contract to be used by the AgentHub to do validation and
 *         injection specific to your protocol. This contract should be given the protocol-specific roles
 *         as it will inject the updates into the protocol.
 */
contract ExampleAgent is BaseAgent {
  IRangeValidationModule public immutable RANGE_VALIDATION_MODULE;

  /**
   * @param agentHub the AgentHub address that will use this agent contract
   * @param rangeValidationModule the address of the range validation module used to store range config and to validate ranges
   */
  constructor(address agentHub, address rangeValidationModule) BaseAgent(agentHub) {
    RANGE_VALIDATION_MODULE = IRangeValidationModule(rangeValidationModule);
  }

  /// @inheritdoc BaseAgent
  function validate(
    uint256 agentId,
    bytes calldata agentContext,
    IRiskOracle.RiskParameterUpdate calldata update
  ) public view override returns (bool) {
    // Agent-specific validations go here. This function must be pure validation logic:
    // - view-only (no state writes)
    // - SHOULD NOT revert for normal validation failures; return false instead.
    //
    // Execution context (relative to AgentHub):
    // - The AgentHub has already performed generic checks such as:
    //   - agent enabled/permissioned sender checks
    //   - updateType matching for this agent
    //   - market selection based on `allowedMarkets` or agent `getMarkets()` (if enabled and filtered by `restrictedMarkets`)
    //   - expiration window and minimumDelay enforcement
    //   This method is for protocol-specific invariants on top of the above.
    //
    // Inputs reference:
    // - agentId:      Unique ID of this agent on the hub; can be used to branch
    //                 logic if the same agent contract instance is shared by
    //                 multiple registered agents.
    // - agentContext: Opaque configuration bytes set via `setAgentContext()` on
    //                 the AgentHub. Recommended to abi.decode and use for
    //                 protocol-specific thresholds, addresses, or units.
    //                 Example (customize to your needs):
    //                 abi.decode(agentContext, (address target));
    // - update:       Proposed risk parameter update from the oracle.
    //                 Fields: market, updateType, previousValue, newValue...
    //
    // Pattern: short-circuit false on any violation of protocol-specific invariants.
    //   uint256 fromValue = uint256(bytes32(update.previousValue));
    //   uint256 toValue = uint256(bytes32(update.newValue));
    //   if (toValue == 0) return false;                      // disallow zero values
    //   // add other protocol-specific invariants here...
    //
    // RangeValidationModule: optional common module to validate ranges.
    return (
      RANGE_VALIDATION_MODULE.validate(
        AGENT_HUB,
        agentId,
        update.market,
        IRangeValidationModule.RangeValidationInput({
          from: uint256(bytes32(update.previousValue)),
          to: uint256(bytes32(update.newValue)),
          updateType: update.updateType
        })
      )
    );
  }

  /// @inheritdoc BaseAgent
  function _processUpdate(
    uint256 agentId,
    bytes calldata agentContext,
    IRiskOracle.RiskParameterUpdate calldata update
  ) internal pure override {
    // Inject the update into your protocol here. This is called only AFTER:
    // - AgentHub generic checks succeed
    // - your agent's `validate()` returned true for this exact `update`
    //
    // Expectations:
    // - Keep this focused on execution (state changes / external calls).
    //
    // Typical pattern:
    //   (address target) = abi.decode(agentContext, (address));
    //   // Execute protocol-specific call (ensure this agent has required role)
    //   IYourProtocol(target).setParam(update.market, toValue);
  }

  /// @inheritdoc BaseAgent
  function getMarkets(
    uint256 agentId
  ) external view virtual override returns (address[] memory customMarkets) {
    // Return dynamic/custom markets for this agent when
    // `MarketsFromAgentEnabled` is true on the AgentHub. When false, the hub's
    // `allowedMarkets` are used and this return value is ignored.
    //
    // Expectations:
    // - view-only and deterministic (no state mutation, avoid variable on-chain
    //   iteration over unbounded sets if possible).
    // - Return unique market addresses; the AgentHub will further filter with
    //   `restrictedMarkets` if configured.
    // - If your agent does not rely on dynamic discovery, return an empty array.
    //
    // Example options:
    // 1) Query a registry on your protocol (ensure bounded/cheap iteration):
    //    return IYourProtocolRegistry(REGISTRY).getListedAssets();
    // 2) No dynamic markets:
    //    return new address[](0);
  }
}
