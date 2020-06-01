#
# bootstrap our template, make sure we 
# local copies of nuget, etc.
#
$log = "$PSScriptRoot\setup.log";
$error.Clear();

# get nuget.exe (cache for four days)
Write-Host "# Checking for nuget.exe"

$cache = 4
$nuget = "$PSScriptRoot\nuget.exe"
$source = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"

if ((test-path $nuget) -and ((Get-ChildItem $nuget).CreationTime -lt [DateTime]::Now.AddDays(-$cache)))
{
    Remove-Item $nuget -force -errorAction SilentlyContinue > $null
}
if (-not (test-path $nuget))
{
    Write-Host "Download Nuget..."
    Invoke-WebRequest $source -OutFile $nuget
    if (-not $?) { throw "Failed to download nuget" }
}

# check node 
npm -v >> $log 2>&1
if (-not $?) { throw "failed to report npm version" }

# clean npm cache
npm cache clean --force >> $log 2>&1
$error.Clear()

Write-Host "# Installing node packages"
npm install ".." >> $log 2>&1
Write-Output ">> $? $($error.Count)" >> $log 2>&1
# Don't really care about the messages from npm install making us think there are errors
$error.Clear()
