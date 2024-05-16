import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import '@openzeppelin/hardhat-upgrades' from "@openzeppelin/hardhat-upgrades";
  

const Z = buildModule("Z", (m) => {
  const z = m.contract("Z", [], {
  });

  return { z };
});

export default Z;