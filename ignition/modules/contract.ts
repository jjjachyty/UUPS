import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import '@openzeppelin/hardhat-upgrades' from "@openzeppelin/hardhat-upgrades";
  

const VTMarkets = buildModule("VTMarkets", (m) => {
  const z = m.contract("VTMarkets", [], {
  });

  return { z };
});

export default VTMarkets;