#comment

$workingdir = "c:\weffles"

cd $workingdir

#The following line was needed on a 2008 R2 setup at one customer It shouldn't hurt having it here however this can be removed in some cases
Add-Type -AssemblyName System.Core

#Following added to unregister any existing watcher Event in case script has already been run
Unregister-Event weffles -ErrorAction SilentlyContinue
Remove-Job weffles -ErrorAction SilentlyContinue


Import-Module .\EventLogWatcher.psm1

#Verify Bookmark currently exists prior to setting as start point
$TestStream = $null
$ECName = (((Get-Content .\bookmark.stream)[1]) -split "'")[1]
$ERId = (((Get-Content .\bookmark.stream)[1]) -split "'")[3]
$TestStream = Get-WinEvent -LogName $ECName -FilterXPath "*[System[(EventRecordID=$ERID)]]"
If ($TestStream -eq $null) {Remove-Item .\bookmark.stream}

$BookmarkToStartFrom = Get-BookmarkToStartFrom

$EventLogQuery = New-EventLogQuery "ForwardedEvents" -Query "*[System[EventID=4964]] or *[System[EventID=4624]] or *[System[EventID=4625]] or *[System[EventID=4648]] or *[System[EventID=1102]] or *[System[EventID=7045]] or *[System[EventID=4720]] or *[System[EventID=106]]or *[System[EventID=200]]"

$EventLogWatcher = New-EventLogWatcher -EventLogQuery $EventLogQuery -BookmarkToStartFrom $BookmarkToStartFrom
# $EventLogQuery $BookmarkToStartFrom 

