try {
    $link = 'https://download.microsoft.com/download/8/8/0/880BCA75-79DD-466A-927D-1ABF1F5454B0/PBIDesktopSetup_x64.exe'
    $downloadPath = "C:\temp"
    $downloadName = (($link).Split("/"))[-1]
  
    # Create $downloadPath if it doesn't already exist
    if (-not (Test-Path $downloadPath)) {
        New-Item -Path $downloadPath -ItemType Directory
    }
    
    # Download installer
    Invoke-WebRequest -Uri $link -UseBasicParsing -OutFile "$downloadPath\$downloadName"

    # Get original UAC settings
    $UAC = (Get-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin).ConsentPromptBehaviorAdmin

    # Disable UAC to complete the install
    Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0

    # Start silent install
    & $downloadPath\$downloadName -s -norestart ACCEPT_EULA=1
}
finally {
    # Renable UAC
    Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value $UAC
}