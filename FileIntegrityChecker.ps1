#Written by Piletji Mautjana
#12/20/2021

#ABOUT: A basic file integrity script that continuously monitors a specified folder for any deletions and additions of new files as well as changes to existing files every second.
$continue = $true
while($continue)
{
Write-Host ""
Write-Host "Choose what you want to do:"
Write-Host ""
Write-Host "1) Collect new baseline"
Write-Host "2) Monitor files with saved baseline"

$response = Read-Host -Prompt "Please enter 1 or 2"
#function that hashes files with SHA512
Function Calculate-File-Hash($filepath){
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}
Function Erase-Baseline-If-Already-Exists($filepath) {
    $baselineExists = Test-Path -Path $filepath
    if ($baselineExists){
        Remove-Item -Path .\baseline.txt
    }
}
Function File-Paths-And-Hashes($filepath){
    $filePathsAndHashes = Get-Content -Path .\baseline.txt
    
    foreach ($f in $filePathsAndHashes) {
        #all filepaths in array[0] and hashes in array[1]
        $fileHashDictionary.add($f.Split("|")[0],$f.Split("|")[1])
    }
}
Function Checking-Files($filepath){
    $files = Get-ChildItem -Path $filepath
    #for each file, calculate hash, write to baseline.txt in current directory
    foreach($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }
}
Function Check-Deleted {
    foreach($key in $fileHashDictionary.Keys){
        $baselineFileStillExists = Test-Path -Path $key
        if(-Not $baselineFileStillExists){
            #One of the baseline files has been deleted, tell the user
            Write-Host "$($key) has been deleted!" -ForegroundColor Magenta
            Write-Host ""
        }
    }
}
Function Monitor-Active($filepath) {
    Write-Host "Checking if files match..."
    while($true){
        Start-Sleep -Seconds 1
        $files = Get-ChildItem -Path "$filepath"
        foreach ($f in $files){
            $hash = Calculate-File-Hash $f.FullName
            if ($fileHashDictionary[$hash.Path] -eq $null) {
                #A new file has been added
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
                Write-Host ""
            }
            else{
                if ($fileHashDictionary[$hash.Path] -eq $hash.Hash){
                #file is unchanged
                }
                else{
                #file hash is different and has been changed
                    Write-Host "$($hash.Path) has been changed!" -ForegroundColor Red
                    Write-Host ""
                }
            }
        }
        Check-Deleted
    }
}

if ($response -eq '1') {
    $fileinput = Read-Host "Specify a directory of text files: "
    #delete baseline if it's already there
    Erase-Baseline-If-Already-Exists($fileinput)
    #calculate hash and store in baseline.txt
    #collect all files in target folder (files_to_check)
    Calculate-File-Hash($fileinput)
    #for each file, calculate hash, write to baseline.txt in current directory
    Checking-Files($fileinput)

}
elseif ($response -eq '2') {
    
    Write-Host ""
    Write-Host "Starting Process..."
    Write-Host ""
    Start-Sleep -Seconds 1

    #create empty dictionary
    $fileHashDictionary = @{}

    #Load file and hash from baseline.txt and store them in a dictionary
    File-Paths-And-Hashes($fileinput)
    
    #Data Structure that represents the original files continuously compared to files to check for changes
    Monitor-Active($fileinput)

    #begin monitoring files with saved baseline
    #Write-Host "Read existing baseline.txt, start monitoring files" -ForegroundColor Yellow
    }
}