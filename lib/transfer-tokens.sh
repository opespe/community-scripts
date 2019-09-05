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

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
. $SCRIPTPATH/eos-functions.sh

# Create wallet and load genesis/eosio private key
echo "Setting up wallet"
setup_wallet > /dev/null
import_private_key $KEY > /dev/null
echo "Wallet setup complete!"
echo ""

# Wait for Nodeos to be ready
echo "Waiting for Nodeos to be ready"
wait_nodeos_ready
echo "Nodeos is ready!"
echo ""

# Check if accounts exist
echo "Checking if account exist"
check_account $SENDER
check_account $RECIPIENT
echo "Accounts exist! Continuing..."
echo ""

# Get SENDERS current TOKEN balance
sender_balance=$($ecmd get currency balance eosio.token $SENDER $TOKEN)
[[ -n "$sender_balance" ]] || sender_balance="0 $TOKEN"

# Get RECIPIENTS current TOKEN balance
recipient_balance=$($ecmd get currency balance eosio.token $RECIPIENT $TOKEN)
[[ -n "$recipient_balance" ]] || recipient_balance="0 $TOKEN"

# Display values
echo "Transaction Details:"
echo ""
echo "----------------------------------------------"
echo ""
echo "NODEOS Endpoint: $NODEOS_ADDR"
echo ""
echo "Sender Account: $SENDER"
echo "Sender's Current Balance: $sender_balance"
echo ""
echo "Recipient Account: $RECIPIENT"
echo "Recipient's Current Balance: $recipient_balance"
echo ""
echo "Amount to transfer: $AMOUNT $TOKEN"
echo ""
echo "----------------------------------------------"
echo ""

# Confirmation Message
read -r -p "Is the above information correct? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    echo "Transfer information confirmed. Continuing..."
    echo ""
else
    echo "Transfer aborted. Exiting..."
    exit 1
fi

# Make the transfer
echo "Executing transation."
$ecmd transfer $SENDER $RECIPIENT "$AMOUNT $TOKEN"
echo "Transaction successfully sent!"
