@echo off
setlocal enabledelayedexpansion

:: Use the directory where this .bat file lives (no Chinese chars needed)
set "PROJECT=%~dp0"
set "VIDEO_DIR=%PROJECT%assets\video"
set "COMP_DIR=%PROJECT%assets\video_compressed"

echo ================================================================
echo   Affordance_LTL - Full Deployment Pipeline
echo ================================================================
echo.
echo Project: %PROJECT%
echo.

:: ========================================
:: Step 1: Check ffmpeg
:: ========================================
echo === STEP 1: Check ffmpeg ===
where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo [ERROR] ffmpeg not found! Install with: winget install ffmpeg
    goto :fail
)
echo [OK] ffmpeg found
echo.

:: ========================================
:: Step 2: Compress videos
:: ========================================
echo === STEP 2: Compress 24 videos to 1080p ===
echo This may take 10-30 minutes...
echo.

if not exist "%COMP_DIR%" mkdir "%COMP_DIR%"

:: Process all source mp4 files using a mapping approach
:: We use a temp file to store the mapping to avoid Chinese chars in this script
cd /d "%PROJECT%"

:: Write mapping to a temp file using PowerShell (it can handle the filenames)
powershell -Command "& { $map = @{'1.静态：整理桌面.mp4'='1_tidy_desk.mp4';'2. 静态：我饿了.mp4'='2_hungry.mp4';'3. 静态：补充蛋白质.mp4'='3_protein.mp4';'4. 静态：帮我准备两个人的实物.mp4'='4_prepare_food_two.mp4';'5. 静态：称重.mp4'='5_weigh.mp4';'6. 静态：倒茶.mp4'='6_pour_tea.mp4';'7. 静态：我困了.mp4'='7_sleepy.mp4';'8. 静态：花枯萎了.mp4'='8_wilted_flower.mp4';'9. 静态：扫垃圾.mp4'='9_sweep.mp4';'10.静态：准备早餐.mp4'='10_breakfast.mp4';'11. 茶叶清理.mp4'='11_clean_tea.mp4';'12.倒茶.mp4'='12_pour_tea.mp4';'13. 钉钉子.mp4'='13_hammer_nail.mp4';'14.切豆腐.mp4'='14_cut_tofu.mp4';'15.倒水并保温.mp4'='15_pour_water_warm.mp4';'16. 倒开水.mp4'='16_pour_hot_water.mp4';'17.舀咖啡.mp4'='17_scoop_coffee.mp4';'18. 搅拌咖啡.mp4'='18_stir_coffee.mp4';'19.浇水.mp4'='19_water_plant.mp4';'20.倒牛奶.mp4'='20_pour_milk.mp4';'21.清理茶叶.mp4'='21_clean_tea_leaves.mp4';'22. 倒茶.mp4'='22_pour_tea.mp4';'23. 倒开水.mp4'='23_pour_hot_water.mp4';'24.做咖啡.mp4'='24_make_coffee.mp4'}; $videoDir='%VIDEO_DIR%'; $compDir='%COMP_DIR%'; $i=0; $total=$map.Count; foreach($entry in $map.GetEnumerator()){$i++; $src=Join-Path $videoDir $entry.Key; $dst=Join-Path $compDir $entry.Value; if(-not(Test-Path $src)){Write-Host \"[$i/$total] SKIP: $($entry.Key)\";continue}; if(Test-Path $dst){Write-Host \"[$i/$total] EXISTS: $($entry.Value)\";continue}; Write-Host \"[$i/$total] $($entry.Key) -> $($entry.Value)\"; & ffmpeg -y -i $src -vf 'scale=-2:1080' -c:v libx264 -crf 28 -preset slow -profile:v main -pix_fmt yuv420p -an -movflags +faststart -r 24 $dst -loglevel warning; if(Test-Path $dst){Write-Host '  [OK]'}else{Write-Host '  [FAIL]'}} }"

echo.
echo [OK] Compression complete!
echo.

:: ========================================
:: Step 3: Copy compressed videos
:: ========================================
echo === STEP 3: Copy compressed to assets/video/ ===
copy /y "%COMP_DIR%\*.mp4" "%VIDEO_DIR%\" >nul 2>&1
echo [OK] Copied
echo.

:: ========================================
:: Step 4: Git init and push
:: ========================================
echo === STEP 4: Git push to GitHub ===
cd /d "%PROJECT%"

if not exist ".git" (
    git init
    git branch -M main
)
git config core.quotepath false

git remote remove origin >nul 2>&1
git remote add origin https://github.com/tamp-ltl/Affordance_LTL.git

:: Add files
git add index.html
git add README.md >nul 2>&1
git add assets/*.jpg assets/*.png assets/*.pdf >nul 2>&1

:: Add compressed English-named videos
for %%F in ("%VIDEO_DIR%\*_*.mp4") do (
    git add "assets/video/%%~nxF"
    echo   Added: %%~nxF
)

echo.
git status
echo.
git commit -m "Deploy with compressed 1080p videos"
echo.
git push -u origin main

echo.
echo ================================================================
echo   ALL DONE!
echo   Visit: https://tamp-ltl.github.io/Affordance_LTL/
echo ================================================================

goto :end

:fail
echo Deployment failed!

:end
echo.
pause
