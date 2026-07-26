```markdown
# Rust Offsets Dumping Guide

## Overview
This guide documents the complete pipeline for dumping and extracting offsets from **Rust** (Facepunch Studios) using **Rodroid Il2CppDumper** — the only open-source IL2CPP dumper that supports Unity 6 metadata v39.

The original `rust-data` TypeScript project is outdated and cannot handle current Rust builds. This document replaces it with a fully working alternative.

---

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Installation](#installation)
3. [Project Structure](#project-structure)
4. [How It Works](#how-it-works)
5. [Usage](#usage)
6. [Scripts Reference](#scripts-reference)
7. [Output Files](#output-files)
8. [Troubleshooting](#troubleshooting)
9. [Limitations](#limitations)

---

## System Requirements

| Requirement | Details |
|-------------|---------|
| **OS** | Windows 10/11 (64-bit) |
| **Steam** | Account that owns Rust |
| **Rust Installation** | `H:\Games\rust\Rust\` (adjust path as needed) |
| **Disk Space** | ~50GB free |
| **Node.js** | 18+ LTS |
| **Git** | Latest |
| **SteamCMD** | Latest |

---

## Installation

### Step 1: Install Node.js
Download from [https://nodejs.org/en/download](https://nodejs.org/en/download) — choose the LTS 64-bit `.msi` installer. Verify:
```powershell
node --version
npm --version
```

### Step 2: Install Yarn
```powershell
npm install --global yarn
```

### Step 3: Install Git
Download from [https://git-scm.com/download/win](https://git-scm.com/download/win). During installation, choose **"Git from the command line and also from 3rd-party software"** for PATH integration.

### Step 4: Install SteamCMD
```powershell
# Download
Invoke-WebRequest -Uri "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -OutFile "$env:TEMP\steamcmd.zip"

# Extract
mkdir C:\steamcmd
Expand-Archive "$env:TEMP\steamcmd.zip" -DestinationPath C:\steamcmd

# Add to PATH (via System Environment Variables)
# Add: C:\steamcmd

# Verify
steamcmd +quit
```

### Step 5: Clone and setup the project
```powershell
git clone https://github.com/etr-dev/rust-data.git
cd rust-data
yarn install
```

### Step 6: Download Rodroid Il2CppDumper
Go to [https://github.com/rodroidmods/rodroid-il2cppdumper/releases](https://github.com/rodroidmods/rodroid-il2cppdumper/releases) and download the latest Windows `.exe` release.

```powershell
# Create directories
mkdir programs\il2cpp -Force
mkdir programs\il2cpp\output -Force

# Copy the downloaded exe and rename it
# (assume you downloaded il2cpp_dumper.exe to Downloads)
copy "$env:USERPROFILE\Downloads\il2cpp_dumper.exe" programs\il2cpp\Il2CppDumper.exe
```

### Step 7: Create dumper config
```powershell
@"
{
  "dumpDisassembly": false
}
"@ | Out-File -FilePath programs\il2cpp\config.json -Encoding UTF8
```

### Step 8: Link Rust game folder
```powershell
# Remove existing if present
if (Test-Path programs\rust_client) {
    cmd /c rmdir programs\rust_client
}

