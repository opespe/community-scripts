#!/bin/bash
set -e

usage="A simple script for transfering tokens between accounts

Usage:
    $(basename "$0") [-h] -s|--sender <sender account> -k|--key <sender private key> -r|--recipient <recipient account> -a|--amount <amount to send> [-t|--token <token symbol>] [-e|--endpoint <api endpoint hostname>]

Where:
    -h                Show this help text
    -s, --sender      (Required) - The blockchain account that will send then tokens.
    -k, --key         (Required) - The sending account's private key.
    -r, --recipient   (Required) - The blockchain account that will be receiving the tokens from the sending account.
    -a, --amount      (Required) - The amount of tokens to send/transfer.
    -t, --token       (Optional) - The symbol for the token you wish to send. Defaults to 'PE'.
    -e, --endpoint    (Optional) - The Nodeos API endpoint to run commands against. Defaults to 'pub-infra.opesx.io'.

Note:
    You can use the following environment variables instead of providing command line options. Environment variables will override command line args if both are specified for a setting.
        - TT_SENDER
        - TT_KEY
        - TT_RECIPIENT
        - TT_AMOUNT
        - TT_TOKEN
        - TT_ENDPOINT
"

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -h|--help)
      echo "$usage"
      exit      
      ;;
    -s|--sender)
      TT_SENDER=${TT_SENDER:-$2}
      shift 2
      ;;
    -k|--key)
      TT_KEY=${TT_KEY:-$2}
      shift 2
      ;;
    -r|--recipient)
      TT_RECIPIENT=${TT_RECIPIENT:-$2}
      shift 2
      ;;
    -a|--amount)
      TT_AMOUNT=${TT_AMOUNT:-$2}
      shift 2
      ;;
    -t|--token)
      TT_TOKEN=${TT_TOKEN:-$2}
      shift 2
      ;;
    -e|--endpoint)
      TT_ENDPOINT=${TT_ENDPOINT:-$2}
      shift 2
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

end () {
    echo >&2 "$@"
    echo ""
    echo "$usage"
    exit 1
}

# Set Docker input variables
DOCKER_TAG=latest
TT_ENDPOINT=${TT_ENDPOINT:-pub-infra.opesx.io}
TT_TOKEN=${TT_TOKEN:-PE}
if [[ -z "$TT_SENDER" ]];then
    read -r -p "Sender Account Name: " TT_SENDER
fi
if [[ -z "$TT_KEY" ]];then
    read -rs -p "Sending Account's Private Key: " TT_KEY
    echo ""
fi
if [[ -z "$TT_RECIPIENT" ]];then
    read -r -p "Recipient Account Name: " TT_RECIPIENT
fi
if [[ -z "$TT_AMOUNT" ]];then
    read -r -p "Amount of $TT_TOKEN to send: " TT_AMOUNT
fi

# Input Validation
[[ -n "$TT_SENDER" ]] || end "ERROR: Sending account not specified."
[[ -n "$TT_RECIPIENT" ]] || end "ERROR: Receiving account not specified."
[[ -n "$TT_AMOUNT" ]] || end "ERROR: Amount not specified."
[[ -n "$TT_KEY" ]] || end "ERROR: Sender's private key not specified."

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
docker pull opespe/infranode:$DOCKER_TAG
docker run --rm -it -v $SCRIPTPATH:/src \
    -e NODEOS_ADDR=$TT_ENDPOINT \
    -e SENDER=$TT_SENDER \
    -e KEY=$TT_KEY \
    -e RECIPIENT=$TT_RECIPIENT \
    -e AMOUNT=$TT_AMOUNT \
    -e TOKEN=$TT_TOKEN \
    --entrypoint bash opespe/infranode:$DOCKER_TAG /src/lib/transfer-tokens.sh