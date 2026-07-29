# Fix corrupted AppAppAppColors and AppAppColors to just AppColors
# Also fix remaining JobConnect references and any leftover Colors.*

$libPath = "d:\project\mobile_apps\frontends\jobconnect\lib"
$files = Get-ChildItem -Path $libPath -Recurse -Filter "*.dart" | Where-Object {
    $_.Name -ne "app_colors.dart" -and $_.Name -ne "app_theme.dart"
}

$modifiedFiles = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $original = $content
    
    # Fix triple/double prefix corruption
    $content = $content -replace 'AppAppAppColors\.', 'AppColors.'
    $content = $content -replace 'AppAppColors\.', 'AppColors.'
    
    # Fix any duplicate imports
    $importLine = "import '.*app_colors\.dart';"
    $matches2 = [regex]::Matches($content, $importLine)
    if ($matches2.Count -gt 1) {
        # Remove all but the first import
        $first = $true
        foreach ($m in $matches2) {
            if ($first) {
                $first = $false
                continue
            }
            $content = $content.Remove($m.Index, $m.Length)
        }
    }
    
    # Replace remaining 'JobConnect' in strings (but not in commented code or URLs)
    $content = $content -replace "'JobConnect'", "'HireNest'"
    
    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $modifiedFiles += $file.FullName.Replace("$libPath\", "")
    }
}

Write-Host "Fixed $($modifiedFiles.Count) files"
foreach ($f in $modifiedFiles) {
    Write-Host "  $f"
}