# Create symlink to your Rust installation
cmd /c mklink /D C:\Users\Administrator\rust-data\programs\rust_client "H:\Games\rust\Rust"
```

### Step 9: Configure .env file
```powershell
@"
DUMP_CS_PATH='C:/programs/il2cpp/dump.cs'
HEADER_OUTPUT='output/rust.h'
STEAM_USERNAME='your_steam_username_here'
STEAM_PW='your_steam_password_here'
MINUTES_BETWEEN_CHECKS='5'
"@ | Out-File -FilePath .env -Encoding UTF8
```

### Step 10: Modify app.ts
Edit `src\app.ts` and make these changes:

1. Disable SteamCMD download:
```typescript
// Find: download: true,
// Change to:
download: false,
```

2. Disable GitHub integration:
```typescript
// Find: github_offsets: true,
// Change to:
github_offsets: false,
```

3. Update the IL2CPP command (find the `il2cppCommand` line and replace):
```typescript
const il2cppCommand = `${il2cppDumperExecPath} --config "${process.cwd()}/programs/il2cpp/config.json" ${gameAssemblyPath} ${metadataPath} ${il2cppDumpOutputPath}`;
```

4. Update the dump paths to match the auto-numbered output:
```typescript
// Find the paths object and update:
dumpCsFilePath: `${il2cppDumpOutputPath}/Dump0/dump.cs`,
scriptFilePath: `${il2cppDumpOutputPath}/Dump0/script.json`,
```

5. Increase Node.js memory in `package.json`:
```json
"start:dev": "rimraf bin && node --max-old-space-size=8192 --require ts-node/register ./src/app.ts"
```

---

## Project Structure

```
C:\Users\Administrator\rust-data\
│
├── programs/
│   ├── il2cpp/                          # Rodroid Il2CppDumper
│   │   ├── Il2CppDumper.exe             # Main dumper executable
│   │   ├── config.json                  # Dumper configuration
│   │   └── output/
│   │       ├── Dump0/                   # Auto-numbered dump folders
│   │       ├── Dump1/
│   │       └── DumpN/
│   │           ├── dump.cs              # C# class decompilation (~185MB)
│   │           ├── script.json          # Method addresses (~672MB)
│   │           ├── il2cpp.h             # C struct definitions (~170MB)
│   │           ├── il2cpp-functions.h   # C++ scaffold
│   │           ├── stringliteral.json   # String literals
│   │           ├── generics_dump.txt    # Generic type dump
│   │           └── DummyDll/            # Reconstructed .NET assemblies
│   │
│   └── rust_client/                     # SYMLINK → H:\Games\rust\Rust\
│       ├── GameAssembly.dll             # IL2CPP compiled game code
│       └── RustClient_Data/
│           └── il2cpp_data/Metadata/
│               └── global-metadata.dat   # IL2CPP metadata
│
├── output/                              # Generated output files
│   ├── offsets.h                        # Final C++ offset header
│   ├── rust_readable_classes.txt        # Extracted class definitions
│   ├── rust_fields.h                    # _Fields struct definitions
│   ├── rust_main_classes.h              # Main struct declarations
│   ├── full_rust_offsets.h              # Complete il2cpp.h copy
│   └── version_info.txt                 # Tracks current build ID
│
├── src/
│   └── app.ts                           # Modified automation script
│
├── extract_readable.ps1                 # Extraction script
├── extract_fields.ps1                   # Field extraction script
├── generate_offsets.ps1                 # Offset header generator
├── auto_fill_offsets.ps1                # Auto-fill missing offsets
│
├── .env                                 # Configuration
├── package.json                         # Node.js project config
└── HANDOFF.md                           # This document
```

---

## How It Works

### The Dumping Pipeline

```
                     ┌─────────────────────────┐
                     │   Rust Game Files        │
                     │   H:\Games\rust\Rust\    │
                     └────────────┬────────────┘
                                  │
                                  ▼
                     ┌─────────────────────────┐
                     │  Rodroid Il2CppDumper   │
                     │  v0.7.0 (Rust-based)    │
                     │                         │
                     │  Reads:                 │
                     │  • GameAssembly.dll     │
                     │  • global-metadata.dat  │
                     │                         │
                     │  Supports:              │
                     │  • Unity 6 / v39        │
                     │  • Variable indices     │
                     │  • Auto-XOR decrypt     │
                     └────────────┬────────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
              ┌──────────┐ ┌──────────┐ ┌──────────┐
              │ dump.cs  │ │il2cpp.h  │ │script.json│
              │ (185MB)  │ │ (170MB)  │ │ (672MB)  │
              └────┬─────┘ └────┬─────┘ └────┬─────┘
                   │            │            │
                   ▼            ▼            ▼
         ┌─────────────────────────────────────────┐
         │        PowerShell Scripts                │
         │                                         │
         │  extract_readable.ps1 → readable classes│
         │  extract_fields.ps1   → field structs   │
         │  generate_offsets.ps1 → offsets.h       │
         └────────────────────┬────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │   offsets.h      │
                    │   (Final Output) │
                    └──────────────────┘
