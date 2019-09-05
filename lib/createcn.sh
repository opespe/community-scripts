#!/bin/bash
set -e

function check_account {
    if [[ $($ecmd get account $1 2>/dev/null) ]]; then
        echo "ERROR: Account $1 already exists. Aborting..."
        exit 1
    else
        echo "Account $1 does not exist. Proceeding..."
    fi
}

function check_referrer_account {
    if [[ $($ecmd get account $1 2>/dev/null) ]]; then
        echo "Referrer account $1 exists. Proceeding..."
    else
        echo "ERROR: Referrer account $1 does not exist. Aborting..."
        exit 1
    fi
}

function verify_account {
    if [[ $($ecmd get account $1 2>/dev/null) ]]; then
        echo "Account $1 created successfully!"
    else
        echo "ERROR: Unable to find account $1. Account creation failed."
        kill_wallet
        exit 1
    fi
}

function verify_table_entry {
    account=$1
    table=$2
    case "$table" in
        o1cnodes)
            account_type=community_node
            ;;
        o1anodes|o1ankeys)
            account_type=access_node
            ;;
        o1inodes)
            account_type=infrastructure_node
            ;;
        producers)
            account_type=owner
            ;;
        *)
            echo "ERROR: Incorrect table name specified. Unable to verify table entry."
            kill_wallet
            exit 1
    esac
    if [[ $($ecmd get table -L $account -l 50 eosio eosio $table | jq -r ".rows[] | select (.${account_type} == \"$account\")") ]]; then
        echo "New account $account was successfully registered in $table table."
    else
        echo "ERROR: New account $account was not found in the $table table."
    fi
}

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
. $SCRIPTPATH/eos-functions.sh

# Get accounts current CNONBRD balance
current_balance=$($ecmd get currency balance eosio.token $REFERRER_CN CNONBRD)
[[ -n "$current_balance" ]] || current_balance="0 CNONBRD"
balance_int=$(echo $current_balance | awk '{ print $1 }')

# Display values
echo "----------------------------------------------"
echo ""
echo "NODEOS Endpoint: $NODEOS_ADDR"
echo ""
echo "New CN Name: $CN_NAME"
echo "New CN URL: $CN_URL"
echo "New CN Owner Public Key: $CN_OWNER_PUB_KEY"
echo "New CN Active Public Key: $CN_ACTIVE_PUB_KEY"
echo "New CN AN Worker Public Key: $AN_WORKER_PUB_KEY"
echo "New IN Worker Public Key: $IN_WORKER_PUB_KEY"
echo ""
echo "Referrer CN: $REFERRER_CN"
echo "Referrer PN: $REFERRER_PN"
echo ""
echo "Current CNONBRD Token Balance: $current_balance"
echo ""
echo "This transaction will cost 1 CNONBRD token"
echo ""
echo "----------------------------------------------"
echo ""

if [[ ! $balance_int > 0 ]];then
    echo "ERROR: You do not currently have enough CNONBRD tokens to create a CN. Aborting."
    exit 1
fi

# Confirmation Message
read -r -p "Is the above information correct? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    echo "CN information confirmed. Continuing..."
    echo ""
else
    echo "CN creation aborted. Exiting..."
    exit 1
fi

# Wait for Nodeos to be ready
echo "Waiting for Nodeos to be ready"
wait_nodeos_ready
echo "Nodeos is ready!"
echo ""

# Check if accounts exist already
echo "Checking if account name exists already"
check_account $CN_NAME
echo "Account names are available! Continuing..."
echo ""

# Checking if referrer accounts exist
echo "Checking if referrer account exist"
check_referrer_account $REFERRER_CN
check_referrer_account $REFERRER_PN
echo "Referrer accounts exist! Continuing..."
echo ""

# Create wallet and load genesis/eosio private key
echo "Setting up wallet"
setup_wallet > /dev/null
import_private_key $REFERRER_CN_PRIVKEY > /dev/null
echo "Wallet setup complete!"
echo ""

REQUEST="{
\"payment\":\"1 CNONBRD\",
\"creator\":\"$REFERRER_CN\",
\"name\":\"$CN_NAME\",
\"owner\":\"$CN_OWNER_PUB_KEY\",
\"active\":\"$CN_ACTIVE_PUB_KEY\",
\"referpn\":\"$REFERRER_PN\",
\"resourcedesc\":\"$CN_URL\",
\"producer_key\":\"$IN_WORKER_PUB_KEY\",
\"location\":0,
\"an_key\":\"$AN_WORKER_PUB_KEY\"
}"

# Create account
echo "Creating new CN account"
$ecmd push action cn.onboarder onboard "$REQUEST" -p $REFERRER_CN
echo "Transaction for new account sent."
echo ""

# Verify account was created
echo "Checking if accounts exists..."
sleep 3
echo "Querying blockchain for $CN_NAME"
verify_account $CN_NAME

# Verify the new account is in the CN, AN, IN, Producers, and AN Keys tables.
verify_table_entry $CN_NAME o1cnodes
verify_table_entry $CN_NAME o1anodes
verify_table_entry $CN_NAME o1inodes
verify_table_entry $CN_NAME producers
verify_table_entry $CN_NAME o1ankeys

# Kill keosd
kill_wallet