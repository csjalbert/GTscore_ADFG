@echo off

copy ..\..\Software\GTscore_1.3\GTscore_WindowsRunner.ps1 %CD% >NUL

powershell.exe -ExecutionPolicy Bypass ./GTscore_WindowsRunner.ps1
