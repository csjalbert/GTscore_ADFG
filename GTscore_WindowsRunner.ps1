#--------------------------------------------------------------------------------
#GTscore_WindowsRunner.ps1
#
#Input:
#	This script is fully automated but requies a few yes/no questions to be answered.
#	However, the bcl dir, barcodes (samplesheet), and panel file must be present in the working directory. 
#
#Usage:
#	This script is automated, after answering a few yes/no questions.
#	It is executed by running winRun_GTscore.bat from the project directory, after confirming 
# 	the bcl directory, samplesheet, and probe file is present in the project directory.
#	
#
#Chase Jalbert
#Alaska Department of Fish and Game
#chase.jalbert@alaska.gov
#	04/13/2022
#--------------------------------------------------------------------------------

#find bcl, samplesheet, and panel
$bcl = Get-ChildItem -Path ./ | Where-Object{ $_.PSIsContainer }| Where-Object {$_.Name -like '*_NB501*'} | Foreach-Object {$_.Name} 
$sampleSheet = Get-ChildItem -Path ./ | Where-Object {$_.Extension -eq '.csv'} | Where-Object {$_.Name -like '*SampleSheet*'} | Foreach-Object {$_.Name}
$panel = Get-ChildItem -Path ./ | Where-Object {$_.Extension -eq '.txt'} | Foreach-Object {$_.Name}
$wdir = Get-Location | Convert-Path | ForEach-Object{$_ -replace ".*Illumina_DROPOFF\\","/mnt/anc_gen_cifs_research/Illumina_DROPOFF/"} 
$projectID = Get-Location | Split-Path -leaf | ForEach-Object{$_ -replace "_",""}

#check if project with same name is already running. If so, do not start as this will lead to issues.
if (Test-Path -Path ($projectID + '.screenlog') -PathType leaf) {
Write-Output "Looks like $projectID is already running!`nYou may need to Foward your problem up the Chain of Command!`nExiting..."
Start-Sleep -s 5
Exit
}

#get username and password for sbs user
$user= Get-ChildItem -Path ..\..\Software\GTscore_1.3\ | Where-Object {$_.Extension -eq '.sbsinfo'} | ForEach-Object {Get-Content $_.FullName} | Select-Object -Index 0
$passwd= Get-ChildItem -Path ..\..\Software\GTscore_1.3\ | Where-Object {$_.Extension -eq '.sbsinfo'} | ForEach-Object {Get-Content $_.FullName} | Select-Object -Index 1

#setting up logging for screen command
$configfile = ($projectID + '.config')
$configtext = ("logfile " + $projectID + ".screenlog`r`nlogfile flush 1`r`nlog on")
$configtext | Out-String -Stream | Out-File $configfile -Encoding ASCII

## Ask the first question
#$question1 = New-Object -TypeName System.Windows.Forms.MessageBox
#$question1Buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo
#$question1Icon = [System.Windows.Forms.MessageBoxIcon]::Question
#$question1Result = $question1::Show("Are you using the IDFG299 panel?", "Confirmation", $question1Buttons, $question1Icon)

#if ($question1Result -eq "Yes") {
#    # User selected Yes
#    $rescoreMessage = "Please tell Chase and Jodi that this needs to be manually rescored!"
#    $rescoreTitle = "Rescore Confirmation"
    
#    # Show a message box with the rescore message
#    $rescoreBox = New-Object -TypeName System.Windows.Forms.MessageBox
#    $rescoreBox::Show($rescoreMessage, $rescoreTitle, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
#}

## Ask the second question
#$question2 = New-Object -TypeName System.Windows.Forms.MessageBox
#$question2Buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo
#$question2Icon = [System.Windows.Forms.MessageBoxIcon]::Question
#$question2Result = $question2::Show("Are you using the ADFG_Coho_WDFW_331 or Sockeye_CRITFC_340 panel?", "Confirmation", $question2Buttons, $question2Icon)

## Convert the user's input to a boolean value
#$correctrescore = $question2Result -eq "Yes"


#run pipeline
echo y | plink.exe $user -pw $passwd "cd $wdir; perl -pi -e 's/\r\n/\n/g' $configfile; screen -l -c $configfile -dmSL $projectID bash /mnt/anc_gen_cifs_research/Software/GTscore_1.3/run_GTscore.sh $bcl $sampleSheet $panel"
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
Write-Host -NoNewLine 'If you are using the IDFG299 panel, let Heather and Chase know the project needs to be rescored prior to importing data... Press any key to close window.'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
