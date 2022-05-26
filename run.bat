npx hardhat test --network testnet
npx hardhat run --network mainnet .\deploy\deploy.js 
$env:http_proxy="http://127.0.0.1:1082"
$env:https_proxy="http://127.0.0.1:1082"
@REM set http_proxy=http://127.0.0.1:1082  https_proxy=http://127.0.0.1:1082