function New-vtsRandomPassword {
    $numbers = 0..9
    $symbols = '!', '@', '#', '$', '%', '*', '?', '+', '='
    $string = ( -join ((0x30..0x39) + ( 0x41..0x5A) + ( 0x61..0x7A) |
            Get-Random -Count 12  |
            ForEach-Object { [char]$_ }))
    $number = $numbers | Get-Random
    $symbol = $symbols | Get-Random
    $NewPW = $string + $number + $symbol

    $NewPW | Set-Clipboard

    Write-Output "Random Password Copied to Clipboard"
}

	