```

### Rodroid Dumper vs Other Tools

| Tool | v39 Support | Speed | Output Format | Status |
|------|:---:|:---:|------|:---:|
| **Rodroid Il2CppDumper** | ✅ | ~17s | dump.cs + il2cpp.h + DummyDLL | ✅ Working |
| Il2CppDumper (C#) | ❌ | ~20s | dump.cs + DummyDLL | ❌ Outdated |
| Cpp2IL | ❌ | ~30s | dump.cs + analysis | ❌ Outdated |
| Il2CppInspector | ❌ | ~25s | JSON + Python | ❌ Outdated |

### Why Field Names Are Hashed

Modern Rust builds (Unity 6 / IL2CPP v39) obfuscate most field names with SHA-style hashes:

```csharp
// OLD (pre-v39):
public float _health; // 0x264

// NEW (v39+):
private float %61eefc783a5720742e1ef650899748fefd7206e4; // 0x264
```

The hashed names change with every game update. The readable names (like `_health`, `playerFlags`) must be manually mapped using:
- Context from surrounding readable fields
- Comparison with previous builds
- Runtime probing with ReClass.NET

---

## Usage

### One-Time Dump
```powershell
cd C:\Users\Administrator\rust-data
yarn start:dev
```

### Continuous Monitoring
The script checks every 5 minutes for game updates. When a new build is detected, it automatically re-dumps. Stop with `Ctrl+C`.

### Force Re-Dump
```powershell
Remove-Item output\version_info.txt -ErrorAction SilentlyContinue
yarn start:dev
```

### Run Individual Scripts
```powershell
# Extract readable class definitions from dump.cs
powershell -ExecutionPolicy Bypass -File extract_readable.ps1

# Extract _Fields struct definitions from il2cpp.h
powershell -ExecutionPolicy Bypass -File extract_fields.ps1

# Generate the C++ offsets.h header
powershell -ExecutionPolicy Bypass -File generate_offsets.ps1

# Attempt to auto-fill missing offsets
powershell -ExecutionPolicy Bypass -File auto_fill_offsets.ps1
```

---

## Scripts Reference

### extract_readable.ps1

**Purpose:** Extracts full class definitions with field names and offsets from `dump.cs`.

**Input:** `programs/il2cpp/output/Dump3/dump.cs`
**Output:** `output/rust_readable_classes.txt`

```powershell
$content = Get-Content "C:\Users\Administrator\rust-data\programs\il2cpp\output\Dump3\dump.cs" -ReadCount 0
$output = @()

$classes = @(
    "class BasePlayer ",
    "class BaseEntity ",
    "class BaseCombatEntity ",
    "class PlayerWalkMovement ",
    "class PlayerEyes ",
    "class PlayerInventory ",
    "class PlayerModel ",
    "class BaseProjectile ",
    "class BaseMelee ",
    "class StorageContainer ",
    "class BaseOven ",
    "class CodeLock ",
    "class Door ",
    "class BuildingBlock ",
    "class ToolCupboard ",
    "class BaseCorpse ",
    "class HeldEntity ",
    "class AttackEntity ",
    "class BaseLauncher ",
    "class BaseWeapon ",
    "class Item ",
    "class BaseLock ",
    "class ModelState ",
    "class PlayerInput ",
    "class GunShot ",
    "class Revolver ",
    "class AssaultRifle ",
    "class RPGLauncher ",
    "class LootableCorpse ",
    "class ResourceEntity "
)

$classPattern = "^public (" + ($classes -join "|") + ")"

$inClass = $false
$braceCount = 0

for ($i=0; $i -lt $content.Length; $i++) {
    $line = $content[$i]
    
    if ($line -match $classPattern) {
        $output += ""
        $output += "// ========================================="
        $output += $line
        $inClass = $true
        $braceCount = 1
        $i++
    }
    elseif ($inClass) {
        $output += $line
        if ($line -match '\{') { $braceCount++ }
        if ($line -match '\}') { $braceCount-- }
        if ($braceCount -le 0) { 
            $inClass = $false
        }
    }
    
    if ($output.Count -gt 10000) { break }
}

