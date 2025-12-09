// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IPool} from 'aave-address-book/AaveV3.sol';
import {IRangeValidationModule} from 'chaos-agents/src/interfaces/IRangeValidationModule.sol';
import {BaseAgent} from 'chaos-agents/src/contracts/agent/BaseAgent.sol';
import {IRiskOracle} from 'chaos-agents/src/contracts/dependencies/IRiskOracle.sol';
import {ShortStrings, ShortString} from 'openzeppelin-contracts/contracts/utils/ShortStrings.sol';
import {Strings} from 'openzeppelin-contracts/contracts/utils/Strings.sol';

abstract contract BaseAaveAgent is BaseAgent {
  using Strings for string;
  using ShortStrings for *;

  IPool public immutable POOL;
  IRangeValidationModule public immutable RANGE_VALIDATION_MODULE;
  ShortString public immutable UPDATE_TYPE;

  /**
   * @notice The new bytes value from the update is invalid
   */
  error InvalidBytesValue();

  /**
   * @notice The update type on the agent contract differs from the one registered on the agent hub
   */
  error InvalidUpdateType(string updateType);

  /**
   * @param agentHub the address of the agentHub which will use this agent contract
   * @param rangeValidationModule the address of range validation module used to store range config and to validate ranges
   * @param updateType the updateType of the agent contract
   * @param pool the address of aave pool
   */
  constructor(address agentHub, address rangeValidationModule, string memory updateType, address pool) BaseAgent(agentHub) {
    RANGE_VALIDATION_MODULE = IRangeValidationModule(rangeValidationModule);
    POOL = IPool(pool);
    UPDATE_TYPE = updateType.toShortString();
  }

  /// @inheritdoc BaseAgent
  function validate(
    uint256 agentId,
    bytes calldata agentContext,
    IRiskOracle.RiskParameterUpdate calldata update
  ) external view virtual override
   returns (bool) {
    // validates if the updateType registered on the agent hub is same as on the agent contract
    require(update.updateType.equal(UPDATE_TYPE.toString()), InvalidUpdateType(update.updateType));
    return _validateUpdate(agentId, agentContext, update);
  }

  /**
   * @inheritdoc BaseAgent
   * @dev returns all the reserves listed on the aave pool.
   */
  function getMarkets(uint256) external view virtual override returns (address[] memory) {
    return POOL.getReservesList();
  }

  /**
   * @notice method to get the updateType of the agent contract
   * @return updateType of the agent contract in string
   */
  function getUpdateType() external view returns (string memory) {
    return UPDATE_TYPE.toString();
  }

  /**
   * @notice method to decode the bytes data from risk oracle to uint256
   * @param valueInBytes the bytes data received from risk oracle
   * @return the decoded bytes value from risk oracle in uint256
   */
  function _decodeToUint(bytes calldata valueInBytes) internal pure returns (uint256) {
    require(valueInBytes.length <= 32, InvalidBytesValue());
    return
      abi.decode(abi.encodePacked(new bytes(32 - valueInBytes.length), valueInBytes), (uint256));
  }

  /**
   * @notice method to perform the agent specific validation on the risk update.
   *         this is an internal virtual method to be implemented and overridden by the child contract
   *         to validate the risk update before injection
   * @param agentId the id of the agent for which to process injection
   * @param agentContext contains custom config bytes data for the agent
   * @param update risk parameter update to be injected
   * @return true if the proposed update is valid else false
   */
  function _validateUpdate(
    uint256 agentId,
    bytes calldata agentContext,
    IRiskOracle.RiskParameterUpdate calldata update
  ) internal view virtual returns (bool);
}
