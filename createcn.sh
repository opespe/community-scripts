#!/bin/bash
set -e

usage="A script for creating new CNs.

Usage:
    $(basename "$0") [-h] -c|--referrercn <referrer cn name> -k|--key <private key> -p|--referrerpn <referrer pn name> -n|--name <new cn name> -u|--url <cn info url>
        -o|--owner <owner public key> -a|--active <active public key> --an <an worker public key> --in <in worker public key> [-e|--endpoint <api endpoint hostname>]

Where:
    -h                Show this help text
    -c, --referrercn  (Required) - The block chain account name of the referring/creator community node (CN).
    -k, --key         (Required) - Private key of referring/creator CN account. Used to pay for CN creation via CNONBRD tokens.
    -p, --referrerpn  (Required) - The block chain account name of the referring personal node (PN).
    -n, --name        (Required) - Block chain account name of the new CN.
    -u, --url         (Required) - The URL of the new CN's info endpoint.
    -o, --owner       (Required) - The new CN's Owner Public Key
    -a, --active      (Required) - The new CN's Active Public Key
    --an              (Required) - The new CN's AN Worker Public Key
    --in              (Required) - The new CN's IN Worker Public Key
    -e, --endpoint    (Optional) - The Nodeos API endpoint to run commands against. Defaults to 'pub-infra.opesx.io'.

Note:
    You can use the following environment variables instead of providing command line options. Environment variables will override command line args if both are specified for a setting.
        - CC_REFERRERCN
        - CC_KEY
        - CC_REFERRERPN
        - CC_NAME
        - CC_URL
        - CC_OWNER
        - CC_ACTIVE
        - CC_AN
        - CC_IN
        - CC_ENDPOINT
"

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -h|--help)
      echo "$usage"
      exit      
      ;;
    -c|--referrercn)
      CC_REFERRERCN=${CC_REFERRERCN:-$2}
      shift 2
      ;;
    -k|--key)
      CC_KEY=${CC_KEY:-$2}
      shift 2
      ;;
    -p|--referrerpn)
      CC_REFERRERPN=${CC_REFERRERPN:-$2}
      shift 2
      ;;
    -n|--name)
      CC_NAME=${CC_NAME:-$2}
      shift 2
      ;;
    -u|--url)
      CC_URL=${CC_URL:-$2}
      shift 2
      ;;
    -o|--owner)
      CC_OWNER=${CC_OWNER:-$2}
      shift 2
      ;;
    -a|--active)
      CC_ACTIVE=${CC_ACTIVE:-$2}
      shift 2
      ;;
    --an)
      CC_AN=${CC_AN:-$2}
      shift 2
      ;;
    --in)
      CC_IN=${CC_IN:-$2}
      shift 2
      ;;
    -e|--endpoint)
      CC_ENDPOINT=${CC_ENDPOINT:-$2}
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
CC_ENDPOINT=${CC_ENDPOINT:-pub-infra.opesx.io}
if [[ -z "$CC_REFERRERCN" ]];then
    read -r -p "Referrer CN Block Chain Account Name: " CC_REFERRERCN
fi
if [[ -z "$CC_KEY" ]];then
    read -rs -p "Referrer CN Account's Private Key: " CC_KEY
    echo ""
fi
if [[ -z "$CC_REFERRERPN" ]];then
    read -r -p "Referrer PN Block Chain Account Name: " CC_REFERRERPN
fi
if [[ -z "$CC_NAME" ]];then
    read -r -p "New CN's Block Chain Account Name: " CC_NAME
fi
if [[ -z "$CC_URL" ]];then
    read -r -p "New CN's info endpoint URL: " CC_URL
fi
if [[ -z "$CC_OWNER" ]];then
    read -r -p "New CN's Owner Public Key: " CC_OWNER
fi
if [[ -z "$CC_ACTIVE" ]];then
    read -r -p "New CN's Active Public Key: " CC_ACTIVE
fi
if [[ -z "$CC_AN" ]];then
    read -r -p "New CN's AN Worker Public Key: " CC_AN
fi
if [[ -z "$CC_IN" ]];then
    read -r -p "New CN's IN Worker Public Key: " CC_IN
fi

# Input Validation
[[ -n "$CC_REFERRERCN" ]] || end "ERROR: Referrer CN's block chain account name not specified."
[[ -n "$CC_KEY" ]] || end "ERROR: Referrer CN's private key not specified."
[[ -n "$CC_REFERRERPN" ]] || end "ERROR: Referrer PN's block chain account name not specified."
[[ -n "$CC_NAME" ]] || end "ERROR: New CN's block chain account name not specified."
[[ -n "$CC_URL" ]] || end "ERROR: New CN's info endpoint URL not specified."
[[ $CC_URL =~ ^https://|^http:// ]] || end "ERROR: CN's info endpoint URL does not start with HTTP or HTTPS."
[[ -n "$CC_OWNER" ]] || end "ERROR: New CN's owner public key not specified."
[[ -n "$CC_ACTIVE" ]] || end "ERROR: New CN's active public key not specified."
[[ -n "$CC_AN" ]] || end "ERROR: New CN's AN worker public key not specified."
[[ -n "$CC_IN" ]] || end "ERROR: New CN's IN worker public key not specified."

# Transform OPES to EOS for public keys
if [[ "$CC_OWNER" =~ ^OPES ]]; then
  CC_OWNER=$(echo $CC_OWNER | sed 's/^OPES/EOS/')
fi
if [[ "$CC_ACTIVE" =~ ^OPES ]]; then
  CC_ACTIVE=$(echo $CC_ACTIVE | sed 's/^OPES/EOS/')
fi
if [[ "$CC_AN" =~ ^OPES ]]; then
  CC_AN=$(echo $CC_AN | sed 's/^OPES/EOS/')
fi
if [[ "$CC_IN" =~ ^OPES ]]; then
  CC_IN=$(echo $CC_IN | sed 's/^OPES/EOS/')
fi

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
docker pull opespe/infranode:$DOCKER_TAG
docker run --rm -it -v $SCRIPTPATH:/src \
    -e NODEOS_ADDR=$CC_ENDPOINT \
    -e REFERRER_CN=$CC_REFERRERCN \
    -e REFERRER_CN_PRIVKEY=$CC_KEY \
    -e REFERRER_PN=$CC_REFERRERPN \
    -e CN_NAME=$CC_NAME \
    -e CN_URL=$CC_URL \
    -e CN_OWNER_PUB_KEY=$CC_OWNER \
    -e CN_ACTIVE_PUB_KEY=$CC_ACTIVE \
    -e AN_WORKER_PUB_KEY=$CC_AN \
    -e IN_WORKER_PUB_KEY=$CC_IN \
    --entrypoint bash opespe/infranode:$DOCKER_TAG /src/lib/createcn.sh