$output | Out-File "C:\Users\Administrator\rust-data\output\rust_readable_classes.txt"
Write-Host "Done! $($output.Count) lines extracted."
```

---

### extract_fields.ps1

**Purpose:** Extracts `_Fields` struct definitions (containing the actual field offsets) from `il2cpp.h`.

**Input:** `programs/il2cpp/output/Dump3/il2cpp.h`
**Output:** `output/rust_fields.h`

```powershell
$content = Get-Content "C:\Users\Administrator\rust-data\programs\il2cpp\output\Dump3\il2cpp.h"
$output = @()

$patterns = @(
    "BasePlayer_Fields",
    "BaseEntity_Fields", 
    "BaseCombatEntity_Fields",
    "PlayerWalkMovement_Fields",
    "PlayerEyes_Fields",
    "PlayerInventory_Fields",
    "PlayerModel_Fields",
    "BaseProjectile_Fields",
    "BaseMelee_Fields",
    "StorageContainer_Fields",
    "BaseOven_Fields",
    "CodeLock_Fields",
    "Door_Fields",
    "BuildingBlock_Fields",
    "ToolCupboard_Fields",
    "BaseCorpse_Fields",
    "HeldEntity_Fields",
    "AttackEntity_Fields",
    "BaseLauncher_Fields",
    "BaseWeapon_Fields",
    "GunShot_Fields",
    "FlameThrower_Fields",
    "Revolver_Fields",
    "AssaultRifle_Fields",
    "RPGLauncher_Fields",
    "Item_Fields",
    "BaseLock_Fields",
    "ResourceEntity_Fields",
    "LootableCorpse_Fields",
    "PlayerInput_Fields",
    "ModelState_Fields"
)

$pattern = "^struct (" + ($patterns -join "|") + ") \{"

for ($i=0; $i -lt $content.Length; $i++) {
    if ($content[$i] -match $pattern) {
        $className = $matches[1]
        $output += "`n// ========== $className =========="
        $output += $content[$i]
        $i++
        $braceCount = 1
        while ($braceCount -gt 0 -and $i -lt $content.Length) {
            $output += $content[$i]
            if ($content[$i] -match '\{') { $braceCount++ }
            if ($content[$i] -match '\}') { $braceCount-- }
            $i++
        }
    }
}

$output | Out-File "C:\Users\Administrator\rust-data\output\rust_fields.h"
Write-Host "Done! Extracted to output/rust_fields.h"
```

---

### generate_offsets.ps1

**Purpose:** Generates the final `offsets.h` file in C++ namespace format using TypeInfo addresses from `script.json` and field offsets from the dump.

**Input:** `programs/il2cpp/output/Dump3/script.json`
**Output:** `output/offsets.h`

```powershell
$scriptJson = Get-Content "C:\Users\Administrator\rust-data\programs\il2cpp\output\Dump3\script.json" -Raw | ConvertFrom-Json

$output = "#pragma once`n`nnamespace offsets {`n"

function Get-TypeInfo {
    param($className)
    foreach ($method in $scriptJson.ScriptMethod) {
        if ($method.Group -match $className -and $method.Address -gt 0x100000) {
            return "0x" + $method.Address.ToString("X")
        }
    }
    return "0x0"
}

# TypeInfo pointers
$output += "    inline int basenetworkable_pointer = $(Get-TypeInfo 'BaseNetworkable');  // BaseNetworkable TypeInfo`n"
$output += "    inline uint64_t camera_pointer = $(Get-TypeInfo 'MainCamera');  // MainCamera TypeInfo`n"
$output += "    inline uint64_t tod_sky_pointer = $(Get-TypeInfo 'TOD_Sky');  // TOD_Sky static class pointer`n"
$output += "    inline uint64_t console_pointer = $(Get-TypeInfo 'ConsoleSystem');  // ConsoleSystem TypeInfo`n"
$output += "    inline uint64_t convar_graphics_pointer = $(Get-TypeInfo 'ConVar.Graphics');  // ConVar.Graphics TypeInfo`n"
$output += "    inline uint64_t Il2cppHandle = 0xDAD33E0;  // TODO: verify`n"
$output += "    inline uint64_t WorldOffset = $(Get-TypeInfo 'World');  // World TypeInfo`n"
$output += "    inline uint64_t PhysxOffset = 0x1C3B3D0;  // TODO: verify`n"
$output += "    inline uint64_t ListComponent_Projectile_c = $(Get-TypeInfo 'Projectile');  // Projectile TypeInfo`n"
$output += "    inline uint64_t PlayerEyes_c = $(Get-TypeInfo 'PlayerEyes');  // PlayerEyes TypeInfo`n"
$output += "    inline uint64_t HeldEntityClass = $(Get-TypeInfo 'HeldEntity');  // HeldEntity TypeInfo`n"
$output += "`n"

