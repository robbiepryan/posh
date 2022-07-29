#Add the required assembly
add-type -AssemblyName System.Windows.Forms
#Send Alt-Tab to bring focus back to selected window
[System.Windows.Forms.SendKeys]::SendWait(("%{TAB}"))
#Wait 100 milliseconds
Start-Sleep -Milliseconds 100
#Paste Contents
[System.Windows.Forms.SendKeys]::SendWait(($(Get-Clipboard)))
