####################################################################################################################################################
#                              Check Citrix Virtual Apps and Virtual Desktop Session Codec and Encoding                                            #
####################################################################################################################################################
#                                                                                                                                                  #
#             Created:         Tobias Zurstegen, zurstegen.de                                                                                      #
#             Last Modified:   25.02.2019                                                                                                          #
#             Description:     Check Hardware Encoding and Codec per Citrix Delivery Group                                                         #
#             Limitation:      Only tested with Citrix VirtualDesktop 7.15.2, 7.18 and Citrix Virtual Apps 1808, 1811                              #
#             Example:         Check-CVADSessionCodec -ddc "Delivery Controller Hostname" -deliverygroup 'deliverygroupname'                       #
#                              If no Delivery Controller hostname defined localhost will use automatically                                         #
#                                                                                                                                                  #                                                          #
####################################################################################################################################################

function Check-CVADSessionCodec{
    param(
        $ddc,
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$deliverygroup
        )

    #Variables
    [int] $sessions = 0;
    [int] $not_available = 0;
    [int] $nonvenc = 0;
    [int] $nonenvc_linuxclient = 0;
    [int] $lossless_all = 0;
    [int] $lossless_linuxclient = 0;
    [int] $activechangingregions = 0;

    $select_xd_7_15 =@{Name="VM";Expression={$_.__SERVER}}, @{Name="Hardware Encode";Expression={$_.Component_HardwareEncodeEnabled}}, @{Name="Codec";Expression={$_.Component_Encoder}}, @{Name="Video Codec usage";Expression={$_.Component_VideoCodecUse}}, @{Name="Max Visual Quality";Expression={$_.Component_MaxVisualQuality}}, @{Name="Min Visual Quality";Expression={$_.Component_MinVisualQuality}}, @{Name="Color Space";Expression={$_.Component_VideoCodecColorspace}}, @{Name="Frames p/s";Expression={$_.Component_Fps}}, @{Name="Max Frame p/s";Expression={$_.Component_MaxFps}}, @{Name="Policy - Hardware Encode";Expression={$_.Policy_UseHardwareEncodingForVideoCodec}}, @{Name="Policy - Video Codec Usage";Expression={$_.Policy_UseVideoCodec}}, @{Name="Policy - Alllow visually lossless compression";Expression={$_.Policy_AllowVisuallyLosslessCompression}}, @{Name="Policy - Visual Quality";Expression={$_.Policy_VisualQuality}}, @{Name="Policy - Frames p/s";Expression={$_.Policy_FramesPerSecond}}             
    $select_xd_7_16 =@{Name="VM";Expression={$_.__SERVER}}, @{Name="Hardware Encode";Expression={$_.Component_Monitor_HardwareEncodeInUse}}, @{Name="Video Codec usage";Expression={$_.Component_VideoCodecUse}}, @{Name="Max Visual Quality";Expression={$_.Component_MaxVisualQuality}}, @{Name="Min Visual Quality";Expression={$_.Component_MinVisualQuality}}, @{Name="Color Space";Expression={$_.Component_VideoCodecColorspace}}, @{Name="Frames p/s";Expression={$_.Component_Fps}}, @{Name="Max Frames p/s";Expression={$_.Component_MaxFps}}, @{Name="Policy - Hardware Encode";Expression={$_.Policy_UseHardwareEncodingForVideoCodec}}, @{Name="Policy - Video Codec Usage";Expression={$_.Policy_UseVideoCodec}}, @{Name="Policy - Alllow visually lossless compression";Expression={$_.Policy_AllowVisuallyLosslessCompression}}, @{Name="Policy - Visual Quality";Expression={$_.Policy_VisualQuality}}, @{Name="Policy - Frames p/s";Expression={$_.Policy_FramesPerSecond}}
    $select_xa_1808 =@{Name="VM";Expression={$_.__SERVER}}, @{Name="Hardware Encode";Expression={$_.Component_Monitor_HardwareEncodeInUse}}, @{Name="Video Codec usage";Expression={$_.Component_VideoCodecUse}}, @{Name="Max Visual Quality";Expression={$_.Component_MaxVisualQuality}}, @{Name="Min Visual Quality";Expression={$_.Component_MinVisualQuality}}, @{Name="Color Space";Expression={$_.Component_VideoCodecColorspace}}, @{Name="Frames p/s";Expression={$_.Component_Fps}}, @{Name="Max Frames p/s";Expression={$_.Component_MaxFps}}, @{Name="Policy - Hardware Encode";Expression={$_.Policy_UseHardwareEncodingForVideoCodec}}, @{Name="Policy - Video Codec Usage";Expression={$_.Policy_UseVideoCodec}}, @{Name="Policy - Visual Quality";Expression={$_.Policy_VisualQuality}}, @{Name="Policy - Frames p/s";Expression={$_.Policy_FramesPerSecond}}


    #Get all active and no disconnected sessions per Delivery Group
    Get-BrokerSite -AdminAddress $ddc
    $computername = Get-BrokerSession -DesktopGroupName $deliverygroup -SessionState Active

    ##Check if Single or MultiSession
    foreach($computer in $computername){
        if(($computer.IPAddress) -and (Test-NetConnection -ComputerName $computer.IPAddress -Port "135" -InformationLevel Quiet)){
            $sessiontype = Get-BrokerMachine -HostedMachineName $computer.HostedMachineName
            $wmi_namespace = "root\citrix\hdx"
            $vdaversion=$sessiontype.AgentVersion.Substring(0,4).ToDouble($null)

            #VirtualDesktop
            if($sessiontype.SessionSupport -eq "SingleSession"){
                #Hostname
                $hostname = $computer.hostedmachinename
            
                #WMI Query 
                $wmi = Get-WmiObject -Namespace $wmi_namespace -Class "citrix_virtualchannel_thinwire" -ComputerName $hostname  
           
                #WMI Ouery only for all VDAs lower 7.16 VDA
                if($vdaversion -lt '7.16'){ #VDA <7.16
                    if($wmi.Component_HardwareEncodeEnabled  -like "False"){
                        #Output
                        $wmi | select $select_xd_7_15
                        $computer | select UserUPN, ClientName, ClientPlatform, ClientVersion
                        Write-Host "-------------------------- `t"
                   
                        $nonvenc++
                        if($computer.ClientPlatform -and "Unix / Linux"){$nonenvc_linuxclient++}
                    }
                }
                #WMI Query only for all VDAs higher 7.15 VDA
                if($vdaversion -ge '7.16' -or $vdaversion -ge '1808'){ #VDA >7.15
                    if($wmi.Component_HardwareEncodeInUse -like "False"){
                        #Output
                        $wmi  | select $select_xd_7_16
                        $computer | select UserUPN, ClientName, ClientPlatform, ClientVersion
                        Write-Host "-------------------------- `t"

                        $nonvenc++
                        if($computer.ClientPlatform -and "Unix / Linux"){$nonenvc_linuxclient++}
                    }
                }

                #WMI Oueries for every VDA Version
                if($wmi.Component_MaxVisualQuality -like "LossLess"){$lossless_all++}
                if($computer.ClientPlatform -like "Unix / Linux" -and $wmi.Component_MaxVisualQuality -like "LossLess"){$lossless_linuxclient++} 

                #Count sessions
                $sessions++
             }
        
            #VirtualApps
            elseif($sessiontype.SessionSupport -eq "MultiSession"){
                $sessionids = " "
                #Connect per Remote Powershell to every VirtualApps VDA and read the UserName and SessionIDs. It's necessary for the WMI Query, because this need the SessionID.
                $s = New-PSSession -ComputerName $computer.HostedMachineName
                $sessionids = Invoke-Command -Session $s -ScriptBlock { Get-Process -IncludeUserName | Select-Object UserName,SessionId  | Where-Object { $_.UserName -ne $null -and $_.UserName.StartsWith("CORP\") -and $_.SessionId -gt 0 } | Sort-Object SessionId -Unique } | Select-Object UserName,SessionId
                Remove-PSSession -Session $s
                foreach($sessionid in $sessionids){
                    [string]$id = $sessionid.SessionId   
                    $wmi = Get-WmiObject -Namespace "root\citrix\hdx" -class "Citrix_VirtualChannel_Thinwire_Enum" -ComputerName $computer.IPAddress -Filter "SessionID=$id" | Sort-Object $_.SessionID -Unique #| select __SERVER, Component_Monitor_HardwareEncodeInUse, Component_MaxVisualQuality, Component_MinVisualQuality, Component_VideoCodecColorspace, Policy_UseHardwareEncodingForVideoCodec, Policy_UseVideoCodec, Policy_AllowVisuallyLosslessCompression, Policy_VisualQuality
                    $user = Get-BrokerSession -DesktopGroupName $deliverygroup -UserName $sessionid.UserName  -SessionState Active
                    if($user){
                        if($wmi.Component_Monitor_HardwareEncodeInUse -like "False"){
                        $nonvenc++
                        $wmi | select $select_xa_1808
                        $user | select UserUPN, ClientName, ClientPlatform, ClientVersion
                        Write-Host "-------------------------- `t"
                  
                        $nonvenc++
                        if($user.ClientPlatform -and "Unix / Linux"){$nonenvc_linuxclient++}
                        }
                    }
                    #Count sessions
                    $sessions++
                    }
             }  
        }        
        else{
            Write-host $computer.HostedMachineName "is not available `t"
            $not_available++
        }
    }

    #Output summary
    write-host "Number of unavailable machines: $not_available"
    write-host "Total number of active sessions without Hardware Enconding: $nonvenc"
    write-host "Number of sessions without Hardware Enconding - only clients with Linux Receiver: $nonenvc_linuxclient"
    write-host "Total number of active sessions where the session quality is LossLess: $lossless_all"
    write-host "Total number of active sessions: $sessions"
}