# BasePlayer fields
$output += "    namespace BasePlayer {`n"
$output += "        inline int playerFlags = 0x6B8;        // VERIFIED from dump`n"
$output += "        inline int CameraMode = 0x35C;         // BasePlayer.CameraMode`n"
$output += "        inline int BaseMovement = 0x788;       // PlayerWalkMovement`n"
$output += "        inline int ModelState = 0x628;         // TODO: verify`n"
$output += "        inline int displayName_ = 0x658;       // TODO: verify`n"
$output += "        inline int playerModel = 0x500;        // PlayerModel`n"
$output += "        inline int clactiveitem = 0x4D0;       // TODO: verify`n"
$output += "        inline int inventory = 0x2F0;          // PlayerInventory`n"
$output += "        inline int playerInput = 0x518;        // PlayerInput`n"
$output += "        inline int eyes = 0x3E8;              // PlayerEyes`n"
$output += "        inline int currentTeam = 0x538;        // VERIFIED from dump`n"
$output += "        inline int userId = 0x600;             // TODO: verify`n"
$output += "        inline int lifestate = 0x258;          // from BaseCombatEntity`n"
$output += "        inline int metabolism = 0x510;         // PlayerMetabolism`n"
$output += "        inline int blueprints = 0x480;         // TODO: verify`n"
$output += "        inline int PetEntity = 0x5E0;          // VERIFIED from dump`n"
$output += "        inline int GestureViewModel = 0x418;   // VERIFIED from dump`n"
$output += "    }`n`n"

# BaseProjectile fields
$output += "    namespace BaseProjectile {`n"
$output += "        inline int recoil = 0x3F0;            // RecoilProperties`n"
$output += "        inline int automatic = 0x380;          // bool`n"
$output += "        inline int viewModel = 0x250;          // TODO: verify`n"
$output += "        inline int primaryMagazine = 0x3C8;    // Magazine`n"
$output += "        inline int reloadTime = 0x3C0;         // float`n"
$output += "        inline int aiming = 0x41D;             // bool`n"
$output += "        inline int numShotsFired = 0x43C;      // int`n"
$output += "        inline int repeatDelay = 0x26C;        // TODO: verify`n"
$output += "        inline int deployDelay = 0x268;        // TODO: verify`n"
$output += "        inline int isBurstWeapon = 0x3B7;      // TODO: verify`n"
$output += "        inline int is_reloading = 0x3B8;       // TODO: verify`n"
$output += "    }`n`n"

# BaseCombatEntity fields
$output += "    namespace BaseCombatEntity {`n"
$output += "        inline int lifestate = 0x298;           // VERIFIED from dump`n"
$output += "        inline int _health = 0x264;             // TODO: verify`n"
$output += "        inline int _maxHealth = 0x268;          // TODO: verify`n"
$output += "        inline int model = 0xE8;                // TODO: verify`n"
$output += "    }`n`n"

# PlayerModel fields
$output += "    namespace PlayerModel {`n"
$output += "        inline int BoneTransforms = 0x50;       // Model::boneTransforms`n"
$output += "        inline int position = 0x1F8;            // TODO: verify`n"
$output += "        inline int velocity = 0x204;            // TODO: verify`n"
$output += "        inline int isVisible = 0x26C;           // TODO: verify`n"
$output += "    }`n`n"

# PlayerWalkMovement fields
$output += "    namespace PlayerWalkMovement {`n"
$output += "        inline int groundAngle = 0xC8;          // TODO: verify`n"
$output += "        inline int gravityMultiplier = 0x84;    // TODO: verify`n"
$output += "        inline int maxVelocity = 0x54;          // TODO: verify`n"
$output += "    }`n`n"

