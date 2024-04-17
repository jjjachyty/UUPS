import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const JAN_1ST_2030 = 1893456000;
const ONE_GWEI: bigint = 1_000_000_000n;

const BT2 = buildModule("LockModule", (m) => {
  // const unlockTime = m.getParameter("unlockTime", JAN_1ST_2030);
  // const lockedAmount = m.getParameter("lockedAmount", ONE_GWEI);

  const bt2 = m.contract("BT2", [], {
    // value: lockedAmount,
  });

  return { bt2 };
});

export default BT2;