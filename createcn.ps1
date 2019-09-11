param(
    [string]$Referrercn,
    [string]$Key,
    [string]$Referrerpn,
    [string]$Name,
    [string]$Url,
    [string]$Owner,
    [string]$Active,
    [string]$an,
    [string]$in,
    [string]$Endpoint = "pub-infra.opesx.io",
    [switch]$h
)

$ErrorActionPreference = "Stop"

$usage = "A script for creating new CNs.

Usage:
    createcn.ps1 [-h] -Referrercn <referrer cn name> -Key <private key> -Referrerpn <referrer pn name> -Name <new cn name> -Url <cn info url>
        -Owner <owner public key> -Active <active public key> -an <an worker public key> -in <in worker public key> [-Endpoint <api endpoint hostname>]

Where:
    -h                Show this help text
    -Referrercn       (Required) - The block chain account name of the referring/creator community node (CN).
    -Key              (Required) - Private key of referring/creator CN account. Used to pay for CN creation via CNONBRD tokens.
    -Referrerpn       (Required) - The block chain account name of the referring personal node (PN).
    -Name             (Required) - Block chain account name of the new CN.
    -Url              (Required) - The URL of the new CN's info endpoint.
    -Owner            (Required) - The new CN's Owner Public Key
    -Active           (Required) - The new CN's Active Public Key
    -an               (Required) - The new CN's AN Worker Public Key
    -in               (Required) - The new CN's IN Worker Public Key
    -Endpoint         (Optional) - The Nodeos API endpoint to run commands against. Defaults to 'pub-infra.opesx.io'.

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

if ($h) {
    Write-Host $usage
    exit 0
}

# Set Docker input variables
$DOCKER_TAG = "latest"

# Referrer CN
if ($env:CC_REFERRERCN) {
    $CC_REFERRERCN = $env:CC_REFERRERCN
} else {
    if ($Referrercn) {
        $CC_REFERRERCN = $Referrercn
    } else {
        $CC_REFERRERCN = Read-Host -Prompt "Referrer CN Block Chain Account Name"
    }
}

# Referrer CN Private Key
if ($env:CC_KEY) {
    $CC_KEY = $env:CC_KEY
} else {
    if ($Key) {
        $CC_KEY = $Key
    } else {
        $EncryptedKey = Read-Host -Prompt "Referrer CN Account's Private Key" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($EncryptedKey)
        $CC_KEY = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }
}

# Referrer PN
if ($env:CC_REFERRERPN) {
    $CC_REFERRERPN = $env:CC_REFERRERPN
} else {
    if ($Referrerpn) {
        $CC_REFERRERPN = $Referrerpn
    } else {
        $CC_REFERRERPN = Read-Host -Prompt "Referrer PN Block Chain Account Name"
    }
}

# New CN Name
if ($env:CC_NAME) {
    $CC_NAME = $env:CC_NAME
} else {
    if ($Name) {
        $CC_NAME = $Name
    } else {
        $CC_NAME = Read-Host -Prompt "New CN's Block Chain Account Name"
    }
}

# New CN Info Endpoint URL
if ($env:CC_URL) {
    $CC_URL = $env:CC_URL
} else {
    if ($Url) {
        $CC_URL = $Url
    } else {
        $CC_URL = Read-Host -Prompt "New CN's info endpoint URL"
    }
}

# New CN Owner Public Key
if ($env:CC_OWNER) {
    $CC_OWNER = $env:CC_OWNER
} else {
    if ($Owner) {
        $CC_OWNER = $Owner
    } else {
        $CC_OWNER = Read-Host -Prompt "New CN's Owner Public Key"
    }
}

# New CN Active Public Key
if ($env:CC_ACTIVE) {
    $CC_ACTIVE = $env:CC_ACTIVE
} else {
    if ($Active) {
        $CC_ACTIVE = $Active
    } else {
        $CC_ACTIVE = Read-Host -Prompt "New CN's Active Public Key"
    }
}

