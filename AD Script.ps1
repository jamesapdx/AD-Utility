#####################################################################
#
#  AD Utilities, created by Jim Shaffer, 3/7/17
#  All except 4 lines hand written. I learned the basics of
#  PowerShell and wrote this script all in one day
#
#  This software will run various AD utilities
#  Software is provided as a PowerShell example, not be
#  used in a production environment
#
#####################################################################


# Menu items are stored in the array $MenuItems, add as needed

$MenuHeadText="Please select one of the followging items:"
$MenuItems= "",
"Change static IP, subnet, Gateway on a remote server",  # item 1
"Install AD services on a remote server",  # item 2
"Promote a remote server to DC",  # item 3
"Move or seize FSMO roles", #item 4
"Exit" #item 5
$MenuItemsCount = $MenuItems.length - 1  # number of menu items
$MenuSelectionText = "Selection (1-$MenuItemsCount)"
$Lines = "`n`n`n"  # used for spacing 


Function Main{
MainMenu
}

Function MainMenu{

Clear
MainMenuDraw

# prompt for input, keep asking if no valid answer (numeric < Menu items)
While( ($Selection = Read-Host -Prompt $MenuSelectionText) -ne $MenuItemsCount){
    
    # improve this in the future by putting the switch items in an array also
    switch($Selection){
    1 {Networking}
    2 {ADServices}
    3 {Promote}
    4 {MoveFSMO}
    }

    Clear
    MainMenuDraw
 }
}

Function MainMenuDraw{
# draw the title and main menu items only

$ScreenWidth=$host.ui.RawUI.WindowSize.width - 4  # get screen width, draw banner within width
$TitleMessage = "  JIM'S AD TOOLS SOFTWARE  "
$TitleBanner = "#"*([int]($ScreenWidth/2) - [int]( $TitleMessage.Length / 2)) + $TitleMessage + "#"*([int]($ScreenWidth/2) - [int]( $TitleMessage.Length / 2))
"$([int]($ScreenWidth/2) - [int]( $TitleMessage.Length / 2))"


Clear
$Lines
Write-Host $TitleBanner "`n`n" -ForegroundColor Green
$MenuHeadText + "`n"

For ($x = 1; $x -le $MenuItemsCount ; $x++ )  # draw the menu items
    {
        "    " + $x  + " " + $MenuItems[$x] + "`n"
    }
}

#####################################################################
#
#  Start of utility functions
#
#####################################################################


Function Networking{
# this function will ask for new network information, IP, subnet mask, gateway
# DNS server, will verify a good connection, then attempt to change the setting 
# on the remote server
# This function is currently NOT working and needs troubleshooting

Clear

$Lines
"Please enter the following parameters. You may enter [exit] to cancel at any time."
"`n"

$ErrorActionPreference = 'continue'  # this prevents ugly error messages on screen

If ( ($Computer = Read-Host -Prompt "Name of server or current IP address") -eq "exit") { return }

#test for connection before asking more details
If (-not (Test-Connection $Computer -Count 1  )  ) {
    ProgressBar FAILED .3 Down
    $P = Read-Host -Prompt "`r`rFailed to connect.  Press enter to continue."
    return
    } 
    Write-Host "  ** Connection verified **" -ForegroundColor red
If ( ($NewSub = Read-Host -Prompt "Enter subnet (first three octets) [default = 192.168.100]") -eq "exit") { return }
    elseif ($NewSub -eq "") {$NewSub = "192.168.100"}
If ( ($NewIP = Read-Host -Prompt "New IP Address (last octet)") -eq "exit") { return }
If ( ($NewSubnet = Read-Host -Prompt "New Subnet Mask [default = 255.255.255.0]") -eq "exit") { return }
    elseif ($NewSubnet -eq "") {$NewSubnet = "255.255.255.0"}
If ( ($NewGateway = Read-Host -Prompt "New Gateway (last octet) [default = 1]") -eq "exit") { return }
    elseif ($NewGateway -eq "") {$NewGateway = "1"}
If ( ($NewDNS = Read-Host -Prompt "New DNS Server (last octet) [default = 30]") -eq "exit") { return }
    elseif ($NewDNS -eq "") {$NewDNS = "30"}
If ( ($Cred = Read-Host -Prompt "Enter username [default = lab\administrator]") -eq "exit") { return }
    elseif ($Cred -eq "") {$Cred = "lab\administrator"}

$NewiP="$NewSub.$NewIP"
$NewGateway="$NewSub.$NewGateway"
$NewDNS="$NewSub.$NewDNS"

# Display newly entered values
"`n`n"
"New IP Address: $NewiP"
"New Subnet: $NewSubnet"
"New Gateway: $NewGateway"
"New DNS Server: $NewDNS"
"Credentials: $Cred"
"`n"

If ( ($P = Read-Host -Prompt "If these values look correct enter [y] to continue") -ne "y") { return }

# remote over and change networking settings
Invoke-Command -ComputerName $Computer -Credential $Cred -ScriptBlock{
    param ( $Computer, $NewIP, $NewSubne, $NewGateway, $NewDNS)

    # following 4 lines are from
    # https://blogs.technet.microsoft.com/heyscriptingguy/2012/02/28/use-powershell-to-configure-static-ip-and-dns-settings/

    $wmi = Get-WmiObject win32_networkadapterconfiguration -filter "ipenabled = 'true'" -computername $Computer
    $wmi.EnableStatic("$NewIP", "$NewSubnet")
    $wmi.SetGateways("$NewGateway", 1)
    $wmi.SetDNSServerSearchOrder("$NewDNS")
  }  -ArgumentList $Computer, $NewIP, $NewSubne, $NewGateway, $NewDNS

# need to add error checking from previous lines, but for now assume success 
ProgressBar SUCCESS 1 Up  
$Lines
$P = Read-Host -Prompt "Commands successfully proccessed. Press enter to continue." 

"`nTesting new connection`n`n"

# test connection to verify changes succeeded
If (-not (Test-Connection $NewIP -Count 1  )  ) {
    ProgressBar FAILED .3 Down
    $P = Read-Host -Prompt "`r`rFailed to connect.  Press enter to continue."
    return
    } 

ProgressBar SUCCESS 1 Up
$Lines
$P = Read-Host -Prompt "Connection successful. Press enter to continue."

}