$action = {     
                #Following is debug line while developing as it will let you enter the nested prompt/session where you
                #can actually query the $EventRecord / $EventRecordXML etc for troubleshooting
                #$host.EnterNestedPrompt()
                $outfile = "c:\weffles\weffles.csv"

                #Creating object to output to .csv
                $EventObj = New-Object psobject
                
                #Adding Date in Short Format to .csv object
                $EventObj | Add-Member noteproperty EventDate $EventRecord.TimeCreated.ToShortDateString()
                
                #Adding Computername to .csv object
                $EventObj | Add-Member noteproperty EventHost $EventRecord.MachineName

                #Adding EventID to .csv object
                $EventObj | Add-Member noteproperty EventID $EventRecord.ID

                #Adding TargetUserName to .csv object
                $EventObj | Add-Member noteproperty TargetUserName $EventRecordXml.SelectSingleNode("//*[@Name='TargetUserName']")."#text"
                
                #Adding TargetUserName to .csv object
                $EventObj | Add-Member noteproperty SamAccountName $EventRecordXml.SelectSingleNode("//*[@Name='SamAccountName']")."#text"

                #Adding LogonType to .csv object
                $EventObj | Add-Member noteproperty LogonType $EventRecordXml.SelectSingleNode("//*[@Name='LogonType']")."#text"  

                #Adding TargetDomainName to .csv object
                $EventObj | Add-Member noteproperty TargetDomainName $EventRecordXml.SelectSingleNode("//*[@Name='TargetDomainName']")."#text"

                #Adding SubjectUserName to .csv object
                $EventObj | Add-Member noteproperty SubjectUserName $EventRecordXml.SelectSingleNode("//*[@Name='SubjectUserName']")."#text"

                #Adding SubjectDomainName to .csv object
                $EventObj | Add-Member noteproperty SubjectDomainName $EventRecordXml.SelectSingleNode("//*[@Name='SubjectDomainName']")."#text"

                #Adding IpAddress to .csv object
                $EventObj | Add-Member noteproperty IpAddress $EventRecordXml.SelectSingleNode("//*[@Name='IpAddress']")."#text"                     

                #Adding WorkstationName to .csv object
                $EventObj | Add-Member noteproperty WorkstationName $EventRecordXml.SelectSingleNode("//*[@Name='WorkstationName']")."#text"                     

                #Adding ProcessName to .csv object
                $EventObj | Add-Member noteproperty ProcessName $EventRecordXml.SelectSingleNode("//*[@Name='ProcessName']")."#text" 
                     
                #Adding AuthenticationPackageName to .csv object
                $EventObj | Add-Member noteproperty AuthenticationPackageName $EventRecordXml.SelectSingleNode("//*[@Name='AuthenticationPackageName']")."#text"
                $EventObj | Add-Member noteproperty Message $EventRecordXml.SelectSingleNode("//*[@Name='Message']")."#text"
                $EventObj | Add-Member noteproperty ActionName $EventRecordXml.SelectSingleNode("//*[@Name='ActionName']")."#text"
                
				$EventObj | Add-Member noteproperty ServiceName $EventRecordXml.SelectSingleNode("//*[@Name='ServiceName']")."#text"
                $EventObj | Add-Member noteproperty ImagePath $EventRecordXml.SelectSingleNode("//*[@Name='ImagePath']")."#text"
                $EventObj | Add-Member noteproperty ServiceType $EventRecordXml.SelectSingleNode("//*[@Name='ServiceType']")."#text"
                $EventObj | Add-Member noteproperty StartType $EventRecordXml.SelectSingleNode("//*[@Name='StartType']")."#text"
                $EventObj | Add-Member noteproperty AccountName $EventRecordXml.SelectSingleNode("//*[@Name='AccountName']")."#text"
                $EventObj | Add-Member noteproperty Computer $EventRecordXml.SelectSingleNode("//*[@Name='Computer']")."#text"
                $EventObj | Add-Member noteproperty UserID $EventRecord.UserID

                
                              
                #Adding Action type after resolving EventID -> Action name to .csv object
                If ($EventRecord.ID -eq '4624')
                    {
					
					$hash = New-Object psobject -Property @{
                           LogonType = $EventRecordXml.SelectSingleNode("//*[@Name='LogonType']")."#text"   
                           IpAddress = $EventRecordXml.SelectSingleNode("//*[@Name='IpAddress']")."#text"                     
                           WorkstationName = $EventRecordXml.SelectSingleNode("//*[@Name='WorkstationName']")."#text"                     
                           ProcessName = $EventRecordXml.SelectSingleNode("//*[@Name='ProcessName']")."#text" 
                           SubjectUserName = $EventRecordXml.SelectSingleNode("//*[@Name='SubjectUserName']")."#text"
                           SubjectDomainName = $EventRecordXml.SelectSingleNode("//*[@Name='SubjectDomainName']")."#text" 
						   AuthenticationPackageName = $EventRecordXml.SelectSingleNode("//*[@Name='AuthenticationPackageName']")."#text"
						   TargetUserName = $EventRecordXml.SelectSingleNode("//*[@Name='TargetUserName']")."#text"
						   TargetDomainName = $EventRecordXml.SelectSingleNode("//*[@Name='TargetDomainName']")."#text"
                       };
					
                     
                    }
					
                    If ($EventRecord.ID -eq '4625')
                    {
					
					$hash = New-Object psobject -Property @{
                           LogonType = $EventRecordXml.SelectSingleNode("//*[@Name='LogonType']")."#text"   
                           IpAddress = $EventRecordXml.SelectSingleNode("//*[@Name='IpAddress']")."#text"                     
                           WorkstationName = $EventRecordXml.SelectSingleNode("//*[@Name='WorkstationName']")."#text"                     
                           ProcessName = $EventRecordXml.SelectSingleNode("//*[@Name='ProcessName']")."#text" 
                           SubjectUserName = $EventRecordXml.SelectSingleNode("//*[@Name='SubjectUserName']")."#text"
                           SubjectDomainName = $EventRecordXml.SelectSingleNode("//*[@Name='SubjectDomainName']")."#text" 
						   AuthenticationPackageName = $EventRecordXml.SelectSingleNode("//*[@Name='AuthenticationPackageName']")."#text"
						   TargetUserName = $EventRecordXml.SelectSingleNode("//*[@Name='TargetUserName']")."#text"
						   TargetDomainName = $EventRecordXml.SelectSingleNode("//*[@Name='TargetDomainName']")."#text"
						   FailureReason = $EventRecordXml.SelectSingleNode("//*[@Name='FailureReason']")."#text"
                       };
					   
                     
                    }
                    
					If ($EventRecord.ID -eq '4648')
                    {
					
					$hash = New-Object psobject -Property @{
                           IpAddress = $EventRecordXml.SelectSingleNode("//*[@Name='IpAddress']")."#text"                     
                           WorkstationName = $EventRecordXml.SelectSingleNode("//*[@Name='WorkstationName']")."#text"                     
                           ProcessName = $EventRecordXml.SelectSingleNode("//*[@Name='ProcessName']")."#text" 
                           SubjectUserName = $EventRecordXml.SelectSingleNode("//*[@Name='SubjectUserName']")."#text"
                           SubjectDomainName = $EventRecordXml.SelectSingleNode("//*[@Name='SubjectDomainName']")."#text" 
						   TargetUserName = $EventRecordXml.SelectSingleNode("//*[@Name='TargetUserName']")."#text"
						   TargetDomainName = $EventRecordXml.SelectSingleNode("//*[@Name='TargetDomainName']")."#text"
						   TargetServerName = $EventRecordXml.SelectSingleNode("//*[@Name='TargetServerName']")."#text"
                       };
					   
                     
                    }
					
                If ($EventRecord.ID -eq '4964')
                    {
                      $hash = New-Object psobject -Property @{
                           SubjectUserName = $EventRecordXml.SelectSingleNode("//*[@Name='SubjectUserName']")."#text"
                           SubjectDomainName = $EventRecordXml.SelectSingleNode("//*[@Name='AuthenticationPackageName']")."#text" 
						   AuthenticationPackageName = $EventRecordXml.SelectSingleNode("//*[@Name='AuthenticationPackageName']")."#text"
						   TargetUserName = $EventRecordXml.SelectSingleNode("//*[@Name='TargetUserName']")."#text"
						   TargetDomainName = $EventRecordXml.SelectSingleNode("//*[@Name='TargetDomainName']")."#text"
						   SidList = $EventRecordXml.SelectSingleNode("//*[@Name='SidList']")."#text"
                       };
					   
                    
                    }
					
					If ($EventRecord.ID -eq '1102')
                    {
                     $hash = New-Object psobject -Property @{
                           SubjectUserName = $EventRecordXml.SelectSingleNode("//*[@Name='SubjectUserName']")."#text"
                           SubjectDomainName = $EventRecordXml.SelectSingleNode("//*[@Name='AuthenticationPackageName']")."#text" 
						   };
                     
                    }
				If ($EventRecord.ID -eq '106')
                    {
                     $hash = New-Object psobject -Property @{
                           Message = $EventRecordXml.SelectSingleNode("//*[@Name='Message']")."#text" 
						   };
                     }
				    
				If ($EventRecord.ID -eq '200')
                    {
                     $hash = New-Object psobject -Property @{
                           ActionName = $EventRecordXml.SelectSingleNode("//*[@Name='ActionName']")."#text" 
						   };
                     
                    }
				
				                
				If ($EventRecord.ID -eq '7045')
                    {
					$hash = New-Object psobject -Property @{
                           LogonType = $EventRecordXml.SelectSingleNode("//*[@Name='LogonType']")."#text"   
                           IpAddress = $EventRecordXml.SelectSingleNode("//*[@Name='IpAddress']")."#text"                     
                           WorkstationName = $EventRecordXml.SelectSingleNode("//*[@Name='WorkstationName']")."#text"                     
                           ProcessName = $EventRecordXml.SelectSingleNode("//*[@Name='ProcessName']")."#text" 
                           SubjectUserName = $EventRecordXml.SelectSingleNode("//*[@Name='SubjectUserName']")."#text"
                           SubjectDomainName = $EventRecordXml.SelectSingleNode("//*[@Name='AuthenticationPackageName']")."#text" 
						   AuthenticationPackageName = $EventRecordXml.SelectSingleNode("//*[@Name='AuthenticationPackageName']")."#text"
						   TargetUserName = $EventRecordXml.SelectSingleNode("//*[@Name='TargetUserName']")."#text"
						   TargetDomainName = $EventRecordXml.SelectSingleNode("//*[@Name='TargetDomainName']")."#text"
						   ServiceName = $EventRecordXml.SelectSingleNode("//*[@Name='ServiceName']")."#text"
                           ImagePath = $EventRecordXml.SelectSingleNode("//*[@Name='ImagePath']")."#text"
                           ServiceType = $EventRecordXml.SelectSingleNode("//*[@Name='ServiceType']")."#text"
                           StartType = $EventRecordXml.SelectSingleNode("//*[@Name='StartType']")."#text"
                           AccountName = $EventRecordXml.SelectSingleNode("//*[@Name='AccountName']")."#text"
                       };
					}
                ElseIf ($EventRecord.ID -eq '4720')
                    {
					$hash = New-Object psobject -Property @{
                           SubjectUserName = $EventRecordXml.SelectSingleNode("//*[@Name='SubjectUserName']")."#text"
                           SubjectDomainName = $EventRecordXml.SelectSingleNode("//*[@Name='AuthenticationPackageName']")."#text" 
						   TargetUserName = $EventRecordXml.SelectSingleNode("//*[@Name='TargetUserName']")."#text"
						   TargetDomainName = $EventRecordXml.SelectSingleNode("//*[@Name='TargetDomainName']")."#text"
						   SamAccountName = $EventRecordXml.SelectSingleNode("//*[@Name='SamAccountName']")."#text"
                       };
					}

              If ($Outfile -ne $Null)
                {
                    $EventObj | Convertto-CSV -Outvariable OutData -NoTypeInformation 
                
                    $OutPath = $Outfile
                    
                    If (Test-Path $OutPath)
                        {
                            $Outdata[1..($Outdata.count - 1)] | ForEach-Object {Out-File -InputObject $_ $OutPath -append default}
                        } 
                    else 
                        {
                            Out-File -InputObject $Outdata $OutPath -Encoding default
                        }
                }


            }

Register-EventRecordWrittenEvent $EventLogWatcher -action $action -SourceIdentifier weffles

$EventLogWatcher.Enabled = $True