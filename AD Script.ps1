$MenuHeadText="Please select one of the followging items:"
$MenuItems= "",
"Change static IP, subnet, Gateway on a remote server",  # item 1
"Install AD services on a remote server",  # item 2
"Promote a remote server to DC",  # item 3
"Move or seize FSMO roles", #item 4
"Exit" #item 5
$MenuItemsCount = $MenuItems.length - 1
$MenuSelectionText = "Selection (1-$MenuItemsCount)"
$Lines = "`n`n`n"


Function Main{
MainMenu
}

Function MainMenu{

Clear
MainMenuDraw

While( ($Selection = Read-Host -Prompt $MenuSelectionText) -ne $MenuItemsCount){
    
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

$ScreenWidth=$host.ui.RawUI.WindowSize.width - 4
$TitleMessage = "  JIM'S AD TOOLS SOFTWARE  "
$TitleBanner = "#"*([int]($ScreenWidth/2) - [int]( $TitleMessage.Length / 2)) + $TitleMessage + "#"*([int]($ScreenWidth/2) - [int]( $TitleMessage.Length / 2))
"$([int]($ScreenWidth/2) - [int]( $TitleMessage.Length / 2))"


Clear
$Lines
Write-Host $TitleBanner "`n`n" -ForegroundColor Green
$MenuHeadText + "`n"

For ($x = 1; $x -le $MenuItemsCount ; $x++ )
    {
        "    " + $x  + " " + $MenuItems[$x] + "`n"
    }
}

Function Networking{

Clear

$Lines
"Please enter the following parameters. You may enter [exit] to cancel at any time."
"`n"

$ErrorActionPreference = 'continue'

If ( ($Computer = Read-Host -Prompt "Name of server or current IP address") -eq "exit") { return }
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

# Display newley entered values
"`n`n"
"New IP Address: $NewiP"
"New Subnet: $NewSubnet"
"New Gateway: $NewGateway"
"New DNS Server: $NewDNS"
"Credentials: $Cred"
"`n"

If ( ($P = Read-Host -Prompt "If these values look correct enter [y] to continue") -ne "y") { return }

# remote over and change IP address
# Development note - not working

Invoke-Command -ComputerName $Computer -Credential $Cred -ScriptBlock{
    param ( $Computer, $NewIP, $NewSubne, $NewGateway, $NewDNS)

    # below from https://blogs.technet.microsoft.com/heyscriptingguy/2012/02/28/use-powershell-to-configure-static-ip-and-dns-settings/

    $wmi = Get-WmiObject win32_networkadapterconfiguration -filter "ipenabled = 'true'" -computername $Computer
    $wmi.EnableStatic("$NewIP", "$NewSubnet")
    $wmi.SetGateways("$NewGateway", 1)
    $wmi.SetDNSServerSearchOrder("$NewDNS")
  }  -ArgumentList $Computer, $NewIP, $NewSubne, $NewGateway, $NewDNS

ProgressBar SUCCESS 1 Up
$Lines
$P = Read-Host -Prompt "Commands successefully proccessed. Press enter to continue." 

"`nTesting new connection`n`n"

If (-not (Test-Connection $NewIP -Count 1  )  ) {
    ProgressBar FAILED .3 Down
    $P = Read-Host -Prompt "`r`rFailed to connect.  Press enter to continue."
    return
    } 

ProgressBar SUCCESS 1 Up
$Lines
$P = Read-Host -Prompt "Connection successeful. Press enter to continue."

}

Function ADServices{

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

ProgressBar SUCCESS 1 Up
$Lines
$P = Read-Host -Prompt "Commands successeful. Press enter to continue."

}

Function Promote{

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
$P = Read-Host -Prompt "Commands successeful. Press enter to continue."

}

Function MoveFSMO{

$Lines
"Please enter the following parameters. You may enter [exit] to cancel at any time."
"`n"


}

Function ProgressBar{
Param ($Message, $Run, $Finish)
# $Message is the message to be diplayed in the footer at completion, no more than 15 characters please
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
$BoatRun = ($ScreenWidth - $BoatLength ) 
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


for ($x = 1 ; $x -lt [int]($BoatRun * $Run) ; $x++)
    { 

    clear
    $Lines
    $TitleBanner
    $Space = " "*$x

    $BoatLeading[$ProgressDisplayLevel] = "~~ $([int](100*($x/($BoatRun*10)))*10) ~~`r"

        for ($y = 0 ; $y -lt $WaterLevel ; $y++)
            {
            Write-Host $Space, $Boat[$y], $BoatLeading[$y]
            }

         write-host $FooterWater -ForegroundColor Cyan
         Start-Sleep -Milliseconds $BoatSpeed
    }
Start-Sleep -Milliseconds $EndDelay

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

Main

$Lines
