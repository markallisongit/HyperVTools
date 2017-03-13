# Download and install HyperVTools
# Method 1: Scripted installer from GitHub
Install the master branch

```Invoke-Expression (Invoke-WebRequest https://raw.githubusercontent.com/markallisongit/HyperVTools/master/install.ps1)```

Install the dev branch (unstable)

```Invoke-Expression (Invoke-WebRequest https://raw.githubusercontent.com/markallisongit/HyperVTools/develop/install.ps1)```

This will install HyperVTools locally for the current user to Documents\WindowsPowerShell\Modules folder. 

# Method 2: Download the zip and manually import the module
```
Invoke-WebRequest https://github.com/markallisongit/HyperVTools/archive/master.zip -OutFile HyperVTools.zip
Expand-Archive HyperVTools.zip -DestinationPath .
Import-Module .\HyperVTools\HyperVTools.psd1
```

