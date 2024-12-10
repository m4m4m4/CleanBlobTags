# This scripts removes all blob tags from an azure blob storage container based on a tag filter in the script. It performs it in chunks of 1000. 
# Set the MaxIterations parameter to something like 500 and it will perform the cleaning for 500K files, which usually takes at least 6 hours.
# If there are no files left with the tag criteria the script will terminate

param (
    [Parameter(Position=0,mandatory=$true)]
    [string]$connectionString,
    [Parameter(Position=1,mandatory=$true)]
    [string]$containerName,
    [Parameter(Position=2,mandatory=$true)]
    [int]$maxIterations
)

# Install the Az.Storage module if not already installed
if (-not (Get-Module -ListAvailable -Name Az.Storage)) {
    Install-Module -Name Az.Storage -Force -Scope CurrentUser
}

Import-Module Az.Storage

# Connect to the Azure Storage account
$context = New-AzStorageContext -ConnectionString $connectionString

# Get the container reference
$container = Get-AzStorageContainer -Name $containerName -Context $context

$maxCount = 1000
$total     = 0
$token     = $Null
Do
{
     #Retrieve blobs using the MaxCount parameter
    $blobs = Get-AzStorageBlobByTag -Container $container.Name -Context $context -TagFilterSqlExpression """Malware Scanning scan time UTC"">'0'" -MaxCount $maxCount -ContinuationToken $token
    $blobCount = 1
    
     #Loop through the batch
     Foreach ($blob in $blobs)
     {
         Set-AzStorageBlobTag -Container $container.Name -Context $context -Blob $blob.Name -Tag @{} | out-null
         #Display progress bar
         $percent = $($blobCount/$maxCount*100)
         Write-Progress -Activity "Processing blobs" -Status "$percent% Complete" -PercentComplete $percent
         $blobCount++
     }

     #Update $total
     $total += $blobs.Count
      
     #Exit if all blobs processed
     If($blobs.Length -le 0) { Break; }
      
     #Set continuation token to retrieve the next batch
     $token = $blobs[$blobs.Count -1].ContinuationToken
     $maxIterations--
 }
 While ($null -ne $token -and $maxIterations -gt 0)
Write-Host "Processed $total blobs in $($container.Name)."
