##############################################
#find bcl, samplesheet, and panel
$bcl = Get-ChildItem -Path ./ | ?{ $_.PSIsContainer }| Where-Object {$_.Name -like '*_NB501*'} | Foreach-Object {$_.Name} 
$sampleSheet = Get-ChildItem -Path ./ | Where-Object {$_.Extension -eq '.csv'} | Where-Object {$_.Name -like '*SampleSheet*'} | Foreach-Object {$_.Name}
$panel = Get-ChildItem -Path ./ | Where-Object {$_.Extension -eq '.txt'} | Foreach-Object {$_.Name}
$wdir = pwd | Convert-Path | %{$_ -replace ".*Illumina_DROPOFF\\","/mnt/anc_gen_cifs_research/Illumina_DROPOFF/"} 
$projectID = pwd | Split-Path -leaf | %{$_ -replace "_",""}


if (Test-Path -Path ($projectID + '.screenlog') -PathType leaf) {
Write-Output "Looks like $projectID is already running!`nYou may need to Foward your problem up the Chain of Command!`nExiting..."
Start-Sleep -s 5
Exit
}

$usr= Get-ChildItem -Path ..\..\Software\GTscore_1.3\ | Where-Object {$_.Extension -eq '.sbsinfo'} | ForEach-Object {Get-Content $_.FullName} | Select -Index 0
$pwd= Get-ChildItem -Path ..\..\Software\GTscore_1.3\ | Where-Object {$_.Extension -eq '.sbsinfo'} | ForEach-Object {Get-Content $_.FullName} | Select -Index 1

$configfile = ($projectID + '.config')
$configtext = ("logfile " + $projectID + ".screenlog`r`nlogfile flush 1`r`nlog on")
$configtext | Out-String -Stream | Out-File $configfile -Encoding ASCII

# run pipeline
echo y | plink.exe $usr -pw $pwd "cd $wdir; perl -pi -e 's/\r\n/\n/g' $configfile; screen -l -c $configfile -dmSL $projectID bash /mnt/anc_gen_cifs_research/Software/GTscore_1.3/run_GTscore.sh $bcl $sampleSheet $panel"
Write-Output "Attempting to start $projectID run...`n"
Start-Sleep  -s 5


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
