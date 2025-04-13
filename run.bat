npx hardhat clean
npx hardhat compile
npx hardhat flatten contracts/Foo.sol > Flattened.sol


npx hardhat test --network testnet
npx hardhat run --network mainnet .\deploy\deploy.js 
npx hardhat run --network testnet ./deploy/NBB_Token.js
npx hardhat verify --network mainnet 0xC2ad3C2d23a5104317c7d60AD7bc2C2DA9b2dfe6 
npx hardhat verify --network testnet --contract "contracts/FoMox.sol:FoMox" 0xce90294Ec41dF39092E2155f7cC6745b0E7De2D5
npx hardhat run --network testnet ./scripts/verifyContracts.ts
npx hardhat run --network testnet ./scripts/verifyManually.ts


$env:http_proxy="http://127.0.0.1:1082"
$env:https_proxy="http://127.0.0.1:1082"
@REM set http_proxy=http://127.0.0.1:1082  https_proxy=http://127.0.0.1:1082

ganache-cli   -e 10000 --account="0x6a31bdd20acb7d510d9cd9f3f30064dc90700efd0c991533e2b60bfc5816786f,100000000000000000000000" -h 0.0.0.0 -p 8545
ganache-cli  -e 10000 --account="0x6a31bdd20acb7d510d9cd9f3f30064dc90700efd0c991533e2b60bfc5816786f,100000000000000000000000" --gasPrice 2000000000 --gasLimit 30000000 --callGasLimit 50000000 --chainId 1337 --hardfork shanghai -h 0.0.0.0 -p 8545 
docker run --detach --name ganache vegaprotocol/ganache:latest --publish 8545:8545 -e 10000 --account="0x6a31bdd20acb7d510d9cd9f3f30064dc90700efd0c991533e2b60bfc5816786f,100000000000000000000000" -h 0.0.0.0 -p 8545

https://bsctestapi.terminet.io/rpc	



npx hardhat ignition deploy ./ignition/modules/BT2.ts --network testnet 
npx hardhat  verify --network mainnet 0xA7FCdae2d8dB37a3E45e615F4f901F78De279A79
ganache-cli -e 10000 --account="0x6a31bdd20acb7d510d9cd9f3f30064dc90700efd0c991533e2b60bfc5816786f,100000000000000000000000" -h 0.0.0.0 -p 8545
