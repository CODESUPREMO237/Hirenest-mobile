# Fix remaining JobConnect references
$libPath = "d:\project\mobile_apps\frontends\jobconnect\lib"
$files = Get-ChildItem -Path $libPath -Recurse -Filter "*.dart"
$count = 0

foreach ($f in $files) {
    $c = Get-Content $f.FullName -Raw
    $o = $c
    $c = $c -replace 'JobConnect', 'HireNest'
    if ($c -ne $o) {
        Set-Content -Path $f.FullName -Value $c -NoNewline
        $count++
        Write-Host $f.Name
    }
}

Write-Host "Fixed $count files"
