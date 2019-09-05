param(
    [string]$Account,
    [string]$Key,
    [string]$Type = "cn",
    [string]$Endpoint = "pub-infra.opesx.io",
    [switch]$Quiet,
    [switch]$h
)

$ErrorActionPreference = "Stop"

$usage = "A script for claiming reward funds.

Usage:
    claimfunds.ps1 [-h] -Account <account name> -Key <private key> [-Type <reward type>] [-Endpoint <api endpoint hostname>] [-Quiet]

Where:
    -h                Show this help text
    -Account          (Required) - The block chain account you want to claim funds for.
    -Key              (Required) - Private key of account claiming funds.
    -Type             (Optional) - The type of rewards to claim. Options are cn, an, and in. Defaults to 'cn'.
    -Endpoint         (Optional) - The Nodeos API endpoint to run commands against. Defaults to 'pub-infra.opesx.io'.
    -Quiet            (Optional) - If provided, script does not prompt for confirmation before attempting to claim funds.

Note:
    You can use the following environment variables instead of providing command line options. Environment variables will override command line args if both are specified for a setting.
        - CF_ACCOUNT
        - CF_KEY
        - CF_TYPE
        - CF_ENDPOINT
"

if ($h) {
    Write-Host $usage
    exit 0
}

# Set Docker input variables
$DOCKER_TAG = "latest"
if ($env:CF_ACCOUNT) {
    $CF_ACCOUNT = $env:CF_ACCOUNT
} else {
    if ($Account) {
        $CF_ACCOUNT = $Account
    } else {
        $CF_ACCOUNT = Read-Host -Prompt "Block Chain Account Name"
    }
}
if ($env:CF_KEY) {
    $CF_KEY = $env:CF_KEY
} else {
    if ($Key) {
        $CF_KEY = $Key
    } else {
        $EncryptedKey = Read-Host -Prompt "Account Private Key" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($EncryptedKey)
        $CF_KEY = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }
}
if ($env:CF_ENDPOINT) {
    $CF_ENDPOINT = $env:CF_ENDPOINT
} else {
    $CF_ENDPOINT = $Endpoint
}
if ($env:CF_TYPE) {
    $CF_TYPE = $env:CF_TYPE.tolower()
} else {
    $CF_TYPE = $Type.tolower()
}
if ($Quiet -or $env:CF_QUIET -eq "True") {
    $CF_QUIET = "True"
} else {
    $CF_QUIET = "False"
}

# Validate input
if ($CF_TYPE -notmatch "^cn$|^an$|^in$") {
    Write-Error "Invalid reward type: $CF_TYPE"
}

$SCRIPTPATH = "/" + ${PSScriptRoot}.Split(":")[0].tolower() + ${PSScriptRoot}.Split(":")[1].Replace("\","/")
docker pull opespe/infranode:$DOCKER_TAG
docker run --rm -it -v "${SCRIPTPATH}:/src" -e NODEOS_ADDR=$CF_ENDPOINT -e CF_ACCOUNT=$CF_ACCOUNT -e CF_KEY=$CF_KEY -e CF_TYPE=$CF_TYPE -e CF_QUIET=$CF_QUIET --entrypoint bash opespe/infranode:$DOCKER_TAG /src/lib/claimfunds.sh