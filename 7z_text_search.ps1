# 2024-12-06
# Author: Chris Holt
# This script will search for a keyword inside text files that are in 7z archives. It will recursively search the entire folder tree provided. 
# Setup and Use:
#   1. `winget install 7z`
#   2. Add the 7zip folder into your PATH variable.
#   3. Ensure the policy is enable to allow powershell scripts to run `Set-ExecutionPolicy -ExecutionPolicy Bypass`
#   4. Run and supply optional parameters
#       `.\7z_text_search.ps1 -LogDir "C:\logs\7z_text_search" -Keyword "Discover" -SearchFolders "D:\TOYO - 2024-11-13", "D:\TOYO - 2024-11-19", "D:\TOYO - 2024-11-25", "D:\TOYO - 2024-12-2"`

param (
    [string]$LogDir = "C:\logs\7z_text_search",
    [string]$Keyword,
    [string[]]$SearchFolders
)

# Validate parameters
if (-Not $Keyword) {
    Write-Error "Keyword must be supplied."
    exit
}

if (-Not $SearchFolders) {
    Write-Error "At least one search folder must be supplied."
    exit
}

# Temporary directory to extract files
$tempDir = "$env:TEMP\7zExtract"

# Ensure the log directory exists
if (-Not (Test-Path -Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force
}

# Log file name with keyword and timestamp
$timestampStart = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = "$LogDir\SearchLog_$Keyword_$timestampStart.txt"

# Ensure the log file exists
if (-Not (Test-Path -Path $logFile)) {
    New-Item -ItemType File -Path $logFile -Force
}

# Write initial log description
Add-Content -Path $logFile -Value "7z Text Search Tool by Chris Holt"
Add-Content -Path $logFile -Value "================"
Add-Content -Path $logFile -Value "Keyword Searched For: $Keyword"
Add-Content -Path $logFile -Value "Search Started At: $timestampStart"
Add-Content -Path $logFile -Value "Folders Searched:"
$SearchFolders | ForEach-Object { Add-Content -Path $logFile -Value $_ }
Add-Content -Path $logFile -Value "================"
Add-Content -Path $logFile -Value ""

# Function to search for the keyword in extracted files
function Search-KeywordInFiles {
    param (
        [string[]]$folders,
        [string]$keyword
    )

    $filesContainingKeyword = @()

    # Process each folder
    foreach ($folder in $folders) {
        # Extract all 7z files to the temporary directory
        Get-ChildItem -Path $folder -Filter "*.7z" | ForEach-Object {
            $file = $_.FullName
            $arguments = "x `"$file`" -o`"$tempDir`" -y"
            Start-Process "7z" -ArgumentList $arguments -NoNewWindow -Wait

            # Search for the keyword in all text files
            $containsKeyword = $false
            Get-ChildItem -Path $tempDir -Recurse -Filter "*.txt" | ForEach-Object {
                $content = Get-Content -Path $_.FullName
                foreach ($line in $content) {
                    if ($line -match $keyword) {
                        $containsKeyword = $true
                        Write-Output $file
                        Add-Content -Path $logFile -Value $file
                        Add-Content -Path $logFile -Value "    $line"
                    }
                }
            }

            # Clean up temporary directory for the next archive
            Remove-Item -Path "$tempDir\*" -Recurse -Force
        }
    }

    return $filesContainingKeyword
}

# Run the search and output the results
$filesWithKeyword = Search-KeywordInFiles -folders $SearchFolders -keyword $Keyword

# Print summary results and add the completion timestamp to the log file
$timestampEnd = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
if ($filesWithKeyword.Count -gt 0) {
    Write-Output "Files containing the keyword '$Keyword':"
    $filesWithKeyword | ForEach-Object { Write-Output $_ }
} else {
    Write-Output "No files found containing the keyword '$Keyword'."
    Add-Content -Path $logFile -Value "No files found containing the keyword '$Keyword'."
}

Add-Content -Path $logFile -Value ""
Add-Content -Path $logFile -Value "Search Completed At: $timestampEnd"
