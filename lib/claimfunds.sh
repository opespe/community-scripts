#!/bin/bash
set -e

function check_account {
    if [[ $($ecmd get account $1 2>/dev/null) ]]; then
        echo "Account $1 exists. Proceeding..."
    else
        echo "Account $1 does not exist. Aborting..."
        exit 1
    fi
}

function get_reward_balance {
    account=$1
    type=$2
    case "$type" in
        cn)
            table=o1cnodes
            account_type=community_node
            ;;
        an)
            table=o1anodes
            account_type=access_node
            ;;
        in)
            table=o1inodes
            account_type=infrastructure_node
            ;;
    esac
    rewards=$($ecmd get table -L $account -l 50 eosio eosio $table | jq -r ".rows[] | select (.${account_type} == \"$account\") | .to_pay")
    echo "$rewards"
}

CLAIMFUNDS_PRIVKEY=5JoVPeTasDKTpkKy4Cb3eBEmANS4vczAHyBVr9NUuXcnYENmKHB

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
. $SCRIPTPATH/eos-functions.sh

# Create wallet and load private keys
echo "Setting up wallet"
setup_wallet > /dev/null
import_private_key $CLAIMFUNDS_PRIVKEY > /dev/null
import_private_key $CF_KEY > /dev/null
echo "Wallet setup complete!"
echo ""

# Wait for Nodeos to be ready
echo "Waiting for Nodeos to be ready"
wait_nodeos_ready
echo "Nodeos is ready!"
echo ""

# Check if accounts exist
echo "Checking if account exist"
check_account $CF_ACCOUNT
echo "Accounts exist! Continuing..."
echo ""

# Get accounts current PE balance
current_balance=$($ecmd get currency balance eosio.token $CF_ACCOUNT PE)
[[ -n "$current_balance" ]] || current_balance="0 PE"

# Get reward balance
reward_balance=$(get_reward_balance $CF_ACCOUNT $CF_TYPE)
[[ -n "$reward_balance" ]] || reward_balance="Unknown"

# Display values
echo "Details:"
echo ""
echo "----------------------------------------------"
echo ""
echo "NODEOS Endpoint: $NODEOS_ADDR"
echo ""
echo "Account: $CF_ACCOUNT"
echo "Current PE Balance: $current_balance"
echo ""
echo "Reward Type to Claim: $CF_TYPE"
echo "Current Reward Balance: $reward_balance"
echo ""
echo "----------------------------------------------"
echo ""

if [[ "$CF_QUIET" == "False" ]];then
    # Confirmation Message
    read -r -p "Is the above information correct? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        echo "Details confirmed. Continuing..."
        echo ""
    else
        echo "Claiming funds aborted. Exiting..."
        exit 1
    fi
fi

# Submit claimfunds action
echo "Sending action to claim funds."
$ecmd push action eosio claimfunds "{\"kind\":\"$CF_TYPE\", \"nodename\":\"$CF_ACCOUNT\"}" -p $CF_ACCOUNT@active eosio@claimfunds

# Give transaction some time to complete
echo "Giving transaction time to finish."
sleep 5

# Check new balance
new_balance=$($ecmd get currency balance eosio.token $CF_ACCOUNT PE)
[[ -n "$new_balance" ]] || new_balance="0 PE"

# Display new balance
echo "Your new balance is $new_balance."