Function ADServices{
# This function will install Domain features on the remote server
# need to test

Clear
$Lines
"Please enter the following parameters. You may enter [exit] to cancel at any time."
"`n"

If ( ($Computer = Read-Host -Prompt "Name of server or IP address") -eq "exit") { return }
If (-not (Test-Connection $Computer -Count 1  )  ) {
    ProgressBar FAILED .3 Down
    $P = Read-Host -Prompt "`r`rFailed to connect.  Press enter to continue."
    return
    } 
If ( ($Cred = Read-Host -Prompt "Enter username [default = lab\administrator]") -eq "exit") { return }
    elseif ($Cred -eq "") {$Cred = "lab\administrator"}

#Install the features
Install-WindowsFeature AD-Domain-services -ComputerName $Computer -Credential $Cred -IncludeAllSubFeature

# need to include error handling, assume success for now
ProgressBar SUCCESS 1 Up
$Lines
$P = Read-Host -Prompt "Commands successeful. Press enter to continue."

}

Function Promote{
# This function will promote a remote server to a domain controller

Clear
$Lines
"Please enter the following parameters. You may enter [exit] to cancel at any time."
"`n"

If ( ($Computer = Read-Host -Prompt "Name of server or IP address") -eq "exit") { return }
If (-not (Test-Connection $Computer -Count 1  )  ) {
    ProgressBar FAILED .3 Down
    $P = Read-Host -Prompt "`r`rFailed to connect.  Press enter to continue."
    return
    } 
If ( ($Cred = Read-Host -Prompt "Enter username [default = lab\administrator]") -eq "exit") { return }
    elseif ($Cred -eq "") {$Cred = "lab\administrator"}
If ( ($DomainName = Read-Host -Prompt "Enter DomainName [default = lab]") -eq "exit") { return }
    elseif ($DomainName -eq "") {$DomainName = "lab"}

Invoke-Command -ComputerName $Computer -Credential $Cred -ScriptBlock{ 
    param ( $DomainName, $Cred )
    Import-Module ADDSDeployment
    Install-ADDSDomainController -DomainName 
    } -ArgumentList $DomainName, $Cred

ProgressBar SUCCESS 1 Up
$Lines
$P = Read-Host -Prompt "Commands successful. Press enter to continue."

}

Function MoveFSMO{
# this function will move the 5 FSMO roles to another server
# not completed at this time

$Lines
"Please enter the following parameters. You may enter [exit] to cancel at any time."
"`n"

}


#####################################################################
#
#  Start of progress bar (move a boat) function
#
#####################################################################

