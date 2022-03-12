<#
.SYNOPSIS
  This script parses two files ($file1 and $file2) and outputs the results to a third file ($output) as well as writing to the console.
  
#>


## FILES IN USE
$file1="C:\Stuff\1.txt"
$file2="C:\Stuff\2.txt"
$output="C:\Stuff\3.txt"

## IF THE OUTPUT FILE ALREADY EXISTS, REMOVE IT
if (Test-Path $output) {
  Remove-Item $output
}

## ASSIGN FILENAMES SO THAT OUTPUT MATCHES EXAMPLE EXACTLY
$filename1="1"
$filename2="2"

## THE AMOUNT OF DIFFERENCES FOUND BETWEEN THE TWO FILES; STARTS AT 0
$diffCount=0

## THE LINE NUMBER TO BEGIN COMPARING DIFFERENCES ON; START AT 0
$lineNumber=0

## GET THE NUMBER OF LINES IN EACH OF THE INPUT FILES
$lineCount1=(Get-Content $file1).Length
$lineCount2=(Get-Content $file2).Length

## FIGURE OUT WHICH INPUT FILE HAS MORE LINES, THEN SET $linecount TO THAT VALUE;
## THIS ALLOWS THE WHILE CONDITION BELOW TO LOOP THROUGH THE APPROPRIATE AMOUNT OF TIMES
if ($lineCount1 -ge $lineCount2) {
    $linecount=$linecount1
}
    else {
        $linecount=$lineCount2
    }


## COUNTER STARTS AT 0 AND WILL CONTINUE UNTIL IT'S EQUAL TO $linecount
$counter=0

while ($counter -le $linecount) {

    $content1=(Get-Content $file1)[$lineNumber] ## GETS THE FILE1 CONTENTS OF A PARTICULAR LINE
    $content2=(Get-Content $file2)[$lineNumber] ## GETS THE FILE2 CONTENTS OF THE SAME LINE

## COMPARES THE PARTICULAR LINE OF FILE1 TO THE SAME LINE OF FILE2;
## IF THE LINES DON'T MATCH, APPEND <File Name>:<Line Number>: <Line Content> ; <File Name>:<Line Number>: <Line Content> TO OUTPUT FILE AND WRITE TO CONSOLE
    if($content1 -cne $content2)
            {Write-Host $filename1":"$lineNumber": "$content1";" $filename2":"$lineNumber": "$content2; 
             Write-Output ($filename1 + ":" + $lineNumber + ": " + $content1 + "; " + $filename2 + ":" + $lineNumber + ": " + $content2) | Out-File $output -Append;
             $diffCount++} ## INCREMENT THE DIFFERENCE COUNT BY 1

## IF THE LINES DO MATCH, APPEND <Line Content> TO OUTPUT FILE AND WRITE TO CONSOLE
        Else {Write-Host $content1;
              Write-Output $content1 | Out-File $output -Append}

## INCREMENT BOTH THE LINE NUMBER AND COUNTER BY 1
    $lineNumber++
    $counter++
}

## DISPLAY THE NUMBER OF DIFFERENCES FOUND TO THE OUTPUT FILE AND THE CONSOLE
Write-Host "Differences Found:"$diffCount
Write-Output "Differences Found:$diffCount" | Out-File $output -Append