# New CN AN Worker Key
if ($env:CC_AN) {
    $CC_AN = $env:CC_AN
} else {
    if ($an) {
        $CC_AN = $an
    } else {
        $CC_AN = Read-Host -Prompt "New CN's AN Worker Public Key"
    }
}

# New CN IN Worker Key
if ($env:CC_IN) {
    $CC_IN = $env:CC_IN
} else {
    if ($in) {
        $CC_IN = $in
    } else {
        $CC_IN = Read-Host -Prompt "New CN's IN Worker Public Key"
    }
}

# Nodeos API Endpoint
if ($env:CC_ENDPOINT) {
    $CC_ENDPOINT = $env:CC_ENDPOINT
} else {
    $CC_ENDPOINT = $Endpoint
}

# Input Validation
function stop-script ($msg) {
    Write-Host "$msg"
    Write-Host ""
    Write-Host "$usage"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($CC_REFERRERCN)) { stop-script "ERROR: Referrer CN's block chain account name not specified." }
if ([string]::IsNullOrWhiteSpace($CC_KEY)) { stop-script "ERROR: Referrer CN's private key not specified." }
if ([string]::IsNullOrWhiteSpace($CC_REFERRERPN)) { stop-script "ERROR: Referrer PN's block chain account name not specified." }
if ([string]::IsNullOrWhiteSpace($CC_NAME)) { stop-script "ERROR: New CN's block chain account name not specified." }
if ([string]::IsNullOrWhiteSpace($CC_URL)) { stop-script "ERROR: New CN's info endpoint URL not specified." }
if ($CC_URL -notmatch "^https://|^http://") { stop-script "ERROR: CN's info endpoint URL does not start with HTTP or HTTPS." }
if ([string]::IsNullOrWhiteSpace($CC_OWNER)) { stop-script "ERROR: New CN's owner public key not specified." }
if ([string]::IsNullOrWhiteSpace($CC_ACTIVE)) { stop-script "ERROR: New CN's active public key not specified." }
if ([string]::IsNullOrWhiteSpace($CC_AN)) { stop-script "ERROR: New CN's AN worker public key not specified." }
if ([string]::IsNullOrWhiteSpace($CC_IN)) { stop-script "ERROR: New CN's IN worker public key not specified." }

# Transform OPES to EOS for public keys
if ($CC_OWNER -match "^OPES") {
  $CC_OWNER = $CC_OWNER -replace "^OPES","EOS"
}
if ($CC_ACTIVE -match "^OPES") {
  $CC_ACTIVE=$CC_ACTIVE -replace "^OPES","EOS"
}
if ($CC_AN -match "^OPES") {
  $CC_AN=$CC_AN -replace "^OPES","EOS"
}
if ($CC_IN -match "^OPES") {
  $CC_IN=$CC_IN -replace "^OPES","EOS"
}

$SCRIPTPATH = "/" + ${PSScriptRoot}.Split(":")[0].tolower() + ${PSScriptRoot}.Split(":")[1].Replace("\","/")
docker pull opespe/infranode:$DOCKER_TAG
docker run --rm -it -v "${SCRIPTPATH}:/src" -e NODEOS_ADDR=$CC_ENDPOINT -e REFERRER_CN=$CC_REFERRERCN -e REFERRER_CN_PRIVKEY=$CC_KEY -e REFERRER_PN=$CC_REFERRERPN -e CN_NAME=$CC_NAME -e CN_URL=$CC_URL -e CN_OWNER_PUB_KEY=$CC_OWNER -e CN_ACTIVE_PUB_KEY=$CC_ACTIVE -e AN_WORKER_PUB_KEY=$CC_AN -e IN_WORKER_PUB_KEY=$CC_IN --entrypoint bash opespe/infranode:$DOCKER_TAG /src/lib/createcn.sh