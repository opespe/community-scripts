NODEOS_URL=http://${NODEOS_ADDR}

wallet_host=127.0.0.1:8899
wdurl=http://${wallet_host}

ecmd="cleos --wallet-url ${wdurl} --url ${NODEOS_URL}"
wcmd="cleos --wallet-url ${wdurl} wallet"

function wait_wallet_ready {
  for (( i=0 ; i<10; i++ )); do
    ! $wcmd list 2>/tmp/wallet.txt || [ -s /tmp/wallets.txt ] || break
    sleep 3
  done
}

function wait_nodeos_ready {
  for (( i=0 ; i<10; i++ )); do
    ! $ecmd get info || break
    sleep 3
  done
}

function import_private_key {
  local privkey=$1
  $wcmd import -n ignition --private-key $privkey | sed 's/[^:]*: //'
}

function setup_wallet {
  kill_wallet
  rm -rf ${HOME}/eosio-wallet
  keosd --http-server-address ${wallet_host} >/tmp/keosd.log 2>&1 &
  wait_wallet_ready
  $wcmd create --to-console -n ignition
}

function kill_wallet {
    # Kill keosd
    pkill keosd || :
}