param(
    # Execute a command
    [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
    [string[]]
    $command
)

# Bootstrap
# Get the basic things we need for the script to work (nuget, npm)

$bs = &"$PSScriptRoot\bootstrap.ps1"
if (-not $?) { return }

#
# Setup the scripts that let us copy files
# and do post build events.
#
function Setup 
{
    Write-Host "Setup"
    Write-Host ""

    $library = Read-Host "Enter Library Name"

    $sandbox = Read-Host "Enter folder of test umbraco site"
    if (-not (test-path $sandbox))
    {
        Write-Host "Cannot find your test umbraco folder"
        return
    }

    rename-project $library

    # update-gulpscript $sandbox

    Write-Host "--- Done ---"
}

# rename the project to something you might want to call it.
function  rename-project ($libraryName) {     

    $project = Get-ChildItem "$PSScriptRoot\..\src" -recurse -filter "*.csproj" -File 
    $folder = Split-Path $project

    $solution = Get-ChildItem "$PSScriptRoot\..\src" -Recurse -Filter "*.sln" -File
    $solutionFolder = Split-Path $solution

    $currentName = Split-Path $folder -Leaf 

    Write-Host "Current" , $currentName;
    Write-Host "NewName" , $libraryName

    if ($currentName -eq $libraryName) {
        # nothing to do the project is already called this.
        return;
    }

    if (Test-Path $project) {
        Write-Host " > Updating .csproj file"
        # replace all instances of the project name in the config
        ((Get-Content $project -Raw) -replace $currentName, $libraryName) | Set-Content -Path $project
    }

    if (Test-Path $solution) {
        Write-Host " > Updating .sln file"
        # replace all instances of the project name in .sln file.
        ((Get-Content $solution -Raw) -replace $currentName, $libraryName) | Set-Content -Path $solution
    }

    # update the properties/AssemblyInfo.cs file
    $assemblyFile = "$folder/Properties/AssemblyInfo.cs"
    if (Test-Path $assemblyFile) {
        Write-Host " > Updating assemblyInfo.cs"
        ((Get-Content $assemblyFile -Raw) -replace $currentName, $libraryName) | Set-Content -Path $assemblyFile
    }

    $buildYml = "$PSScriptRoot/../.github/workflows/build.yml";
    if (Test-Path $buildYml)
    {
        Write-Host " > Updating build.yml"
        ((Get-Content $buildYml -Raw) -replace $currentName, $libraryName) | Set-Content -Path $buildYml

    }

    Write-Host " > Renaming files/folders..."
    
    # rename the *.csproj file
    Rename-Item -Path $project -NewName "$folder\$libraryName.csproj"

    # rename the soluion file ?
    Rename-Item -Path $solution -NewName "$solutionFolder\$libraryName.sln"

    # rename the nuspec file
    if (Test-Path "$folder/$currentName.nuspec") {
        Rename-Item -Path "$folder/$currentName.nuspec" -NewName "$folder/$libraryName.nuspec"
    }

    # rename the app_plugins folder
    $appPlugins = "$folder/App_Plugins/$currentName";
    if (Test-Path $appPlugins) {
        Rename-Item -Path $appPlugins -NewName "$folder/App_Plugins/$libraryName"
    }

    # rename the project folder.
    $newFolder = (Split-Path $folder) + "/" + $libraryName
    Rename-Item -Path $folder -NewName $newFolder

}

# update the gulp script paths.json - that we use for updates.
function update-gulpscript($sandboxSite) {

    Write-Host "## Updating gulp script config"

    # edit the paths.json to add this.
    $paths = "$PSScriptRoot/../paths.json";
    if (test-path $paths)
    {
        Write-Host "## Updating paths.json"

        $pathJson = Get-Content $paths | Out-String | ConvertFrom-Json
        $pathJson.site = $sandbox

        # find the projects .

        $folder = Get-ChildItem "$PSScriptRoot\..\src" -recurse -filter "*.csproj" -File | Split-Path
        $App_Plugins = "$folder/App_Plugins"
        if (test-path $App_Plugins)
        {
            $pluginfolder = Get-ChildItem $App_Plugins -Recurse -Filter "package.manifest" -File | Split-Path | Split-Path -Leaf
            $library = Split-Path $folder -Leaf

            $pathJson.library = $library
            $pathJson.pluginFolder = $pluginfolder
        }

        $pathJson | ConvertTo-Json | Out-File $paths 
    }   
}

# run the commands past to the script. 
if ($command.Length -gt 0)
{
    &$command;
}
else {
    Get-Content "$PSScriptRoot/readme.txt"
}