Function ProgressBar{
Param ($Message, $Run, $Finish)
# pass the success or fail message (1-15 characters), run distance (.1 to 1), and "Up" for a
# non failed finish

# this function is for fun and servers as a pretend progress bar
# it will draw a boat moving across the screen and sink the boat to 
# represent a failed state

# $Message is the message to be displayed in the footer at completion, no more than 15 characters please
# $Run is a number from .1 - 1 when the boat should sink, used for short distance failures

# define art

$Boat=
"",
"",
"",
"         |    |    |",
"        )_)  )_)  )_)",
"       )___))___))___)\",
"      )____)____)_____)\\",
"    _____|____|____|____\\\__",
"    \                   /",
""

$BoatFinish=
"",
"",
"",
"         |    |    |",
"         |    |    | ",
"        _|_  _|_  _|_ \",
"       __|_ __|_ __|__ \\",
"    _____|____|____|____\\\__",
"    \                   /",
""

# art from chris.com\ascii 

If ($Run -eq "" ) { $Run = 1 }
$ScreenWidth=$host.ui.RawUI.WindowSize.width - 4
$WaterLevel = $Boat.Length - 1
$ProgressDisplayLevel = 2
$BoatSpeed = 60
$SinkSpeed = 240
$EndDelay = 350
$BoatLength = 40
$BoatRun = ($ScreenWidth - $BoatLength )  # total distance to run the boat
$BoatLeading = @("`r")*$WaterLevel
$Boat[$WaterLevel] = "^"*($ScreenWidth)
$TitleMessage = ">  PROGRESS  <"
$TitleBanner = "="*([int]($ScreenWidth/2) - [int]( $TitleMessage.Length / 2)) + $TitleMessage + "="*([int]($ScreenWidth/2) - [int]( $TitleMessage.Length / 2))
"$([int]($ScreenWidth/2) - [int]( $TitleMessage.Length / 2))"
$FooterMessage = "|  $Message  |"
$FooterBanner = "^"*([int]($ScreenWidth/2) - [int]( $TitleMessage.Length / 2)) + $FooterMessage + "^"*([int]($ScreenWidth/2) - [int]( $TitleMessage.Length / 2))
"$([int]($ScreenWidth/2) - [int]( $TitleMessage.Length / 2))"
$FooterWater = "^"*$FooterBanner.Length


# loop, sail the boat across the screen

for ($x = 1 ; $x -lt [int]($BoatRun * $Run) ; $x++) # outer loop, from 1 to total distance * desired distance factor (.1 to 1)
    { 

    clear  # clear the screen and draw the header/banner items
    $Lines
    $TitleBanner
    $Space = " "*$x

    $BoatLeading[$ProgressDisplayLevel] = "~~ $([int](100*($x/($BoatRun*10)))*10) ~~`r"

        for ($y = 0 ; $y -lt $WaterLevel ; $y++) # draw the boat array loop
            {
            Write-Host $Space, $Boat[$y], $BoatLeading[$y]  # draw trailing space, boat, any leading items
            }

         write-host $FooterWater -ForegroundColor Cyan  # draw the water
         Start-Sleep -Milliseconds $BoatSpeed  # delay to get the right draw speed as it moves across the screen
    }
Start-Sleep -Milliseconds $EndDelay  

# the following will either raise the sails or sink the boat
If ($Finish -eq "Up"){
    clear
    $Lines
    $TitleBanner

    $BoatLeading[$ProgressDisplayLevel] = "~~ $([int](100*($x/($BoatRun*10)))*10) ~~`r"
        for ($y = 0 ; $y -lt $WaterLevel ; $y++)
            {
            Write-Host $Space, $BoatFinish[$y], $BoatLeading[$y]
            }

         write-host $FooterWater -ForegroundColor Cyan
         Start-Sleep -Milliseconds $BoatSpeed
    }

# sink the boat
else {
for ($x = 0 ; $x -lt $WaterLevel ; $x++)
    {
    clear
    $Lines
    $TitleBanner
   
    for ($z = 0 ; $z -lt $x - 0; $z++) {"`r"}
    for ($y = 0 ; $y -lt $WaterLevel - $x ; $y++)
            {
            Write-Host $Space, $Boat[$y], $BoatLeading[$y]
            }

         write-host $FooterBanner -ForegroundColor Cyan
         Start-Sleep -Milliseconds $SinkSpeed
    }   
    }

$Lines

}

Main  #### Start of the program ####

$Lines  #### End of the program ####