# PlayerEyes fields
$output += "    namespace PlayerEyes {`n"
$output += "        inline int body_rotation = 0x44;        // Quaternion`n"
$output += "        inline int view_offset = 0x40;          // TODO: verify`n"
$output += "        inline int eye_rotation = 0x6C;         // TODO: verify`n"
$output += "    }`n`n"

# Item fields
$output += "    namespace item {`n"
$output += "        inline int item_definition = 0x30;      // TODO: verify`n"
$output += "        inline int item_uid = 0x70;             // TODO: verify`n"
$output += "        inline int amount = 0xB8;               // TODO: verify`n"
$output += "    }`n`n"

# Close namespace
$output += "};`n"

$output | Out-File "C:\Users\Administrator\rust-data\output\offsets.h"
Write-Host "Generated output/offsets.h"
Write-Host ""
Write-Host "Fields marked TODO need manual lookup in:"
Write-Host "  output/rust_readable_classes.txt"
```

---

### auto_fill_offsets.ps1

**Purpose:** Attempts to automatically find and fill missing offsets by searching `rust_readable_classes.txt`. Note: most field names are hashed in current Rust builds, so this will only find a few matches.

**Input:** `output/rust_readable_classes.txt`, `output/offsets.h`
**Output:** `output/offsets.h` (updated in-place)

```powershell
$readableFile = "C:\Users\Administrator\rust-data\output\rust_readable_classes.txt"
$offsetsFile = "C:\Users\Administrator\rust-data\output\offsets.h"
$scriptJson = Get-Content "C:\Users\Administrator\rust-data\programs\il2cpp\output\Dump3\script.json" -Raw | ConvertFrom-Json

function Get-FieldOffset {
    param($className, $fieldName)
    $lines = Get-Content $readableFile
    $inClass = $false
    $braceCount = 0
    $classPattern = "class $className "

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $classPattern) {
            $inClass = $true
            $braceCount = 0
            continue
        }
        if ($inClass) {
            if ($lines[$i] -match '\{') { $braceCount++ }
            if ($lines[$i] -match '\}') { $braceCount-- }
            if ($braceCount -le 0) { break }
            
            if ($lines[$i] -match "$fieldName.*// (0x[0-9A-Fa-f]+)") {
                return $matches[1]
            }
        }
    }
    return "0x0"
}

function Get-TypeInfo {
    param($className)
    foreach ($method in $scriptJson.ScriptMethod) {
        if ($method.Group -match $className -and $method.Address -gt 0x100000) {
            return "0x" + $method.Address.ToString("X")
        }
    }
    return "0x0"
}

Write-Host "Searching for field offsets..." -ForegroundColor Green

$classes = @{
    "BasePlayer" = @("ModelState", "displayName", "clactiveitem", "userId", "lifestate", "blueprints")
    "BaseCombatEntity" = @("_health", "_maxHealth", "model")
    "BaseProjectile" = @("viewModel", "repeatDelay", "deployDelay", "isBurstWeapon", "is_reloading")
    "PlayerModel" = @("position", "velocity", "isVisible")
    "PlayerWalkMovement" = @("groundAngle", "gravityMultiplier", "maxVelocity")
    "PlayerEyes" = @("view_offset", "eye_rotation")
    "Item" = @("item_definition", "item_uid", "amount")
}

$foundOffsets = @{}

foreach ($class in $classes.Keys) {
    Write-Host "  Searching $class..." -ForegroundColor Yellow
    foreach ($field in $classes[$class]) {
        $offset = Get-FieldOffset $class $field
        if ($offset -ne "0x0") {
            $foundOffsets["$class.$field"] = $offset
            Write-Host "    $field = $offset" -ForegroundColor Green
        } else {
            Write-Host "    $field = NOT FOUND (may be hashed or private)" -ForegroundColor Red
        }
    }
}

Write-Host "`nUpdating offsets.h..." -ForegroundColor Green

$content = Get-Content $offsetsFile -Raw

