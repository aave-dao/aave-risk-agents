// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {ReserveConfiguration, DataTypes} from 'aave-v3-origin/src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {IAaveV3ConfigEngine as IEngine} from 'aave-v3-origin/src/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {EngineFlags} from 'aave-v3-origin/src/contracts/extensions/v3-config-engine/EngineFlags.sol';
import {Address} from 'openzeppelin-contracts/contracts/utils/Address.sol';
import {IRiskOracle} from 'chaos-agents/src/contracts/dependencies/IRiskOracle.sol';
import {IRangeValidationModule} from 'chaos-agents/src/interfaces/IRangeValidationModule.sol';

import {BaseAaveAgent, BaseAgent} from './BaseAaveAgent.sol';

/**
 * @title AaveBorrowCapAgent
 * @author BGD Labs
 * @notice Agent contract to be used by the agentHub to do validation and
 *         injection for borrow caps by risk oracle on the Aave protocol
 */
contract AaveBorrowCapAgent is BaseAaveAgent {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using Address for address;

  /**
   * @param agentHub the address of the agentHub which will use this agent contract
   * @param rangeValidationModule the address of range validation module used to store range config and to validate ranges
   * @param updateTypeSuffix the updateType suffix to append, useful for networks where we have multiple instances, ex. Core and Prime on mainnet.
   * @param pool the address of aave pool
   */
  constructor(
    address agentHub,
    address rangeValidationModule,
    string memory updateTypeSuffix,
    address pool
  ) BaseAaveAgent(agentHub, rangeValidationModule, 'BorrowCapUpdate', updateTypeSuffix, pool) {}

  /// @inheritdoc BaseAaveAgent
  function _validateUpdate(
    uint256 agentId,
    bytes calldata,
    IRiskOracle.RiskParameterUpdate calldata update
  ) internal view override returns (bool) {
    uint256 currentCap = POOL.getConfiguration(update.market).getBorrowCap();
    uint256 newCap = _interpret(update.newValue);

    if (currentCap == newCap || currentCap == 0 || newCap == 0) return false;

    return
      RANGE_VALIDATION_MODULE.validate(
        AGENT_HUB,
        agentId,
        update.market,
        IRangeValidationModule.RangeValidationInput({
          from: currentCap,
          to: newCap,
          updateType: update.updateType
        })
      );
  }

  /// @inheritdoc BaseAgent
  function _processUpdate(
    uint256,
    bytes calldata agentContext,
    IRiskOracle.RiskParameterUpdate calldata update
  ) internal override {
    uint256 newCap = _interpret(update.newValue);

    IEngine.CapsUpdate[] memory capsUpdate = new IEngine.CapsUpdate[](1);
    capsUpdate[0] = IEngine.CapsUpdate({
      asset: update.market,
      supplyCap: EngineFlags.KEEP_CURRENT,
      borrowCap: newCap
    });

    address target = abi.decode(agentContext, (address));
    target.functionDelegateCall(abi.encodeWithSelector(IEngine.updateCaps.selector, capsUpdate));
  }

  /**
   * @notice method to interpret the cap value from risk oracle
   * @param valueInBytes bytes encoded cap value passed from the risk oracle
   * @return value the decoded value from the risk oracle, denotes the cap value in units
   */
  function _interpret(bytes calldata valueInBytes) internal pure returns (uint256) {
    return _decodeToUint(valueInBytes);
  }
}
