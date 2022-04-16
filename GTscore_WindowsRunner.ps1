#--------------------------------------------------------------------------------
#GTscore_WindowsRunner.ps1
#
#Input:
#	This script is fully automated and requires no user input. However, the bcl dir, barcodes (samplesheet),
#	and panel file must be present in the working directory. 
#
#Usage:
#	This script is fully automated and is executed by running winRun_GTscore.bat.
#
#
#Chase Jalbert
#Alaska Department of Fish and Game
#chase.jalbert@alaska.gov
#	04/13/2022
#--------------------------------------------------------------------------------

#find bcl, samplesheet, and panel
$bcl = Get-ChildItem -Path ./ | ?{ $_.PSIsContainer }| Where-Object {$_.Name -like '*_NB501*'} | Foreach-Object {$_.Name} 
$sampleSheet = Get-ChildItem -Path ./ | Where-Object {$_.Extension -eq '.csv'} | Where-Object {$_.Name -like '*SampleSheet*'} | Foreach-Object {$_.Name}
$panel = Get-ChildItem -Path ./ | Where-Object {$_.Extension -eq '.txt'} | Foreach-Object {$_.Name}
$wdir = pwd | Convert-Path | %{$_ -replace ".*Illumina_DROPOFF\\","/mnt/anc_gen_cifs_research/Illumina_DROPOFF/"} 
$projectID = pwd | Split-Path -leaf | %{$_ -replace "_",""}

#check if project with same name is already running. If so, do not start as this will lead to issues.
if (Test-Path -Path ($projectID + '.screenlog') -PathType leaf) {
Write-Output "Looks like $projectID is already running!`nYou may need to Foward your problem up the Chain of Command!`nExiting..."
Start-Sleep -s 5
Exit
}

#get username and password for sbs user
$usr= Get-ChildItem -Path ..\..\Software\GTscore_1.3\ | Where-Object {$_.Extension -eq '.sbsinfo'} | ForEach-Object {Get-Content $_.FullName} | Select -Index 0
$pwd= Get-ChildItem -Path ..\..\Software\GTscore_1.3\ | Where-Object {$_.Extension -eq '.sbsinfo'} | ForEach-Object {Get-Content $_.FullName} | Select -Index 1

#setting up logging for screen command
$configfile = ($projectID + '.config')
$configtext = ("logfile " + $projectID + ".screenlog`r`nlogfile flush 1`r`nlog on")
$configtext | Out-String -Stream | Out-File $configfile -Encoding ASCII

#run pipeline
echo y | plink.exe $usr -pw $pwd "cd $wdir; perl -pi -e 's/\r\n/\n/g' $configfile; screen -l -c $configfile -dmSL $projectID bash /mnt/anc_gen_cifs_research/Software/GTscore_1.3/run_GTscore.sh $bcl $sampleSheet $panel"
Write-Output "Attempting to start $projectID run...`n"
Start-Sleep  -s 5

#make sure project is running and alert user to failure
if (Test-Path -Path "nohup.out" -PathType leaf) {
	Write-Output "$projectID is running!`n"
	} Else {
	Write-Output "$projectID failed to run.`n"
	Remove-Item ($projectID + '.config')
	Remove-Item ($projectID + ".screenlog")
	Remove-Item GTscore_WindowsRunner.ps1
	Write-Output "`nEnsure you have the SampleSheet.csv and Panel.txt in this directory, then try again if you please.`n"
}
Write-Host -NoNewLine 'Press any key to close window.'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