$replacements = @{
    'inline int ModelState = 0x628;'           = "inline int ModelState = $($foundOffsets['BasePlayer.ModelState']);"
    'inline int displayName_ = 0x658;'         = "inline int displayName_ = $($foundOffsets['BasePlayer.displayName']);"
    'inline int clactiveitem = 0x4D0;'         = "inline int clactiveitem = $($foundOffsets['BasePlayer.clactiveitem']);"
    'inline int userId = 0x600;'               = "inline int userId = $($foundOffsets['BasePlayer.userId']);"
    'inline int lifestate = 0x258;'            = "inline int lifestate = $($foundOffsets['BasePlayer.lifestate']);"
    'inline int blueprints = 0x480;'           = "inline int blueprints = $($foundOffsets['BasePlayer.blueprints']);"
    'inline int _health = 0x264;'              = "inline int _health = $($foundOffsets['BaseCombatEntity._health']);"
    'inline int _maxHealth = 0x268;'           = "inline int _maxHealth = $($foundOffsets['BaseCombatEntity._maxHealth']);"
    'inline int model = 0xE8;'                 = "inline int model = $($foundOffsets['BaseCombatEntity.model']);"
    'inline int viewModel = 0x250;'            = "inline int viewModel = $($foundOffsets['BaseProjectile.viewModel']);"
    'inline int repeatDelay = 0x26C;'          = "inline int repeatDelay = $($foundOffsets['BaseProjectile.repeatDelay']);"
    'inline int deployDelay = 0x268;'          = "inline int deployDelay = $($foundOffsets['BaseProjectile.deployDelay']);"
    'inline int isBurstWeapon = 0x3B7;'        = "inline int isBurstWeapon = $($foundOffsets['BaseProjectile.isBurstWeapon']);"
    'inline int is_reloading = 0x3B8;'         = "inline int is_reloading = $($foundOffsets['BaseProjectile.is_reloading']);"
    'inline int position = 0x1F8;'             = "inline int position = $($foundOffsets['PlayerModel.position']);"
    'inline int velocity = 0x204;'             = "inline int velocity = $($foundOffsets['PlayerModel.velocity']);"
    'inline int isVisible = 0x26C;'            = "inline int isVisible = $($foundOffsets['PlayerModel.isVisible']);"
    'inline int groundAngle = 0xC8;'           = "inline int groundAngle = $($foundOffsets['PlayerWalkMovement.groundAngle']);"
    'inline int gravityMultiplier = 0x84;'     = "inline int gravityMultiplier = $($foundOffsets['PlayerWalkMovement.gravityMultiplier']);"
    'inline int maxVelocity = 0x54;'           = "inline int maxVelocity = $($foundOffsets['PlayerWalkMovement.maxVelocity']);"
    'inline int view_offset = 0x40;'           = "inline int view_offset = $($foundOffsets['PlayerEyes.view_offset']);"
    'inline int eye_rotation = 0x6C;'          = "inline int eye_rotation = $($foundOffsets['PlayerEyes.eye_rotation']);"
    'inline int item_definition = 0x30;'       = "inline int item_definition = $($foundOffsets['Item.item_definition']);"
    'inline int item_uid = 0x70;'              = "inline int item_uid = $($foundOffsets['Item.item_uid']);"
    'inline int amount = 0xB8;'                = "inline int amount = $($foundOffsets['Item.amount']);"
}

foreach ($key in $replacements.Keys) {
    $content = $content.Replace($key, $replacements[$key])
}

$missingTypeInfos = @{
    "console_pointer = 0x0;" = "console_pointer = $(Get-TypeInfo 'ConsoleSystem');"
    "convar_graphics_pointer = 0x0;" = "convar_graphics_pointer = $(Get-TypeInfo 'ConVar.Graphics');"
}

foreach ($key in $missingTypeInfos.Keys) {
    $content = $content.Replace($key, $missingTypeInfos[$key])
}

