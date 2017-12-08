<#  Setup script for Subscription Server for Security Events and reporting

from https://aka.ms/jessica @jepayneMSFT with some help from Kurt Falde @kurt_falde

Current version uses EventLogWatcher.psm1 from https://pseventlogwatcher.codeplex.com - although @Lee_Holmes told me BinaryFormatter was not optimal so that may change. :) 

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

<#This is where we actuall import the Windows Event Collector subscriptions, i.e. the events we're going to collect. WEFFLES intentionally is NOT gathering "all the things"
and instead we want to get targeted "known bad" or "possibly shady" events. The core events file looks for these item : 
7045 : new service creations to look for persistence 
200 and 106 : scheduled task operations, also for persistence and execution 
4720: creation of local accounts, sometimes done as a malware free backdoor 
1102: clearing the security event log (anywhere you see that is a machine that should automatically get deeper forensic analysis) 

The "InterestingAccounts.xml subscription is one I use to specifically track either high value accounts, or known compromised accounts. 
You can get laser focus on the activities you need to see, versus combing through millions of logon events to start with. 

It's also incredibly useful for solving that question of "what DOES that legacy account in Domain Admins that we're afraid to remove do?" as you get logs from both
domain controllers and workstations as well as the process and logon type - and you also get 4625 logon failed events, so you can rapidly find if something does break. #>

#Import the core subscriptions, if you edited the "Interesting Accounts" example, uncomment that, and if you have Defender as your AV, uncomment the MalwareEvents 
#wecutil cs "InterestingAccounts.xml"
#wecutil cs "MalwareEvents.xml"
wecutil cs "coreevents.xml"

#Creating Task Scheduler Item to restart parsing script on reboot of system.
schtasks.exe /create /tn "WEF Parsing Task" /xml WEFFLESParsingTask.xml

#Set the Windows Event Collector Service to start type automatic, it's automatic with delayed start by default, which is fine as that lets the dependencies churn in. 
#it is also annoying though, as sometimes you spend a good 5+ minutes thinking WEFFLES isn't working. Be patient. :)
Set-Service -Name Wecsvc -StartupType "Automatic"

<#You need to reboot now, uncomment if you want to do it automatically. After reboot let the machine cook for five minutes, and then you should see a weffles.csv in the c:\weffles
directory, and then you can use the weffles.pbix PowerBI desktop to analyze it - make sure the pbix and the csv are in a directory c:\weffles on your machine and open the .pbx and then hit refresh. #>
#Restart-Computer