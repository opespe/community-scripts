param(
    [Parameter(Mandatory)]
    [string]$Account,
    [Parameter(Mandatory)]
    [string]$Key,
    [string]$Type = "cn",
    [string]$Endpoint = "pub-infra.opesx.io",
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

# Set Docker input variables
$DOCKER_TAG = "latest"
$CF_ACCOUNT = $Account
$CF_ENDPOINT = $Endpoint
$CF_KEY = $Key
$CF_TYPE = $Type.tolower()
if ($Quiet) {
    $CF_QUIET = "True"
} Else {
    $CF_QUIET = "False"
}

# Validate input
if ($CF_TYPE -notmatch "^cn$|^an$|^in$") {
    Write-Error "Invalid reward type: $CF_TYPE"
}

$SCRIPTPATH = "/" + ${PSScriptRoot}.Split(":")[0].tolower() + ${PSScriptRoot}.Split(":")[1].Replace("\","/")
echo $SCRIPTPATH
docker pull opespe/infranode:$DOCKER_TAG
docker run --rm -it -v "${SCRIPTPATH}:/src" -e NODEOS_ADDR=$CF_ENDPOINT -e CF_ACCOUNT=$CF_ACCOUNT -e CF_KEY=$CF_KEY -e CF_TYPE=$CF_TYPE -e CF_QUIET=$CF_QUIET --entrypoint bash opespe/infranode:$DOCKER_TAG /src/lib/claimfunds.sh