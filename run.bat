npx hardhat test --network testnet
npx hardhat run --network mainnet .\deploy\deploy.js 
npx hardhat run --network testnet ./deploy/NBB_Token.js

$env:http_proxy="http://127.0.0.1:1082"
$env:https_proxy="http://127.0.0.1:1082"
@REM set http_proxy=http://127.0.0.1:1082  https_proxy=http://127.0.0.1:1082

ganache-cli -f https://bsc-dataseed1.ninicoin.io  -e 10000 --account="0x6a31bdd20acb7d510d9cd9f3f30064dc90700efd0c991533e2b60bfc5816786f,100000000000000000000000" -h 0.0.0.0 -p 8545
ganache-cli -f https://bsctestapi.terminet.io/rpc -e 10000 --account="0x6a31bdd20acb7d510d9cd9f3f30064dc90700efd0c991533e2b60bfc5816786f,100000000000000000000000" -h 0.0.0.0 -p 8545
	

https://bsctestapi.terminet.io/rpc	