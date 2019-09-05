param(
    [string]$Sender,
    [string]$Key,
    [string]$Recipient,
    [string]$Amount,
    [string]$Token = "PE",
    [string]$Endpoint = "pub-infra.opesx.io",
    [switch]$h
)

$ErrorActionPreference = "Stop"

$usage = "A simple script for transfering tokens between accounts

Usage:
    transfer-tokens.ps1 [-h] -Sender <sender account> -Key <sender private key> -Recipient <recipient account> -Amount <amount to send> [-Token <token symbol>] [-Endpoint <api endpoint hostname>]

Where:
    -h                Show this help text
    -Sender           (Required) - The blockchain account that will send then tokens.
    -Key              (Required) - The sending account's private key.
    -Recipient        (Required) - The blockchain account that will be receiving the tokens from the sending account.
    -Amount           (Required) - The amount of tokens to send/transfer.
    -Token            (Optional) - The symbol for the token you wish to send. Defaults to 'PE'.
    -Endpoint         (Optional) - The Nodeos API endpoint to run commands against. Defaults to 'pub-infra.opesx.io'.

Note:
    You can use the following environment variables instead of providing command line options. Environment variables will override command line args if both are specified for a setting.
        - TT_SENDER
        - TT_KEY
        - TT_RECIPIENT
        - TT_AMOUNT
        - TT_TOKEN
        - TT_ENDPOINT
"

if ($h) {
    Write-Host $usage
    exit 0
}

# Set Docker input variables
$DOCKER_TAG = "latest"
if ($env:TT_SENDER) {
    $TT_SENDER = $env:TT_SENDER
} else {
    if ($Sender) {
        $TT_SENDER = $Sender
    } else {
        $TT_SENDER = Read-Host -Prompt "Sender Account Name"
    }
}
if ($env:TT_KEY) {
    $TT_KEY = $env:TT_KEY
} else {
    if ($Key) {
        $TT_KEY = $Key
    } else {
        $EncryptedKey = Read-Host -Prompt "Sending Account's Private Key" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($EncryptedKey)
        $TT_KEY = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }
}
if ($env:TT_RECIPIENT) {
    $TT_RECIPIENT = $env:TT_RECIPIENT
} else {
    if ($Recipient) {
        $TT_RECIPIENT = $Recipient
    } else {
        $TT_RECIPIENT = Read-Host -Prompt "Recipient Account Name"
    }
}
if ($env:TT_TOKEN) {
    $TT_TOKEN = $env:TT_TOKEN
} else {
    $TT_TOKEN = $Token
}
if ($env:TT_AMOUNT) {
    $TT_AMOUNT = $env:TT_AMOUNT
} else {
    if ($Amount) {
        $TT_AMOUNT = $Amount
    } else {
        $TT_AMOUNT = Read-Host -Prompt "Amount of $TT_TOKEN to send"
    }
}
if ($TT_AMOUNT -notmatch "^[0-9]*$|^[0-9]+\.[0-9]{1,4}$") {
    Write-Error "Invalid amount. Max percision is 4 decimal places and amounts less than 0 must provide the 0 in front of the decimal."
}
if ($env:TT_ENDPOINT) {
    $TT_ENDPOINT = $env:TT_ENDPOINT
} else {
    $TT_ENDPOINT = $Endpoint
}

$SCRIPTPATH = "/" + ${PSScriptRoot}.Split(":")[0].tolower() + ${PSScriptRoot}.Split(":")[1].Replace("\","/")
docker pull opespe/infranode:$DOCKER_TAG
docker run --rm -it -v "${SCRIPTPATH}:/src" -e NODEOS_ADDR=$TT_ENDPOINT -e SENDER=$TT_SENDER -e KEY=$TT_KEY -e RECIPIENT=$TT_RECIPIENT -e AMOUNT=$TT_AMOUNT -e TOKEN=$TT_TOKEN --entrypoint bash opespe/infranode:$DOCKER_TAG /src/lib/transfer-tokens.sh