<#  Setup script for Subscription Server for Security Events and reporting

from https://aka.ms/jessica @jepayneMSFT with some help from Kurt Falde @kurt_falde

#>

<#WEFFLES is currently hard coded to a directory, this is because of the need to have it be a fast and failproof solution for IR situations. 
You can change the directory by chasing all the variables, and in the future there may be a version that allows more flexibility. But I errored on the side of "make sure it works, as often as possible" since often times IR situations lead you to tired people and tired infrastructure. #>
mkdir c:\weffles
copy *.* c:\weffles
cd C:\weffles

<#If you don't want to manually create a WEF GPO following the instructions at https://aka.ms/weffles you can use this to create a GPO in the domain from the backup version provided in the weffles zip file - this will create a GPO which is NOT linked to anything, so you can link to test OUs and test the 
rollout without deploying all at once. If you uncomment this line and chose to do that versus creating the GPO manually, the script will need to be run with an account that has permissions
to create GPOs in the domain, and you will need to have the AD module available on the box. You might just take this command and the GUID/GPO folder and run them stand alone on a GPO 
editor's machine prior to doing the rest of the script. The GPO this is referencing is provided in the F9763831-99BB-4F8D-B145-022D7EB719F9.zip file in the GitHub repo. After creation tou will need to edit the server name to the FQDN of your collector server. #>

#Import-GPO -BackupGPOName "WEF GPO" -TargetName "Windows Event Forwarding GPO" -CreateIfNeeded -Path "C:\weffles\"

#Setting WinRM Service to automatic start and running quickconfig
Set-Service -Name winrm -StartupType Automatic
winrm quickconfig -quiet

<#Set the size of the forwarded events log to 1GB, as we'll be saving them off to .csv
you can set this bigger if you want, but remember the main performance bottleneck of WEF is the log size - you need enough memory to hold the log +5GB or so for normal OS functions
so if had a reason to make this 10GB of log, you'll need to add 10GB RAM to the base amount in your VM #>
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

#Set the Windows Event Collector Service to start type automatic, it's automatic with delayed start by default, which is fine as that lets the dependencies churn in. 
#it is also annoying though, as sometimes you spend a good 5+ minutes thinking WEFFLES isn't working. Be patient. :)
Set-Service -Name Wecsvc -StartupType "Automatic"

#reboot
#Restart-Computer