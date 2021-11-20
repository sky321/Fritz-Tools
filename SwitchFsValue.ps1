<#
.SYNOPSIS
    Wrapper-Skript für PeterPawns EVA-Tools PowerShell-Skripte

.DESCRIPTION
    PowerShell-Skript zum switchen des Wertes linux_fs_start der die Starpartition der Fritzbox festlegt. Hiermit ist es möglich nachdem ein neues Image geflashed wurde auf das alta zurück zu wechseln.
    Dieses Skript benötigt die EVA-Tools aus PeterPawns GitHup-Repository.

    Wichtig: vor dem Ausführen des Skripts sollte sichergestellt sein, dass entweder am LAN-Interface
    eine feste IP-Adresse eingestellt ist oder wenn die IP-Zuweisung per DHCP statt findet, dass der
    DhcpMediasense (https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&cad=rja&uact=8&ved=2ahUKEwjLw4jYgvvwAhUHmBQKHRulC8AQFjAAegQIAxAD&url=https%3A%2F%2Fdocs.microsoft.com%2Fde-de%2Ftroubleshoot%2Fwindows-server%2Fnetworking%2Fdisable-media-sensing-feature-for-tcpip&usg=AOvVaw0Gxeh5K_M2bfrhiHzUNnvO)
    deaktiviert wurde. 

    Hierzu öffnet man eine Powershell mit administrativen Rechten und führt "Set-NetIPv4Protocol -DhcpMediaSense Disabled" aus. Danach sollte
	überpüft werden, ob das LAN-Interface eine APIPA-Adresse bezogen hat. Wenn nicht, dann sollte ein "renew" des DHCP-Lease angestossen werden.
	Ansonsten führt man einfach dieses Skript aus (hierzu werden die administrativen Rechte nicht benötit).

	Nach erfolgreichem flashen der FRITZ!Box setzt man die Einstellung mittels "Set-NetIPv4Protocol -DhcpMediaSense Enabled" wieder zurück.
    

.NOTES
    Filename: SwitchFsValue.ps1

.EXAMPLE
    .\SwitchFsValue.ps1 [-BoxIP 192.168.178.1]

.PARAMETER BoxIP
	Steuert das ansprechen der FRITZ!Box während des Startvorgangs entweder über die vordefinierte IP oder über eine Eigene, Festgelegte.
    
.LINK
    https://github.com/PeterPawn/YourFritz
    https://github.com/WileC/FreetzTheBox

#>

#####################################################################
##
## Parameter-Definitionen

Param([Parameter(Mandatory = $False, HelpMessage = 'The IP for searching the box while booting')][string]$BoxIP='192.168.0.111'
    )


## Überprüfung, ob Neztwerkkabel am LAN-Interface angeschlossen ist oder DhcpMediaSense deaktiviert wurde
Write-Output "INFO: Ueberpruefung, ob Neztwerkkabel am LAN-Interface angeschlossen ist oder DhcpMediaSense deaktiviert wurde..";
if ( $(Get-NetIPv4Protocol).DhcpMediaSense )
    {
    Write-Verbose -Message "INFO: Der DHCPMediaSense ist auf den Netzwerkschittstellen aktiv. Dies kann je nach Verbindung zur FRITZ!Box zu Problemen führen. `
    `Sollte ein LAN-Kabel verwendet werden, sollte entweder eine APIPA-Adresse bereits vergeben sein, bevor der Flash-Vorgang gestartet wird oder eine feste `
    `IP-Adresse vergeben worden sein. Alternativ kann auch ein Switch zwischen PC und FRITZ!Box verbunden werden. Für weitere Informationen bitte die readme.md `
    `lesen (https://github.com/WileC/FreetzTheBox/blob/master/README.md) `n"
    }

if ( -not $(Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ether*,WLAN*).IPv4Address )
    {
    Write-Error -Message "FEHLER: Keiner Netzwerkschnittstelle wurde eine gültige IP-Adresse vergeben!" -Category ConnectionError -ErrorAction Stop;
    }


#########################################################
##
## Skript-Aufruf von .\EVA-Discover.ps1
##

Write-Output "Bitte die FRITZ!Box nun an den Strom anschliessen...";

.\EVA-Discover.ps1 -maxWait 120 -requested_address $BoxIP -Verbose -Debug;

Read-Host -Prompt "Um fortzufahren [ENTER] druecken...";

########################################################
##
## Skript-Aufruf von .\EVA-FTP-Client.ps1, zum setzen des neues Wertes für linux_fs_start
## und Reboot
##


Write-Output "INFO: Wechsel Firmware-Partition der FRITZ!Box ...";

.\EVA-FTP-Client.ps1 -Address $BoxIP -ScriptBlock { SwitchSystem } -Verbose -Debug;

Read-Host -Prompt "Zum Reboot [ENTER] druecken...";

.\EVA-FTP-Client.ps1 -Address $BoxIP -ScriptBlock { RebootTheDevice } -Verbose -Debug;

Read-Host -Prompt "Zum Schliessen der Session [ENTER] druecken...";
