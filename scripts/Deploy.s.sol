// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript, PolygonScript, BNBScript, GnosisScript, ArbitrumScript, OptimismScript, PlasmaScript, LineaScript, BaseScript, AvalancheScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3EthereumLido} from 'aave-address-book/AaveV3EthereumLido.sol';
import {MiscPolygon} from 'aave-address-book/MiscPolygon.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';
import {MiscBNB} from 'aave-address-book/MiscBNB.sol';
import {AaveV3BNB} from 'aave-address-book/AaveV3BNB.sol';
import {MiscGnosis} from 'aave-address-book/MiscGnosis.sol';
import {AaveV3Gnosis} from 'aave-address-book/AaveV3Gnosis.sol';
import {MiscPlasma} from 'aave-address-book/MiscPlasma.sol';
import {AaveV3Plasma} from 'aave-address-book/AaveV3Plasma.sol';
import {MiscArbitrum} from 'aave-address-book/MiscArbitrum.sol';
import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {MiscOptimism} from 'aave-address-book/MiscOptimism.sol';
import {AaveV3Optimism} from 'aave-address-book/AaveV3Optimism.sol';
import {MiscLinea} from 'aave-address-book/MiscLinea.sol';
import {AaveV3Linea} from 'aave-address-book/AaveV3Linea.sol';
import {MiscBase} from 'aave-address-book/MiscBase.sol';
import {AaveV3Base} from 'aave-address-book/AaveV3Base.sol';
import {MiscAvalanche} from 'aave-address-book/MiscAvalanche.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveV3Avalanche.sol';

import {DeploySupplyCapAgent} from './AaveSupplyCapAgent.s.sol';
import {DeployBorrowCapAgent} from './AaveBorrowCapAgent.s.sol';
import {DeployDiscountRateAgent} from './AaveDiscountRateAgent.s.sol';
import {DeployEModeAgent} from './AaveEModeAgent.s.sol';
import {DeployRatesAgent} from './AaveRatesAgent.s.sol';
import {DeployCapoAgent} from './AaveCapoAgent.s.sol';

// make deploy-ledger contract=scripts/Deploy.s.sol:DeployEthereum chain=mainnet
contract DeployEthereum is EthereumScript {
  function run() external broadcast {
    DeployDiscountRateAgent.deploy(
      MiscEthereum.AGENT_HUB,
      MiscEthereum.RANGE_VALIDATION_MODULE,
      '_Core',
      address(AaveV3Ethereum.POOL),
      address(AaveV3Ethereum.ORACLE)
    );
    DeployEModeAgent.deploy(
      MiscEthereum.AGENT_HUB,
      MiscEthereum.RANGE_VALIDATION_MODULE,
      '_Core',
      address(AaveV3Ethereum.POOL)
    );

    // core
    DeployRatesAgent.deploy(
      MiscEthereum.AGENT_HUB,
      MiscEthereum.RANGE_VALIDATION_MODULE,
      '_Core',
      address(AaveV3Ethereum.POOL)
    );
    // prime
    DeployRatesAgent.deploy(
      MiscEthereum.AGENT_HUB,
      MiscEthereum.RANGE_VALIDATION_MODULE,
      '_Prime',
      address(AaveV3EthereumLido.POOL)
    );

    // core
    DeployCapoAgent.deploy(
      MiscEthereum.AGENT_HUB,
      MiscEthereum.RANGE_VALIDATION_MODULE,
      '_Core',
      address(AaveV3Ethereum.POOL),
      address(AaveV3Ethereum.ORACLE)
    );
  }
}

// make deploy-ledger contract=scripts/Deploy.s.sol:DeployArbitrum chain=arbitrum
contract DeployArbitrum is ArbitrumScript {
  function run() external broadcast {
    DeploySupplyCapAgent.deploy(
      MiscArbitrum.AGENT_HUB,
      MiscArbitrum.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Arbitrum.POOL)
    );
    DeployBorrowCapAgent.deploy(
      MiscArbitrum.AGENT_HUB,
      MiscArbitrum.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Arbitrum.POOL)
    );

    DeployRatesAgent.deploy(
      MiscArbitrum.AGENT_HUB,
      MiscArbitrum.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Arbitrum.POOL)
    );
  }
}

