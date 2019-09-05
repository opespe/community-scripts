# community-scripts

Repository for community scripts

## Scripts

* **claimfunds.sh** - Script to help with claiming CN, AN, and IN PE rewards.
* **createcn.sh** - Script to create new CNs via the CN Onboarding contract.

## Requirements

You will need the following software to run the scripts found in this repository.

* Bash or PowerShell
* Docker

> **NOTE:** Scripts in this repository will pull down the `opespe/infranode` Docker image from Docker Hub to gain access to the `cleos` command. It will also attempt to mount the root of this repository inside the container when it runs.

## Usage

For each script in this repository you can run it with the `-h` option to learn about the usage of that particular script.

For example:

```
./claimfunds.sh -h
```