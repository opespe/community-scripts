# community-scripts

Repository for community scripts

## Scripts

* **claimfunds.sh** - Script to help with claiming CN, AN, and IN PE rewards.
* **claimfunds.ps1** - Windows PowerShell equivalent of `claimfunds.sh`.
* **createcn.sh** - Script to create new CNs via the CN Onboarding contract.
* **transfer-tokens.sh** - Script to help with transferring tokens from one account to another.
* **transfer-tokens.ps1** - Windows PowerShell equivalent of `transfer-tokens.sh`.

## Requirements

You will need the following software to run the scripts found in this repository.

* Bash or PowerShell
* Docker

> **NOTE:** Scripts in this repository will pull down the `opespe/infranode` Docker image from Docker Hub to gain access to the `cleos` command. It will also attempt to mount the root of this repository inside the container when it runs.

## Usage

For each script in this repository you can run it with the `-h` option to learn about the usage of that particular script.

For example:

##### Linux
```
./claimfunds.sh -h
```

##### PowerShell
```
.\claimfunds.ps1 -h
```

## Troubleshooting

### File cannot be loaded because running scripts is disabled on this system

When running the PowerShell version of the scripts found in this repo, you may initially run into the following error.

```
.\claimfunds.ps1 : File claimfunds.ps1 cannot be loaded because running scripts is disabled on this system. For more information, see about_Execution_policies at https://go.microsoft.com/fwlink/?LinkID=135170
```

The reason this error appears is because of PowerShell's default security settings around running PowerShell scripts. You can read more at the link provided in the [error message](https://go.microsoft.com/fwlink/?LinkID=135170).

To loosen the security settings for the current PowerShell session run the following command.

```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
```

> **NOTE:** This command only applies to the current PowerShell session. If you close it and reopen, you'll have to run the above command again. To permanently change the setting so you don't have to run the above command every time, change the scope to `CurrentUser` like so `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force`.

Now you should be able to rerun the desired script without getting the error.
