<#  Setup script for Subscription Server for Security Events and reporting

from https://aka.ms/jessica @jepayneMSFT with some help from Kurt Falde @kurt_falde

#>

mkdir c:\weffles
copy *.* c:\weffles
cd C:\weffles

<#Create a GPO in the domain from the backup version provided in the weffles zip file - this will create a GPO which is NOT linked to anything, so you can link to test OUs and test the 
rollout without deploying all at once. If you uncomment this line and chose to do that versus creating the GPO manually, the script will need to be run with an account that has permissions
to create GPOs in the domain. #>
#
#Import-GPO -BackupGPOName "WEF GPO" -TargetName "Windows Event Forwarding GPO" -CreateIfNeeded -Path "C:\weffles\"

#Setting WinRM Service to automatic start and running quickconfig
Set-Service -Name winrm -StartupType Automatic
winrm quickconfig -quiet

#Set the size of the forwarded events log to 1GB, as we'll be saving them off to .csv
wevtutil sl forwardedevents /ms:1000000000


#Running quickconfig for subscription service
wecutil qc -quiet


#If you need to export any existing subscriptions, or want to export a subscription made via the gui to get SDDLs of domains
#use wecutil gs "%subscriptionname%" /f:xml >>"C:\Temp\%subscriptionname%.xml"

#Import the core subscriptions, if you edited the "Interesting Accounts" example, uncomment that, and if you have Defender as your AV, uncomment the MalwareEvents 
#wecutil cs "InterestingAccounts.xml"
#wecutil cs "MalwareEvents.xml"
wecutil cs "coreevents.xml"

#Creating Task Scheduler Item to restart parsing script on reboot of system.
schtasks.exe /create /tn "WEF Parsing Task" /xml WEFFLESParsingTask.xml

#Set the Windows Event Collector Service to start type automatic
Set-Service -Name Wecsvc -StartupType Automatic

#reboot
Restart-Computer