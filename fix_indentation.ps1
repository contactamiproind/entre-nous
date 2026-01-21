# PowerShell script to fix indentation
$filePath = "d:\Projects\entre-nous\lib\screens\admin\add_question_screen.dart"
$lines = Get-Content $filePath

$output = @()
for ($i = 0; $i < $lines.Count; $i++) {
    if ($i -ge 652 -and $i -lt 1026 -and $lines[$i].Trim() -ne "") {
        # Add 4 spaces to lines 653-1026 (0-indexed: 652-1025)
        $output += "    " + $lines[$i]
    } else {
        $output += $lines[$i]
    }
}

$output | Set-Content $filePath -Encoding UTF8
Write-Host "Indentation fixed successfully!"
Write-Host "Added 4 spaces to lines 653-1026"
