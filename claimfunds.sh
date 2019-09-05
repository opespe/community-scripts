#!/bin/bash
set -e

usage="A script for claiming reward funds.

Usage:
    $(basename "$0") [-h] -a|--account <account name> -k|--key <private key> [-t|--type <reward type>] [-e|--endpoint <api endpoint hostname>] [-q|--quiet]

Where:
    -h                Show this help text
    -a, --account     (Required) - The block chain account you want to claim funds for.
    -k, --key         (Required) - Private key of account claiming funds.
    -t, --type        (Optional) - The type of rewards to claim. Options are cn, an, and in. Defaults to 'cn'.
    -e, --endpoint    (Optional) - The Nodeos API endpoint to run commands against. Defaults to 'pub-infra.opesx.io'.
    -q, --quiet       (Optional) - If provided, script does not prompt for confirmation before attempting to claim funds.

Note:
    You can use the following environment variables instead of providing command line options. Environment variables will override command line args if both are specified for a setting.
        - CF_ACCOUNT
        - CF_KEY
        - CF_TYPE
        - CF_ENDPOINT
"

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -h|--help)
      echo "$usage"
      exit      
      ;;
    -a|--account)
      CF_ACCOUNT=${CF_ACCOUNT:-$2}
      shift 2
      ;;
    -k|--key)
      CF_KEY=${CF_KEY:-$2}
      shift 2
      ;;
    -t|--type)
      CF_TYPE=${CF_TYPE:-$2}
      shift 2
      ;;
    -e|--endpoint)
      CF_ENDPOINT=${CF_ENDPOINT:-$2}
      shift 2
      ;;
    -q|--quiet)
      CF_QUIET="true"
      shift 1
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
CF_ENDPOINT=${CF_ENDPOINT:-pub-infra.opesx.io}
CF_TYPE=${CF_TYPE:-cn}
CF_QUIET=${CF_QUIET:-"False"}
[[ -n "$CF_TYPE" ]] && CF_TYPE=$(echo $CF_TYPE | tr '[:upper:]' '[:lower:]')
if [[ -z "$CF_ACCOUNT" ]] && [[ "$CF_QUIET" == "False" ]];then
    read -r -p "Block Chain Account Name: " CF_ACCOUNT
fi
if [[ -z "$CF_KEY" ]] && [[ "$CF_QUIET" == "False" ]];then
    read -rs -p "Account Private Key: " CF_KEY
    echo ""
fi

# Input Validation
[[ -n "$CF_ACCOUNT" ]] || end "ERROR: Account name not specified."
[[ -n "$CF_KEY" ]] || end "ERROR: Private key not specified."
[[ $CF_TYPE =~ ^cn$|^an$|^in$ ]] || end "ERROR: Invalid reward type: $CF_TYPE"

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
docker pull opespe/infranode:$DOCKER_TAG
docker run --rm -it -v $SCRIPTPATH:/src \
    -e NODEOS_ADDR=$CF_ENDPOINT \
    -e CF_ACCOUNT=$CF_ACCOUNT \
    -e CF_KEY=$CF_KEY \
    -e CF_TYPE=$CF_TYPE \
    -e CF_QUIET=$CF_QUIET \
    --entrypoint bash opespe/infranode:$DOCKER_TAG /src/lib/claimfunds.sh