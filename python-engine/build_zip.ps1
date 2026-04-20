    # Configuration
    $PythonVer = "3.12.6"
    $WorkDir = "build_temp"
    $DistZip = "../spade/assets/python_dist.zip" 

    # Clean Setup
    Write-Host "[INFO] Cleaning up..." -ForegroundColor Cyan
    if (Test-Path $WorkDir) { Remove-Item -Recurse -Force $WorkDir }
    if (Test-Path $DistZip) { Remove-Item -Force $DistZip }

    # Create the work dir
    New-Item -ItemType Directory -Path $WorkDir | Out-Null

    # Ensure the destination directory actually exists before zipping
    $DestDir = Split-Path -Parent $DistZip
    if (-not (Test-Path $DestDir)) {
        Write-Host "[INFO] Creating assets directory..."
        New-Item -ItemType Directory -Path $DestDir | Out-Null
    }

    # Download Python Embeddable (Minimal Portable Python)
    Write-Host "[INFO] Downloading Portable Python $PythonVer..."
    $Url = "https://www.python.org/ftp/python/$PythonVer/python-$PythonVer-embed-amd64.zip"
    Invoke-WebRequest -Uri $Url -OutFile "$WorkDir/python.zip"

    Expand-Archive -Path "$WorkDir/python.zip" -DestinationPath "$WorkDir/python"
    Remove-Item "$WorkDir/python.zip"

    # Enable Pip (Uncomment 'import site' in python._pth)
    $PthFile = Get-ChildItem "$WorkDir/python/python*._pth" | Select-Object -First 1
    (Get-Content $PthFile.FullName) -replace "#import site", "import site" | Set-Content $PthFile.FullName

    # Install Pip and Dependencies
    Write-Host "[INFO] Installing dependencies..."
    Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile "$WorkDir/python/get-pip.py"

    & "$WorkDir/python/python.exe" "$WorkDir/python/get-pip.py" --no-warn-script-location

    if (Test-Path "requirements.txt") {
        & "$WorkDir/python/python.exe" -m pip install -r requirements.txt --no-warn-script-location
    }

    # Copy project code (new src layout)
    Write-Host "[INFO] Copying project source..."
    
    # Create the 'src' directory inside the portable python folder
    $TargetSrc = "$WorkDir/python/src"
    if (-not (Test-Path $TargetSrc)) {
        New-Item -ItemType Directory -Path $TargetSrc | Out-Null
    }

    # Add an __init__.py so Python treats 'src' as a package
    New-Item -ItemType File -Path "$TargetSrc/__init__.py" -Force | Out-Null

    # Copy modules INTO the new 'src' directory
    foreach ($module in @("analysis", "data_io", "plotting", "cli", "utils")) {
        $modulePath = "src/$module"
        if (Test-Path $modulePath) {
            Copy-Item $modulePath "$TargetSrc/" -Recurse
        }
    }

    # Keep Flutter runtime compatibility: it executes `python.exe main.py`
    if (Test-Path "src/cli/main.py") {
        Copy-Item "src/cli/main.py" "$WorkDir/python/main.py" -Force
    }

    # Optional utility script
    if (Test-Path "src/cli/extract_info.py") {
        Copy-Item "src/cli/extract_info.py" "$WorkDir/python/extract_info.py" -Force
    }

    # Zip it all up
    Write-Host "[INFO] Zipping portable environment to $DistZip..."
    $CompressFiles = Get-ChildItem -Path "$WorkDir/python/*"
    Compress-Archive -Path $CompressFiles -DestinationPath $DistZip -Force

    Write-Host "[SUCCESS] Done! Created $DistZip" -ForegroundColor Green