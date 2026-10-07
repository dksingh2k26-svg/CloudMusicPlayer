# Builds CloudMusicPlayer into a debug APK on Windows. No admin rights needed.
# Run from the project folder (the one containing settings.gradle.kts):
#   powershell -ExecutionPolicy Bypass -File .\build-apk.ps1
$ErrorActionPreference = "Stop"

# Locate the project (the folder with settings.gradle.kts) next to this script or in a subfolder
$proj = @($PSScriptRoot, (Get-Location).Path) | Where-Object { $_ -and (Test-Path "$_\settings.gradle.kts") } | Select-Object -First 1
if (-not $proj) {
    $hit = Get-ChildItem $PSScriptRoot -Recurse -Depth 3 -Filter settings.gradle.kts -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { $proj = $hit.DirectoryName }
}
if (-not $proj) { throw "Project not found. Unzip CloudMusicPlayer_v0_4_tdlib.zip and run this script from inside the CloudMusicPlayer folder (it must contain settings.gradle.kts)." }
Set-Location $proj
Write-Host "Building project in $proj"
$ProgressPreference = "SilentlyContinue"   # much faster downloads

$tools   = Join-Path $env:USERPROFILE "android-build"
$jdkDir  = Join-Path $tools "jdk17"
$sdkDir  = Join-Path $tools "android-sdk"
$gradleV = "8.11.1"
$gradleDir = Join-Path $tools "gradle-$gradleV"
New-Item -ItemType Directory -Force $tools | Out-Null

function Get-Zip($url, $dest) {
    $zip = Join-Path $tools ([IO.Path]::GetRandomFileName() + ".zip")
    Write-Host "Downloading $url"
    Invoke-WebRequest $url -OutFile $zip
    Expand-Archive $zip -DestinationPath $dest -Force
    Remove-Item $zip
}

# 1) JDK 17
if (-not (Test-Path "$jdkDir\bin\java.exe")) {
    Get-Zip "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse" "$tools\jdk-tmp"
    Move-Item (Get-ChildItem "$tools\jdk-tmp" -Directory | Select-Object -First 1).FullName $jdkDir
    Remove-Item "$tools\jdk-tmp" -Recurse -Force
}

# 2) Gradle
if (-not (Test-Path "$gradleDir\bin\gradle.bat")) {
    Get-Zip "https://services.gradle.org/distributions/gradle-$gradleV-bin.zip" $tools
}

# 3) Android SDK command-line tools
$sdkmanager = "$sdkDir\cmdline-tools\latest\bin\sdkmanager.bat"
if (-not (Test-Path $sdkmanager)) {
    Get-Zip "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip" "$tools\cmd-tmp"
    New-Item -ItemType Directory -Force "$sdkDir\cmdline-tools" | Out-Null
    Move-Item "$tools\cmd-tmp\cmdline-tools" "$sdkDir\cmdline-tools\latest"
    Remove-Item "$tools\cmd-tmp" -Recurse -Force
}

$env:JAVA_HOME = $jdkDir
$env:ANDROID_HOME = $sdkDir
$env:ANDROID_SDK_ROOT = $sdkDir
$env:Path = "$jdkDir\bin;$gradleDir\bin;$env:Path"

# 4) SDK packages + licenses
Write-Host "Accepting licenses and installing SDK packages (first run takes a few minutes)..."
1..30 | ForEach-Object { "y" } | & $sdkmanager --sdk_root=$sdkDir --licenses | Out-Null
& $sdkmanager --sdk_root=$sdkDir "platform-tools" "platforms;android-36" "build-tools;36.0.0"

# 5) Point Gradle at the SDK and build
"sdk.dir=$($sdkDir -replace '\\','/')" | Set-Content -Encoding ASCII "local.properties"
$log = Join-Path ([Environment]::GetFolderPath("Desktop")) "build-log.txt"
cmd /c "gradle assembleDebug --no-daemon --console=plain > `"$log`" 2>&1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n--- Errors ---"
    Select-String -Path $log -Pattern "^e: |What went wrong|Could not resolve|error:|FAILED" -Context 0,3 | Select-Object -First 40 | ForEach-Object { $_.Line; $_.Context.PostContext }
    throw "Build failed. Full log saved to $log - send that file (or the lines above) to Claude."
}

$apk = Get-ChildItem "app\build\outputs\apk\debug\*.apk" | Select-Object -First 1
$out = Join-Path ([Environment]::GetFolderPath("Desktop")) "CloudMusicPlayer-debug.apk"
Copy-Item $apk.FullName $out -Force
Write-Host "`nDONE: $out"