// make deploy-ledger contract=scripts/Deploy.s.sol:DeployAvalanche chain=avalanche
contract DeployAvalanche is AvalancheScript {
  function run() external broadcast {
    DeploySupplyCapAgent.deploy(
      MiscAvalanche.AGENT_HUB,
      MiscAvalanche.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Avalanche.POOL)
    );
    DeployBorrowCapAgent.deploy(
      MiscAvalanche.AGENT_HUB,
      MiscAvalanche.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Avalanche.POOL)
    );

    DeployRatesAgent.deploy(
      MiscAvalanche.AGENT_HUB,
      MiscAvalanche.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Avalanche.POOL)
    );
  }
}

// make deploy-ledger contract=scripts/Deploy.s.sol:DeployBase chain=base
contract DeployBase is BaseScript {
  function run() external broadcast {
    DeploySupplyCapAgent.deploy(
      MiscBase.AGENT_HUB,
      MiscBase.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Base.POOL)
    );
    DeployBorrowCapAgent.deploy(
      MiscBase.AGENT_HUB,
      MiscBase.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Base.POOL)
    );
    DeployRatesAgent.deploy(
      MiscBase.AGENT_HUB,
      MiscBase.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Base.POOL)
    );
  }
}

// make deploy-ledger contract=scripts/Deploy.s.sol:DeployBNB chain=bnb
contract DeployBNB is BNBScript {
  function run() external broadcast {
    DeploySupplyCapAgent.deploy(
      MiscBNB.AGENT_HUB,
      MiscBNB.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3BNB.POOL)
    );
    DeployBorrowCapAgent.deploy(
      MiscBNB.AGENT_HUB,
      MiscBNB.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3BNB.POOL)
    );
  }
}

// make deploy-ledger contract=scripts/Deploy.s.sol:DeployGnosis chain=gnosis
contract DeployGnosis is GnosisScript {
  function run() external broadcast {
    DeploySupplyCapAgent.deploy(
      MiscGnosis.AGENT_HUB,
      MiscGnosis.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Gnosis.POOL)
    );
    DeployBorrowCapAgent.deploy(
      MiscGnosis.AGENT_HUB,
      MiscGnosis.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Gnosis.POOL)
    );
  }
}

// make deploy-ledger contract=scripts/Deploy.s.sol:DeployOptimism chain=optimism
contract DeployOptimism is OptimismScript {
  function run() external broadcast {
    DeploySupplyCapAgent.deploy(
      MiscOptimism.AGENT_HUB,
      MiscOptimism.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Optimism.POOL)
    );
    DeployBorrowCapAgent.deploy(
      MiscOptimism.AGENT_HUB,
      MiscOptimism.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Optimism.POOL)
    );
  }
}

// make deploy-ledger contract=scripts/Deploy.s.sol:DeployPolygon chain=polygon
contract DeployPolygon is PolygonScript {
  function run() external broadcast {
    DeploySupplyCapAgent.deploy(
      MiscPolygon.AGENT_HUB,
      MiscPolygon.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Polygon.POOL)
    );
    DeployBorrowCapAgent.deploy(
      MiscPolygon.AGENT_HUB,
      MiscPolygon.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Polygon.POOL)
    );
  }
}

// make deploy-ledger contract=scripts/Deploy.s.sol:DeployPlasma chain=plasma
contract DeployPlasma is PlasmaScript {
  function run() external broadcast {
    DeployDiscountRateAgent.deploy(
      MiscPlasma.AGENT_HUB,
      MiscPlasma.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Plasma.POOL),
      address(AaveV3Plasma.ORACLE)
    );
    DeployEModeAgent.deploy(
      MiscPlasma.AGENT_HUB,
      MiscPlasma.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Plasma.POOL)
    );
  }
}

// make deploy-ledger contract=scripts/Deploy.s.sol:DeployLinea chain=linea
contract DeployLinea is LineaScript {
  function run() external broadcast {
    DeployRatesAgent.deploy(
      MiscLinea.AGENT_HUB,
      MiscLinea.RANGE_VALIDATION_MODULE,
      '',
      address(AaveV3Linea.POOL)
    );
  }
}
