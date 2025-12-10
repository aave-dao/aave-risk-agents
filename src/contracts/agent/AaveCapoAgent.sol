// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IAaveOracle} from 'aave-v3-origin/src/contracts/interfaces/IAaveOracle.sol';
import {IPriceCapAdapter} from 'aave-capo/interfaces/IPriceCapAdapter.sol';
import {IRangeValidationModule} from 'chaos-agents/src/interfaces/IRangeValidationModule.sol';
import {IRiskOracle} from 'chaos-agents/src/contracts/dependencies/IRiskOracle.sol';
import {BaseAgent} from 'chaos-agents/src/contracts/agent/BaseAgent.sol';

import {BaseAaveAgent} from './BaseAaveAgent.sol';

/**
 * @title AaveCapoAgent
 * @author BGD Labs
 * @notice Agent contract to be used by the agentHub to do postValidation and injection
 *         for updating snapshot ratio, snapshot timestamp and maxGrowthPercent on capo feed by risk oracle on the Aave protocol
 */
contract AaveCapoAgent is BaseAaveAgent {
  IAaveOracle public immutable AAVE_ORACLE;

  /**
   * @param agentHub the address of the agentHub which will use this agent contract
   * @param rangeValidationModule the address of range validation module used to store range config and to validate ranges
   * @param updateTypeSuffix the updateType suffix to append, useful for networks where we have multiple instances, ex. Core and Prime on mainnet.
   * @param pool the address of aave pool
   * @param aaveOracle the address of aave oracle of the instance
   */
  constructor(
    address agentHub,
    address rangeValidationModule,
    string memory updateTypeSuffix,
    address pool,
    address aaveOracle
  ) BaseAaveAgent(agentHub, rangeValidationModule, string.concat('CapoPriceCapUpdate', updateTypeSuffix), pool) {
    AAVE_ORACLE = IAaveOracle(aaveOracle);
  }

  /// @inheritdoc BaseAaveAgent
  function _validateUpdate(
    uint256 agentId,
    bytes calldata,
    IRiskOracle.RiskParameterUpdate calldata update
  ) internal view override returns (bool) {
    IPriceCapAdapter capoFeed = IPriceCapAdapter(AAVE_ORACLE.getSourceOfAsset(update.market));
    IPriceCapAdapter.PriceCapUpdateParams memory newCapoUpdate = _interpret(update.newValue);

    IRangeValidationModule.RangeValidationInput[]
      memory input = new IRangeValidationModule.RangeValidationInput[](2);

    input[0] = IRangeValidationModule.RangeValidationInput({
      from: capoFeed.getSnapshotRatio(),
      to: newCapoUpdate.snapshotRatio,
      updateType: 'CapoSnapshotRatio'
    });
    input[1] = IRangeValidationModule.RangeValidationInput({
      from: capoFeed.getMaxYearlyGrowthRatePercent(),
      to: newCapoUpdate.maxYearlyRatioGrowthPercent,
      updateType: 'CapoMaxYearlyGrowthRatePercent'
    });

    return RANGE_VALIDATION_MODULE.validate(AGENT_HUB, agentId, update.market, input);
  }

  /// @inheritdoc BaseAgent
  function _processUpdate(
    uint256,
    bytes calldata,
    IRiskOracle.RiskParameterUpdate calldata update
  ) internal override {
    address capoFeed = AAVE_ORACLE.getSourceOfAsset(update.market);
    IPriceCapAdapter.PriceCapUpdateParams memory newCapoUpdate = _interpret(update.newValue);

    IPriceCapAdapter(capoFeed).setCapParameters(newCapoUpdate);
  }

  /**
   * @notice method to interpret the capo price cap update values from risk oracle
   * @param valueInBytes bytes encoded capo price cap struct passed from the risk oracle
   * @return value the decoded value from the risk oracle, denotes struct containing snapshot ratio, timestamp and maxGrowthPercent
   */
  function _interpret(
    bytes calldata valueInBytes
  ) internal pure returns (IPriceCapAdapter.PriceCapUpdateParams memory) {
    return abi.decode(valueInBytes, (IPriceCapAdapter.PriceCapUpdateParams));
  }
}
