// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TestnetProcedures} from 'aave-v3-origin/tests/utils/TestnetProcedures.sol';
import {CLRatePriceCapAdapter, IPriceCapAdapter, IACLManager} from 'aave-capo/contracts/CLRatePriceCapAdapter.sol';
import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {RangeValidationModule, IRangeValidationModule} from 'chaos-agents/src/contracts/modules/RangeValidationModule.sol';
import {IAgentHub, IAgentConfigurator} from 'chaos-agents/src/interfaces/IAgentHub.sol';
import {BaseAgentTest} from 'chaos-agents/tests/agent/BaseAgentTest.sol';
import {Math} from 'openzeppelin-contracts/contracts/utils/math/Math.sol';

import {AaveCapoAgent} from '../../src/contracts/agent/AaveCapoAgent.sol';

contract AaveCapoAgent_Test is BaseAgentTest('CapoPriceCapUpdate'), TestnetProcedures {
  using SafeCast for uint256;

  RangeValidationModule public _rangeValidationModule;

  address internal _lstAsset;
  address internal _ratioProviderFeed = address(58);
  CLRatePriceCapAdapter internal _capoFeed;

  function setUp() public override {
    initTestEnvironment();

    // assume the already listed weth asset as wstETH
    _lstAsset = address(weth);
    super.setUp();

    vm.warp(1750000000); // Jun-15-2025
  }

  function _customiseAgentConfig(
    IAgentConfigurator.AgentRegistrationInput memory config
  ) internal view override returns (IAgentConfigurator.AgentRegistrationInput memory) {
    address[] memory markets = new address[](1);
    markets[0] = _lstAsset;

    config.allowedMarkets = markets;
    config.isMarketsFromAgentEnabled = false;
    return config;
  }

  function _deployAgent() internal override returns (address) {
    _rangeValidationModule = new RangeValidationModule();

    return
      address(
        new AaveCapoAgent(
          address(_agentHub),
          address(_rangeValidationModule),
          address(contracts.poolProxy),
          address(contracts.aaveOracle)
        )
      );
  }

  function _postSetup() internal override {
    _rangeValidationModule.setDefaultRangeConfig(
      address(_agentHub),
      _agentId,
      'CapoSnapshotRatio',
      IRangeValidationModule.RangeConfig({
        maxIncrease: 5_00,
        maxDecrease: 5_00,
        isIncreaseRelative: true,
        isDecreaseRelative: true
      })
    );
    _rangeValidationModule.setDefaultRangeConfig(
      address(_agentHub),
      _agentId,
      'CapoMaxYearlyGrowthRatePercent',
      IRangeValidationModule.RangeConfig({
        maxIncrease: 10_00,
        maxDecrease: 10_00,
        isIncreaseRelative: true,
        isDecreaseRelative: true
      })
    );

    // mocks the ratio provider contract
    vm.mockCall(_ratioProviderFeed, abi.encodeWithSignature('latestAnswer()'), abi.encode(1.15e18));
    vm.mockCall(_ratioProviderFeed, abi.encodeWithSignature('decimals()'), abi.encode(18));
    vm.warp(1750000000); // Jun-15-2025

    _capoFeed = new CLRatePriceCapAdapter(
      IPriceCapAdapter.CapAdapterParams({
        aclManager: IACLManager(address(contracts.aclManager)),
        baseAggregatorAddress: contracts.aaveOracle.getSourceOfAsset(_lstAsset),
        ratioProviderAddress: _ratioProviderFeed,
        pairDescription: 'wstETH / ETH / USD Capo',
        minimumSnapshotDelay: 7 days,
        priceCapParams: IPriceCapAdapter.PriceCapUpdateParams({
          snapshotRatio: 1.15e18,
          snapshotTimestamp: 1748000000, // May-23-2024
          maxYearlyRatioGrowthPercent: 9_68
        })
      })
    );

    address[] memory oracles = new address[](1);
    oracles[0] = address(_capoFeed);
    address[] memory assets = new address[](1);
    assets[0] = _lstAsset;

    vm.startPrank(poolAdmin);
    // updates the weth asset oracle to wstETH so it behave as wstETH
    contracts.aaveOracle.setAssetSources(assets, oracles);
    contracts.aclManager.addRiskAdmin(address(_agent));
    vm.stopPrank();
  }

  function test_validate_snapshotRatioNotInRange(uint16 snapshotRatioChange) public {
    vm.assume(snapshotRatioChange > 5_00 && snapshotRatioChange <= 100_00);
    uint256 currentSnapshotRatio = _capoFeed.getSnapshotRatio();
    uint256 currentMaxGrowthPercent = _capoFeed.getMaxYearlyGrowthRatePercent();
    uint256 currentSnapshotTs = _capoFeed.getSnapshotTimestamp();

    // more than 5% relative increase
    _addUpdateToRiskOracle(
      (currentSnapshotRatio * (100_00 + snapshotRatioChange)) / 100_00,
      currentSnapshotTs + 1,
      currentMaxGrowthPercent
    );
    assertFalse(_agent.validate(_agentId, '', _riskOracle.getUpdateById(1)));

    // more than 5% relative decrease
    _addUpdateToRiskOracle(
      (currentSnapshotRatio * (100_00 - snapshotRatioChange)) / 100_00,
      currentSnapshotTs + 1,
      currentMaxGrowthPercent
    );
    assertFalse(_agent.validate(_agentId, '', _riskOracle.getUpdateById(2)));
  }

  function test_validate_snapshotRatioInRange(uint16 snapshotRatioChange) public {
    vm.assume(snapshotRatioChange <= 5_00);
    uint256 currentSnapshotRatio = _capoFeed.getSnapshotRatio();
    uint256 currentMaxGrowthPercent = _capoFeed.getMaxYearlyGrowthRatePercent();
    uint256 currentSnapshotTs = _capoFeed.getSnapshotTimestamp();

    // less than 5% relative increase
    _addUpdateToRiskOracle(
      (currentSnapshotRatio * (100_00 + snapshotRatioChange)) / 100_00,
      currentSnapshotTs + 1,
      currentMaxGrowthPercent
    );
    assertTrue(_agent.validate(_agentId, '', _riskOracle.getUpdateById(1)));

    // less than 5% relative decrease
    _addUpdateToRiskOracle(
      (currentSnapshotRatio * (100_00 - snapshotRatioChange)) / 100_00,
      currentSnapshotTs + 1,
      currentMaxGrowthPercent
    );
    assertTrue(_agent.validate(_agentId, '', _riskOracle.getUpdateById(2)));
  }

  function test_validate_maxGrowthPercentNotInRange(uint16 maxGrowthPercentChange) public {
    vm.assume(maxGrowthPercentChange > 10_00 && maxGrowthPercentChange <= 100_00);
    uint256 currentSnapshotRatio = _capoFeed.getSnapshotRatio();
    uint256 currentMaxGrowthPercent = _capoFeed.getMaxYearlyGrowthRatePercent();
    uint256 currentSnapshotTs = _capoFeed.getSnapshotTimestamp();

    // more than 5% relative increase
    _addUpdateToRiskOracle(
      currentSnapshotRatio,
      currentSnapshotTs + 1,
      // we need to round up for checking increase not in range
      Math.mulDiv(
        currentMaxGrowthPercent,
        (100_00 + maxGrowthPercentChange),
        100_00,
        Math.Rounding.Ceil
      )
    );
    assertFalse(_agent.validate(_agentId, '', _riskOracle.getUpdateById(1)));

    // more than 5% relative decrease
    _addUpdateToRiskOracle(
      currentSnapshotRatio,
      currentSnapshotTs + 1,
      // we need to round down for checking decrease not in range
      Math.mulDiv(
        currentMaxGrowthPercent,
        (100_00 - maxGrowthPercentChange),
        100_00,
        Math.Rounding.Floor
      )
    );
    assertFalse(_agent.validate(_agentId, '', _riskOracle.getUpdateById(2)));
  }

  function test_validate_maxGrowthPercentInRange(uint16 maxGrowthPercentChange) public {
    vm.assume(maxGrowthPercentChange <= 10_00);
    uint256 currentSnapshotRatio = _capoFeed.getSnapshotRatio();
    uint256 currentMaxGrowthPercent = _capoFeed.getMaxYearlyGrowthRatePercent();
    uint256 currentSnapshotTs = _capoFeed.getSnapshotTimestamp();

    // less than 5% relative increase
    _addUpdateToRiskOracle(
      currentSnapshotRatio,
      currentSnapshotTs + 1,
      // we need to round down for checking increase in range
      Math.mulDiv(
        currentMaxGrowthPercent,
        (100_00 + maxGrowthPercentChange),
        100_00,
        Math.Rounding.Floor
      )
    );
    assertTrue(_agent.validate(_agentId, '', _riskOracle.getUpdateById(1)));

    // less than 5% relative decrease
    _addUpdateToRiskOracle(
      currentSnapshotRatio,
      currentSnapshotTs + 1,
      // we need to round up for checking decrease in range
      Math.mulDiv(
        currentMaxGrowthPercent,
        (100_00 - maxGrowthPercentChange),
        100_00,
        Math.Rounding.Ceil
      )
    );
    assertTrue(_agent.validate(_agentId, '', _riskOracle.getUpdateById(2)));
  }

  function test_snapshotTimestampNotInRange(uint40 newSnapshotTimestamp) public {
    uint256 minSnapshotTimestamp = _capoFeed.getSnapshotTimestamp();
    uint256 maxSnapshotTimestamp = block.timestamp - _capoFeed.MINIMUM_SNAPSHOT_DELAY();
    vm.assume(
      newSnapshotTimestamp <= minSnapshotTimestamp || newSnapshotTimestamp >= maxSnapshotTimestamp
    );

    _addUpdateToRiskOracle(
      _capoFeed.getSnapshotRatio(),
      newSnapshotTimestamp,
      _capoFeed.getMaxYearlyGrowthRatePercent()
    );

    uint256[] memory agentIds = new uint256[](1);
    agentIds[0] = _agentId;
    (bool shouldRunKeeper, IAgentHub.ActionData[] memory actions) = _agentHub.check(agentIds);
    assertTrue(shouldRunKeeper);

    vm.expectRevert(
      abi.encodeWithSelector(IPriceCapAdapter.InvalidRatioTimestamp.selector, newSnapshotTimestamp)
    );
    _agentHub.execute(actions);
  }

  function test_injectionFromHub() public {
    uint256 newMaxGrowthPercent = (_capoFeed.getMaxYearlyGrowthRatePercent() * 110) / 100; // 10% relative increase
    uint256 newSnapshotRatio = (_capoFeed.getSnapshotRatio() * 105) / 100; // 5% relative increase
    uint256 newSnapshotTimestamp = block.timestamp - _capoFeed.MINIMUM_SNAPSHOT_DELAY() - 1;

    _addUpdateToRiskOracle(newSnapshotRatio, newSnapshotTimestamp, newMaxGrowthPercent);

    assertTrue(_checkAndPerformAutomation(_agentId));

    assertEq(_capoFeed.getMaxYearlyGrowthRatePercent(), newMaxGrowthPercent);
    assertEq(_capoFeed.getSnapshotRatio(), newSnapshotRatio);
    assertEq(_capoFeed.getSnapshotTimestamp(), newSnapshotTimestamp);
  }

  function test_injection_sameMaxGrowthPercent() public {
    uint256 newSnapshotRatio = _capoFeed.getSnapshotRatio() - 1;
    uint256 newSnapshotTimestamp = block.timestamp - _capoFeed.MINIMUM_SNAPSHOT_DELAY() - 1;
    uint256 currentMaxGrowthPercent = _capoFeed.getMaxYearlyGrowthRatePercent();

    _addUpdateToRiskOracle(newSnapshotRatio, newSnapshotTimestamp, currentMaxGrowthPercent);
    assertTrue(_checkAndPerformAutomation(_agentId));

    assertEq(_capoFeed.getMaxYearlyGrowthRatePercent(), currentMaxGrowthPercent);
  }

  function test_injection_sameSnapshotRatio() public {
    uint256 currentSnapshotRatio = _capoFeed.getSnapshotRatio();
    uint256 newSnapshotTimestamp = block.timestamp - _capoFeed.MINIMUM_SNAPSHOT_DELAY() - 1;
    uint256 newMaxGrowthPercent = _capoFeed.getMaxYearlyGrowthRatePercent() - 1;

    _addUpdateToRiskOracle(currentSnapshotRatio, newSnapshotTimestamp, newMaxGrowthPercent);
    assertTrue(_checkAndPerformAutomation(_agentId));

    assertEq(_capoFeed.getSnapshotRatio(), currentSnapshotRatio);
  }

  function test_injection_sameSnapshotTsNotAllowed() public {
    uint256 newSnapshotRatio = _capoFeed.getSnapshotRatio() - 1;
    uint256 newMaxGrowthPercent = _capoFeed.getMaxYearlyGrowthRatePercent() - 1;
    uint256 currentSnapshotTs = _capoFeed.getSnapshotTimestamp();

    _addUpdateToRiskOracle(newSnapshotRatio, currentSnapshotTs, newMaxGrowthPercent);

    uint256[] memory agentIds = new uint256[](1);
    agentIds[0] = _agentId;
    (bool shouldRunKeeper, IAgentHub.ActionData[] memory actions) = _agentHub.check(agentIds);
    assertTrue(shouldRunKeeper);

    vm.expectRevert(
      abi.encodeWithSelector(IPriceCapAdapter.InvalidRatioTimestamp.selector, currentSnapshotTs)
    );
    _agentHub.execute(actions);
  }

  function _addUpdateToRiskOracle(
    uint256 snapshotRatio,
    uint256 snapshotTimestamp,
    uint256 maxGrowthPercent
  ) internal {
    vm.startPrank(_riskOracleOwner);

    _riskOracle.publishRiskParameterUpdate(
      'referenceId',
      abi.encode(
        IPriceCapAdapter.PriceCapUpdateParams({
          snapshotRatio: snapshotRatio.toUint104(),
          snapshotTimestamp: snapshotTimestamp.toUint48(),
          maxYearlyRatioGrowthPercent: maxGrowthPercent.toUint16()
        })
      ),
      _updateType,
      _lstAsset,
      'additionalData'
    );
    vm.stopPrank();
  }
}
