# PowerShell script to replace hardcoded Colors.* with AppColors.* across all Dart files
# Also replaces 'JobConnect' with 'HireNest' in user-facing strings

$libPath = "d:\project\mobile_apps\frontends\jobconnect\lib"

# Get all .dart files except app_colors.dart and app_theme.dart (those are the source of truth)
$files = Get-ChildItem -Path $libPath -Recurse -Filter "*.dart" | Where-Object {
    $_.Name -ne "app_colors.dart" -and $_.Name -ne "app_theme.dart"
}

$modifiedFiles = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $original = $content
    $needsImport = $false

    # === Color replacements ===
    
    # Colors.white -> AppColors.white
    if ($content -match 'Colors\.white(?![\w])') {
        $content = $content -replace 'Colors\.white(?![\w])', 'AppColors.white'
        $needsImport = $true
    }
    
    # Colors.black -> AppColors.black
    if ($content -match 'Colors\.black(?![\w])') {
        $content = $content -replace 'Colors\.black(?![\w])', 'AppColors.black'
        $needsImport = $true
    }
    
    # Colors.black87 -> AppColors.textPrimary
    if ($content -match 'Colors\.black87') {
        $content = $content -replace 'Colors\.black87', 'AppColors.textPrimary'
        $needsImport = $true
    }
    
    # Colors.black54 -> AppColors.grey600
    if ($content -match 'Colors\.black54') {
        $content = $content -replace 'Colors\.black54', 'AppColors.grey600'
        $needsImport = $true
    }
    
    # Colors.black45 -> AppColors.grey500
    if ($content -match 'Colors\.black45') {
        $content = $content -replace 'Colors\.black45', 'AppColors.grey500'
        $needsImport = $true
    }
    
    # Colors.black38 -> AppColors.grey500
    if ($content -match 'Colors\.black38') {
        $content = $content -replace 'Colors\.black38', 'AppColors.grey500'
        $needsImport = $true
    }
    
    # Colors.black26 -> AppColors.grey400
    if ($content -match 'Colors\.black26') {
        $content = $content -replace 'Colors\.black26', 'AppColors.grey400'
        $needsImport = $true
    }
    
    # Colors.black12 -> AppColors.grey200
    if ($content -match 'Colors\.black12') {
        $content = $content -replace 'Colors\.black12', 'AppColors.grey200'
        $needsImport = $true
    }
    
    # Colors.white70 -> AppColors.textLight
    if ($content -match 'Colors\.white70') {
        $content = $content -replace 'Colors\.white70', 'AppColors.textLight'
        $needsImport = $true
    }
    
    # Colors.white54 -> AppColors.grey400
    if ($content -match 'Colors\.white54') {
        $content = $content -replace 'Colors\.white54', 'AppColors.grey400'
        $needsImport = $true
    }
    
    # Colors.white24 -> AppColors.grey300
    if ($content -match 'Colors\.white24') {
        $content = $content -replace 'Colors\.white24', 'AppColors.grey300'
        $needsImport = $true
    }
    
    # Colors.white12 -> AppColors.grey200
    if ($content -match 'Colors\.white12') {
        $content = $content -replace 'Colors\.white12', 'AppColors.grey200'
        $needsImport = $true
    }
    
    # Colors.red -> AppColors.error
    if ($content -match 'Colors\.red(?![\w])') {
        $content = $content -replace 'Colors\.red(?![\w])', 'AppColors.error'
        $needsImport = $true
    }
    
    # Colors.redAccent -> AppColors.error
    if ($content -match 'Colors\.redAccent') {
        $content = $content -replace 'Colors\.redAccent', 'AppColors.error'
        $needsImport = $true
    }
    
    # Colors.green -> AppColors.success
    if ($content -match 'Colors\.green(?![\w])') {
        $content = $content -replace 'Colors\.green(?![\w])', 'AppColors.success'
        $needsImport = $true
    }
    
    # Colors.greenAccent -> AppColors.secondaryLight
    if ($content -match 'Colors\.greenAccent') {
        $content = $content -replace 'Colors\.greenAccent', 'AppColors.secondaryLight'
        $needsImport = $true
    }
    
    # Colors.blue -> AppColors.primary
    if ($content -match 'Colors\.blue(?![\w])') {
        $content = $content -replace 'Colors\.blue(?![\w])', 'AppColors.primary'
        $needsImport = $true
    }
    
    # Colors.blueAccent -> AppColors.primary 
    if ($content -match 'Colors\.blueAccent') {
        $content = $content -replace 'Colors\.blueAccent', 'AppColors.primary'
        $needsImport = $true
    }
    
    # Colors.orange -> AppColors.warning
    if ($content -match 'Colors\.orange(?![\w])') {
        $content = $content -replace 'Colors\.orange(?![\w])', 'AppColors.warning'
        $needsImport = $true
    }
    
    # Colors.amber -> AppColors.accent
    if ($content -match 'Colors\.amber(?![\w])') {
        $content = $content -replace 'Colors\.amber(?![\w])', 'AppColors.accent'
        $needsImport = $true
    }
    
    # Colors.purple -> AppColors.cta
    if ($content -match 'Colors\.purple(?![\w])') {
        $content = $content -replace 'Colors\.purple(?![\w])', 'AppColors.cta'
        $needsImport = $true
    }
    
    # Colors.transparent -> Colors.transparent (keep as-is, it's not a brand color)
    # No change needed
    
    # Colors.grey -> AppColors.grey400
    if ($content -match 'Colors\.grey(?![\w\[])') {
        $content = $content -replace 'Colors\.grey(?![\w\[])', 'AppColors.grey400'
        $needsImport = $true
    }
    
    # Colors.grey[50] -> AppColors.grey50
    if ($content -match 'Colors\.grey\[50\]') {
        $content = $content -replace 'Colors\.grey\[50\]!?', 'AppColors.grey50'
        $needsImport = $true
    }
    
    # Colors.grey[100] -> AppColors.grey100
    if ($content -match 'Colors\.grey\[100\]') {
        $content = $content -replace 'Colors\.grey\[100\]!?', 'AppColors.grey100'
        $needsImport = $true
    }
    
    # Colors.grey[200] -> AppColors.grey200
    if ($content -match 'Colors\.grey\[200\]') {
        $content = $content -replace 'Colors\.grey\[200\]!?', 'AppColors.grey200'
        $needsImport = $true
    }
    
    # Colors.grey[300] -> AppColors.grey300
    if ($content -match 'Colors\.grey\[300\]') {
        $content = $content -replace 'Colors\.grey\[300\]!?', 'AppColors.grey300'
        $needsImport = $true
    }
    
    # Colors.grey[400] -> AppColors.grey400
    if ($content -match 'Colors\.grey\[400\]') {
        $content = $content -replace 'Colors\.grey\[400\]!?', 'AppColors.grey400'
        $needsImport = $true
    }
    
    # Colors.grey[500] -> AppColors.grey500
    if ($content -match 'Colors\.grey\[500\]') {
        $content = $content -replace 'Colors\.grey\[500\]!?', 'AppColors.grey500'
        $needsImport = $true
    }
    
    # Colors.grey[600] -> AppColors.grey600
    if ($content -match 'Colors\.grey\[600\]') {
        $content = $content -replace 'Colors\.grey\[600\]!?', 'AppColors.grey600'
        $needsImport = $true
    }
    
    # Colors.grey[700] -> AppColors.grey700
    if ($content -match 'Colors\.grey\[700\]') {
        $content = $content -replace 'Colors\.grey\[700\]!?', 'AppColors.grey700'
        $needsImport = $true
    }
    
    # Colors.grey[800] -> AppColors.grey800
    if ($content -match 'Colors\.grey\[800\]') {
        $content = $content -replace 'Colors\.grey\[800\]!?', 'AppColors.grey800'
        $needsImport = $true
    }
    
    # Colors.grey[900] -> AppColors.grey900
    if ($content -match 'Colors\.grey\[900\]') {
        $content = $content -replace 'Colors\.grey\[900\]!?', 'AppColors.grey900'
        $needsImport = $true
    }
    
    # Colors.grey.shade* patterns
    if ($content -match 'Colors\.grey\.shade50(?![\d])') {
        $content = $content -replace 'Colors\.grey\.shade50(?![\d])', 'AppColors.grey50'
        $needsImport = $true
    }
    if ($content -match 'Colors\.grey\.shade100') {
        $content = $content -replace 'Colors\.grey\.shade100', 'AppColors.grey100'
        $needsImport = $true
    }
    if ($content -match 'Colors\.grey\.shade200') {
        $content = $content -replace 'Colors\.grey\.shade200', 'AppColors.grey200'
        $needsImport = $true
    }
    if ($content -match 'Colors\.grey\.shade300') {
        $content = $content -replace 'Colors\.grey\.shade300', 'AppColors.grey300'
        $needsImport = $true
    }
    if ($content -match 'Colors\.grey\.shade400') {
        $content = $content -replace 'Colors\.grey\.shade400', 'AppColors.grey400'
        $needsImport = $true
    }
    if ($content -match 'Colors\.grey\.shade500') {
        $content = $content -replace 'Colors\.grey\.shade500', 'AppColors.grey500'
        $needsImport = $true
    }
    if ($content -match 'Colors\.grey\.shade600') {
        $content = $content -replace 'Colors\.grey\.shade600', 'AppColors.grey600'
        $needsImport = $true
    }
    if ($content -match 'Colors\.grey\.shade700') {
        $content = $content -replace 'Colors\.grey\.shade700', 'AppColors.grey700'
        $needsImport = $true
    }
    if ($content -match 'Colors\.grey\.shade800') {
        $content = $content -replace 'Colors\.grey\.shade800', 'AppColors.grey800'
        $needsImport = $true
    }
    if ($content -match 'Colors\.grey\.shade900') {
        $content = $content -replace 'Colors\.grey\.shade900', 'AppColors.grey900'
        $needsImport = $true
    }
    
    # Colors.blue[*] patterns
    if ($content -match 'Colors\.blue\[\d+\]') {
        $content = $content -replace 'Colors\.blue\[\d+\]!?', 'AppColors.primary'
        $needsImport = $true
    }
    
    # Colors.green[*] patterns
    if ($content -match 'Colors\.green\[\d+\]') {
        $content = $content -replace 'Colors\.green\[\d+\]!?', 'AppColors.success'
        $needsImport = $true
    }
    
    # Colors.red[*] patterns
    if ($content -match 'Colors\.red\[\d+\]') {
        $content = $content -replace 'Colors\.red\[\d+\]!?', 'AppColors.error'
        $needsImport = $true
    }
    
    # Colors.orange[*] patterns
    if ($content -match 'Colors\.orange\[\d+\]') {
        $content = $content -replace 'Colors\.orange\[\d+\]!?', 'AppColors.warning'
        $needsImport = $true
    }
    
    # Colors.amber[*] patterns
    if ($content -match 'Colors\.amber\[\d+\]') {
        $content = $content -replace 'Colors\.amber\[\d+\]!?', 'AppColors.accent'
        $needsImport = $true
    }
    
    # Colors.purple[*] patterns
    if ($content -match 'Colors\.purple\[\d+\]') {
        $content = $content -replace 'Colors\.purple\[\d+\]!?', 'AppColors.cta'
        $needsImport = $true
    }
    
    # Colors.indigo -> AppColors.primary
    if ($content -match 'Colors\.indigo') {
        $content = $content -replace 'Colors\.indigo(?:\[\d+\])?!?', 'AppColors.primary'
        $needsImport = $true
    }
    
    # Colors.teal -> AppColors.secondary
    if ($content -match 'Colors\.teal') {
        $content = $content -replace 'Colors\.teal(?:\[\d+\])?!?', 'AppColors.secondary'
        $needsImport = $true
    }
    
    # Colors.deepPurple -> AppColors.cta
    if ($content -match 'Colors\.deepPurple') {
        $content = $content -replace 'Colors\.deepPurple(?:\[\d+\])?!?', 'AppColors.cta'
        $needsImport = $true
    }
    
    # Colors.blueGrey -> AppColors.grey600
    if ($content -match 'Colors\.blueGrey') {
        $content = $content -replace 'Colors\.blueGrey(?:\[\d+\])?!?', 'AppColors.grey600'
        $needsImport = $true
    }

    # Colors.yellow -> AppColors.accent
    if ($content -match 'Colors\.yellow(?![\w])') {
        $content = $content -replace 'Colors\.yellow(?![\w])', 'AppColors.accent'
        $needsImport = $true
    }
    
    # Colors.pink -> AppColors.error (keep for freelance-related if needed)
    if ($content -match 'Colors\.pink(?![\w])') {
        $content = $content -replace 'Colors\.pink(?![\w])', 'AppColors.error'
        $needsImport = $true
    }
    
    # Colors.cyan -> AppColors.info
    if ($content -match 'Colors\.cyan') {
        $content = $content -replace 'Colors\.cyan(?:\[\d+\])?!?', 'AppColors.info'
        $needsImport = $true
    }
    
    # === 'JobConnect' -> 'HireNest' replacements (only in string literals) ===
    if ($content -match "'JobConnect'") {
        $content = $content -replace "'JobConnect'", "'HireNest'"
    }
    
    # === Add import if needed ===
    if ($needsImport -and $content -notmatch "import.*app_colors\.dart") {
        # Calculate relative import path
        $relativePath = $file.FullName.Replace("$libPath\", "").Replace("\", "/")
        $depth = ($relativePath.Split("/").Count - 1)
        $prefix = "../" * $depth
        $importLine = "import '${prefix}core/theme/app_colors.dart';"
        
        # Add import after existing imports
        if ($content -match "import 'package:flutter/material\.dart';") {
            $content = $content -replace "(import 'package:flutter/material\.dart';)", "`$1`n$importLine"
        }
    }
    
    # Write if changed
    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $modifiedFiles += $file.FullName.Replace("$libPath\", "")
    }
}

Write-Host "`n=== FILES MODIFIED ===" -ForegroundColor Green
foreach ($f in $modifiedFiles) {
    Write-Host "  ✅ $f" -ForegroundColor Cyan
}
Write-Host "`nTotal files modified: $($modifiedFiles.Count)" -ForegroundColor Yellow