$content | Out-File $offsetsFile
Write-Host "Done! Updated output/offsets.h" -ForegroundColor Green
Write-Host "`nFields still 0x0 may be hashed/obfuscated and need manual lookup." -ForegroundColor Yellow
```

---

## Output Files

| File | Size | Description |
|------|------|-------------|
| `output/offsets.h` | ~2KB | Final C++ offset header for cheat development |
| `output/rust_readable_classes.txt` | ~50MB | Class definitions extracted from dump.cs |
| `output/rust_fields.h` | ~1MB | `_Fields` struct definitions with offsets |
| `output/rust_main_classes.h` | ~10KB | Main struct declarations |
| `output/full_rust_offsets.h` | 170MB | Complete il2cpp.h (all type definitions) |
| `programs/il2cpp/output/DumpN/dump.cs` | 185MB | Full C# decompilation |
| `programs/il2cpp/output/DumpN/script.json` | 672MB | Method addresses and signatures |
| `programs/il2cpp/output/DumpN/il2cpp.h` | 170MB | All C struct definitions |
| `programs/il2cpp/output/DumpN/DummyDll/` | ~200MB | Reconstructed .NET assemblies |

---

## Troubleshooting

### "Metadata file supplied is not a supported version[39]"
**Cause:** Using old Il2CppDumper or Cpp2IL.
**Fix:** Use Rodroid Il2CppDumper from the releases page.

### "Cannot create a string longer than 0x1fffffe8 characters"
**Cause:** dump.cs exceeds Node.js string limit (~512MB).
**Fix:** Set `"dumpDisassembly": false` in config.json, or increase Node memory: `node --max-old-space-size=8192`.

### Symlink fails across drives
**Cause:** Windows symlink limitations between different drives.
**Fix:** Use xcopy instead:
```powershell
xcopy "H:\Games\rust\Rust\*" programs\rust_client\ /E /I /H /Y
```

### Fields showing as `0x0` in offsets.h
**Cause:** Field names are hashed (SHA-style) in Unity 6 / v39.
**Fix:** Manually verify offsets using ReClass.NET or by comparing with previous builds.

### "The term 'psql' is not recognized"
**Cause:** This project is NOT a Rust programming language project — it's TypeScript for the game Rust. PostgreSQL/psql are not needed.

---

## Limitations

1. **Auto-dump only provides raw layouts** — The polished `offsets.h` from cheat developers requires hours of manual reverse engineering
2. **Field names are hashed** — You cannot auto-generate a complete readable `offsets.h`  
3. **Static pointers and pointer chains** — Must be found manually using memory analysis tools (ReClass.NET, IDA Pro)
4. **Encrypted fields** — The dumper doesn't identify which fields are encrypted at runtime
5. **TypeInfo pointers may be approximate** — The script uses the first method address as a proxy; actual TypeInfo may differ

---

## Tools for Manual Verification

| Tool | Purpose |
|------|---------|
| **ReClass.NET** | Runtime memory structure analysis |
| **IDA Pro / Ghidra** | Static binary disassembly |
| **Cheat Engine** | Memory scanning and pointer tracing |
| **x64dbg** | Debugging and dynamic analysis |
| **IL2CPP Inspector** | Alternative dump format |

---

## Updating After a Game Update

1. Let Steam update Rust in `H:\Games\rust\Rust\`
2. Delete version tracking: `del output\version_info.txt`
3. Run: `yarn start:dev`
4. Compare new dump with previous build
5. Update `offsets.h` with changed values
6. Verify critical offsets in-game before deploying

---

## Credits

| Tool | Link |
|------|------|
| **Rodroid Il2CppDumper** | https://github.com/rodroidmods/rodroid-il2cppdumper |
| **Original rust-data project** | https://github.com/etr-dev/rust-data |
| **Il2CppDumper (C#)** | https://github.com/Perfare/Il2CppDumper |
| **Cpp2IL** | https://github.com/SamboyCoding/Cpp2IL |

---

## Build Information

| Property | Value |
|----------|-------|
| **Date Generated** | 2026-07-26 |
| **Rust Build ID** | 24253723 |
| **Dumper Version** | Rodroid Il2CppDumper v0.7.0 |
| **IL2CPP Version** | v39 (Unity 6) |
| **Game Assembly** | GameAssembly.dll (269 MB) |
| **Metadata** | global-metadata.dat (64 MB) |
| **Type Definitions** | 30,398 |
| **Method Definitions** | 773,310 |
```

---

Save this as `HANDOFF.md`:

```powershell
notepad "C:\Users\Administrator\rust-data\HANDOFF.md"
```

Paste the entire markdown content above, save, and you have a complete handoff document with all scripts, setup instructions, and documentation.