# Rename Arabic audio files to ASCII names
# Works by sorted order - no Arabic text needed!
# Run from project root: PowerShell -ExecutionPolicy Bypass -File rename_by_order.ps1

$audioDir = "assets\audio"

# Get all mp3 files sorted alphabetically (Arabic sort = same order as Arabic alphabet)
$files = Get-ChildItem -Path $audioDir -Filter "*.mp3" | Sort-Object Name

if ($files.Count -eq 0) {
    Write-Host "No mp3 files found in $audioDir" -ForegroundColor Red
    exit
}

Write-Host "Found $($files.Count) mp3 files" -ForegroundColor Cyan

# The ASCII names in the SAME sorted order as the Arabic filenames
# (Arabic alphabetical: alef, ba, ha, ain, meem, shin...)
$asciiNames = @(
    "adhan_shaisha.mp3",        # 1. ابوالعينين شعيشع
    "adhan_ahmed_jalal.mp3",   # 2. احمد جلال يحيى
    "adhan_makkah.mp3",        # 3. اذان ,الحرم المكي...
    "adhan_belbashir.mp3",     # 4. بلبشير عبد القادر
    "adhan_hamza_majali.mp3",  # 5. حمزة المجالي
    "adhan_abdulbasit.mp3",    # 6. عبد الباسط عبد الصمد
    "adhan_refat.mp3",         # 7. محمد رفعت
    "adhan_minshawi.mp3",      # 8. محمد صديق المنشاوي
    "adhan_alafasy.mp3",       # 9. مشاري بن راشد العفاسي
    "adhan_mustafa_ismail.mp3" # 10. مصطفى اسماعيل
)

if ($files.Count -ne $asciiNames.Count) {
    Write-Host "Expected 10 files, found $($files.Count). Listing them:" -ForegroundColor Yellow
    $files | ForEach-Object { Write-Host "  $($_.Name)" }
    exit
}

for ($i = 0; $i -lt $files.Count; $i++) {
    $oldPath = $files[$i].FullName
    $newPath = Join-Path $audioDir $asciiNames[$i]
    Rename-Item -LiteralPath $oldPath -NewName $asciiNames[$i]
    Write-Host "OK: [$($i+1)] -> $($asciiNames[$i])" -ForegroundColor Green
}

Write-Host ""
Write-Host "All done! Now run: flutter run" -ForegroundColor Cyan
