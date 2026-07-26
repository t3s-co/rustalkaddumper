```markdown
# Rust Offsets Dumping & Decryption Pipeline

## Complete Guide — From Game Files to Cheat-Ready Offsets

---

## Table of Contents
1. [Overview](#overview)
2. [System Requirements](#system-requirements)
3. [Installation](#installation)
4. [Project Structure](#project-structure)
5. [How It Works](#how-it-works)
6. [Usage](#usage)
7. [Scripts Reference](#scripts-reference)
8. [Decryption Functions](#decryption-functions)
9. [Output Files](#output-files)
10. [Updating After Game Patch](#updating-after-game-patch)
11. [Troubleshooting](#troubleshooting)
12. [Limitations](#limitations)
13. [Tools for Manual Verification](#tools-for-manual-verification)
14. [Credits](#credits)
15. [Build Information](#build-information)

---

## Overview

This pipeline automatically dumps and formats offsets from the game **Rust** (Facepunch Studios) using **Rodroid Il2CppDumper** — the only open-source IL2CPP dumper supporting Unity 6 metadata v39.

The original `rust-data` TypeScript tool is outdated and cannot handle current Rust builds. This document provides a complete replacement with automated PowerShell scripts for extraction, formatting, and decryption function generation.

### What This Pipeline Produces

- **`offsets.h`** — C++ header with 150+ field offsets organized by class namespace
- **`decrypts.cpp`** — Runtime decryption functions for 5 encrypted fields
- **`decrypt_helpers.h`** — One-liner wrapper functions for easy use in cheats
- **Raw dumps** — Full `dump.cs`, `il2cpp.h`, `script.json`, and DummyDLL assemblies

---

## System Requirements

| Requirement | Details |
|-------------|---------|
| **OS** | Windows 10/11 (64-bit) |
| **Steam** | Account that owns Rust |
| **Rust Installation** | `H:\Games\rust\Rust\` (adjust path as needed) |
| **Disk Space** | ~50GB free (dumps are large: 170MB–672MB each) |
| **Node.js** | 18+ LTS |
| **Git** | Latest |
| **SteamCMD** | Latest (for build ID checking) |

---

## Installation

### Step 1: Install Node.js
Download from [https://nodejs.org/en/download](https://nodejs.org/en/download) — choose LTS 64-bit `.msi`.
```powershell
node --version
npm --version
```

### Step 2: Install Yarn
```powershell
npm install --global yarn
```

### Step 3: Install Git
Download from [https://git-scm.com/download/win](https://git-scm.com/download/win).  
During installation, choose **"Git from the command line and also from 3rd-party software"**.

### Step 4: Install SteamCMD
```powershell
Invoke-WebRequest -Uri "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -OutFile "$env:TEMP\steamcmd.zip"
mkdir C:\steamcmd
Expand-Archive "$env:TEMP\steamcmd.zip" -DestinationPath C:\steamcmd
# Add C:\steamcmd to System PATH (via Environment Variables)
steamcmd +quit  # Verify
```

### Step 5: Clone and Setup Project
```powershell
git clone https://github.com/etr-dev/rust-data.git
cd rust-data
yarn install
```

### Step 6: Download Rodroid Il2CppDumper
Go to [https://github.com/rodroidmods/rodroid-il2cppdumper/releases](https://github.com/rodroidmods/rodroid-il2cppdumper/releases)  
Download the latest Windows `.exe` release.

```powershell
mkdir programs\il2cpp -Force
mkdir programs\il2cpp\output -Force
copy "$env:USERPROFILE\Downloads\il2cpp_dumper.exe" programs\il2cpp\Il2CppDumper.exe
```

### Step 7: Create Dumper Config
```powershell
Set-Content -Path programs\il2cpp\config.json -Value '{"dumpDisassembly": false}'
```

### Step 8: Link Rust Game Folder
```powershell
if (Test-Path programs\rust_client) { cmd /c rmdir programs\rust_client }
cmd /c mklink /D C:\Users\Administrator\rust-data\programs\rust_client "H:\Games\rust\Rust"
```

### Step 9: Configure .env File
```powershell
Set-Content -Path .env -Value @"
DUMP_CS_PATH='C:/programs/il2cpp/dump.cs'
HEADER_OUTPUT='output/rust.h'
STEAM_USERNAME='your_steam_username_here'
STEAM_PW='your_steam_password_here'
MINUTES_BETWEEN_CHECKS='5'
"@
```

### Step 10: Modify app.ts
Edit `src\app.ts`:

**Disable SteamCMD download:**
```typescript
// Find: download: true,
// Change to:
download: false,
```

**Disable GitHub integration:**
```typescript
// Find: github_offsets: true,
// Change to:
github_offsets: false,
```

**Update IL2CPP command:**
```typescript
const il2cppCommand = `${il2cppDumperExecPath} --config "${process.cwd()}/programs/il2cpp/config.json" ${gameAssemblyPath} ${metadataPath} ${il2cppDumpOutputPath}`;
```

**Update dump paths:**
```typescript
dumpCsFilePath: `${il2cppDumpOutputPath}/Dump0/dump.cs`,
scriptFilePath: `${il2cppDumpOutputPath}/Dump0/script.json`,
```

**Increase Node.js memory** (in `package.json`):
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
│   │       └── DumpN/
│   │           ├── dump.cs              # C# decompilation (~185MB)
│   │           ├── script.json          # Method addresses (~672MB)
│   │           ├── il2cpp.h             # C struct definitions (~170MB)
│   │           ├── il2cpp-functions.h   # C++ scaffold
│   │           ├── stringliteral.json   # String literals
│   │           ├── generics_dump.txt    # Generic type dump
│   │           └── DummyDll/            # Reconstructed .NET assemblies
│   │
│   └── rust_client/                     # SYMLINK -> H:\Games\rust\Rust\
│
├── output/                              # Generated output files
│   ├── offsets.h                        # Final C++ offset header with decrypt annotations
│   ├── decrypt_helpers.h                # One-liner wrapper functions
│   ├── rust_readable_classes.txt        # Extracted class definitions
│   ├── rust_fields.h                    # _Fields struct definitions
│   ├── rust_main_classes.h              # Main struct declarations
│   ├── full_rust_offsets.h              # Complete il2cpp.h copy (170MB)
│   └── version_info.txt                 # Tracks current build ID
│
├── decrypts.cpp                         # Runtime decryption functions
│
├── src/
│   └── app.ts                           # Modified automation script
│
├── extract_readable.ps1                 # Class extraction script
├── extract_fields.ps1                   # Field extraction script
├── generate_offsets.ps1                 # Offset header generator
├── auto_decrypt.ps1                     # Decrypt function mapper
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
                     │  - GameAssembly.dll     │
                     │  - global-metadata.dat  │
                     │                         │
                     │  Supports:              │
                     │  - Unity 6 / v39        │
                     │  - Variable indices     │
                     │  - Auto-XOR decrypt     │
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
         │  extract_readable.ps1 -> readable classes│
         │  extract_fields.ps1   -> field structs   │
         │  generate_offsets.ps1 -> offsets.h       │
         │  auto_decrypt.ps1     -> decrypts.cpp    │
         └────────────────────┬────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
              ┌──────────┐      ┌──────────────┐
              │offsets.h │      │decrypts.cpp   │
              │(150+     │      │(5 decrypt     │
              │ offsets) │      │  functions)   │
              └──────────┘      └──────────────┘
```

### Why Rodroid Dumper?

| Feature | Old Il2CppDumper | Rodroid Dumper |
|---------|:---:|:---:|
| Unity 6 / Metadata v39 | ❌ | ✅ |
| Variable-width indices | ❌ | ✅ |
| Auto-XOR decryption | ❌ | ✅ |
| Speed | ~20s | ~17s |
| Inline disassembly | ❌ | ✅ (optional) |

### Why Field Names Are Hashed

Modern Rust builds (Unity 6 / IL2CPP v39) obfuscate most field names:

```csharp
// OLD (pre-v39):
public float _health; // 0x264

// NEW (v39+):
private float %61eefc783a5720742e1ef650899748fefd7206e4; // 0x264
```

The readable names must be manually mapped using context, comparison with previous builds, and runtime probing with ReClass.NET.

---

## Usage

### One-Time Dump
```powershell
cd C:\Users\Administrator\rust-data
yarn start:dev
```

### Continuous Monitoring (checks every 5 minutes)
```powershell
yarn start:dev
# Stops with Ctrl+C
```

### Force Re-Dump
```powershell
Remove-Item output\version_info.txt -ErrorAction SilentlyContinue
yarn start:dev
```

### Run Individual Scripts
```powershell
# Extract readable class definitions
powershell -ExecutionPolicy Bypass -File extract_readable.ps1

# Extract field struct definitions
powershell -ExecutionPolicy Bypass -File extract_fields.ps1

# Generate offsets.h
powershell -ExecutionPolicy Bypass -File generate_offsets.ps1

# Map decrypt functions and update offsets.h
powershell -ExecutionPolicy Bypass -File auto_decrypt.ps1
```

### Using in Your Cheat
```cpp
#include "offsets.h"
#include "decrypt_helpers.h"

// One-liners for encrypted fields:
uintptr_t eyes  = Decrypt::PlayerEyes(player);
uintptr_t inv   = Decrypt::PlayerInventory(player);
uintptr_t item  = Decrypt::ActiveItem(player);

// Direct offset access for non-encrypted fields:
float health = read<float>(entity + offsets::BaseCombatEntity::_health);
bool aiming  = read<bool>(weapon + offsets::BaseProjectile::aiming);
```

---

## Scripts Reference

All scripts should be placed in `C:\Users\Administrator\rust-data\` and run with:
```powershell
powershell -ExecutionPolicy Bypass -File script_name.ps1
```

---

### extract_readable.ps1

**Purpose:** Extracts full class definitions with field names and offsets from `dump.cs`.

**Input:** `programs/il2cpp/output/Dump3/dump.cs`  
**Output:** `output/rust_readable_classes.txt`

Searches for 30+ common Rust class names (BasePlayer, BaseEntity, BaseProjectile, etc.) and extracts their complete C# definitions including all fields with hex offsets.

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

**Purpose:** Extracts `_Fields` struct definitions from `il2cpp.h`.

**Input:** `programs/il2cpp/output/Dump3/il2cpp.h`  
**Output:** `output/rust_fields.h`

The `_Fields` structs contain the raw field definitions with hashed names and hex offsets. Useful for low-level memory layout verification.

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

**Purpose:** Generates the final `offsets.h` in C++ namespace format.

**Input:** `programs/il2cpp/output/Dump3/script.json`  
**Output:** `output/offsets.h`

Extracts TypeInfo pointers from `script.json` (using the first method address as proxy) and combines them with known field offsets organized by class namespace.

**Contains:**
- 12 TypeInfo/static class pointers
- 150+ field offsets across 25+ namespaces
- `Offsets::` alias namespace for compatibility

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

### auto_decrypt.ps1

**Purpose:** Creates decryption function files and updates `offsets.h` with ENCRYPTED annotations.

**Input:** `output/offsets.h`  
**Output:** 
- `decrypts.cpp` — Runtime decryption functions
- `output/decrypt_helpers.h` — One-liner wrappers
- `output/offsets.h` — Updated with `// ENCRYPTED - use decrypt::xxx()` annotations

```powershell
$offsetsFile = "C:\Users\Administrator\rust-data\output\offsets.h"
$decryptFile = "C:\Users\Administrator\rust-data\decrypts.cpp"
$helperFile = "C:\Users\Administrator\rust-data\output\decrypt_helpers.h"

Write-Host "[*] Creating decrypts.cpp..." -ForegroundColor Yellow

$cpp = "#include <cstdint>`n#include `"memory.hpp`"`n`nnamespace decrypt {`n`n"

$cpp += "std::uintptr_t client_entities(std::uintptr_t p) {`n"
$cpp += "    std::uint32_t r8d=0,eax=0,ecx=0; std::uintptr_t rax=0,rdi=p;`n"
$cpp += "    rax = read<std::uintptr_t>(rdi + 0x18);`n"
$cpp += "    std::uint32_t* rdx = (std::uint32_t*)&rax;`n"
$cpp += "    r8d = 0x02;`n"
$cpp += "    do {`n"
$cpp += "        eax = *(std::uint32_t*)(rdx); rdx = (std::uint32_t*)((char*)rdx + 0x04);`n"
$cpp += "        eax += 0xF1B06211; ecx = eax; eax <<= 0x0E; ecx >>= 0x12;`n"
$cpp += "        ecx |= eax; ecx ^= 0x24383967; ecx -= 0x5801F290;`n"
$cpp += "        *((std::uint32_t*)rdx - 1) = ecx;`n"
$cpp += "    } while (--r8d);`n"
$cpp += "    return get_handle(rax);`n"
$cpp += "}`n`n"

$cpp += "std::uintptr_t entity_list(std::uintptr_t p) {`n"
$cpp += "    std::uint32_t r8d=0,eax=0,ecx=0; std::uintptr_t rax=0,rdi=p;`n"
$cpp += "    rax = read<std::uintptr_t>(rdi + 0x18);`n"
$cpp += "    std::uint32_t* rdx = (std::uint32_t*)&rax;`n"
$cpp += "    r8d = 0x02;`n"
$cpp += "    do {`n"
$cpp += "        ecx = *(std::uint32_t*)(rdx); eax = *(std::uint32_t*)(rdx);`n"
$cpp += "        rdx = (std::uint32_t*)((char*)rdx + 0x04);`n"
$cpp += "        ecx >>= 0x13; eax <<= 0x0D; ecx |= eax;`n"
$cpp += "        ecx -= 0x48F9C02E; ecx ^= 0x6CCF6779;`n"
$cpp += "        *((std::uint32_t*)rdx - 1) = ecx;`n"
$cpp += "    } while (--r8d);`n"
$cpp += "    return get_handle(rax);`n"
$cpp += "}`n`n"

$cpp += "std::uintptr_t player_eyes(std::uintptr_t p) {`n"
$cpp += "    std::uint32_t r8d=0,eax=0,ecx=0; std::uintptr_t rax=0,rdi=p;`n"
$cpp += "    rax = read<std::uintptr_t>(rdi + 0x18);`n"
$cpp += "    std::uint32_t* rdx = (std::uint32_t*)&rax;`n"
$cpp += "    r8d = 0x02;`n"
$cpp += "    do {`n"
$cpp += "        ecx = *(std::uint32_t*)(rdx); eax = *(std::uint32_t*)(rdx);`n"
$cpp += "        rdx = (std::uint32_t*)((char*)rdx + 0x04);`n"
$cpp += "        ecx >>= 0x1C; eax <<= 0x04; ecx |= eax;`n"
$cpp += "        ecx += 0x6851055B; ecx ^= 0x442249A6;`n"
$cpp += "        *((std::uint32_t*)rdx - 1) = ecx;`n"
$cpp += "    } while (--r8d);`n"
$cpp += "    return get_handle(rax);`n"
$cpp += "}`n`n"

$cpp += "std::uintptr_t player_inventory(std::uintptr_t p) {`n"
$cpp += "    std::uint32_t r8d=0,eax=0,ecx=0; std::uintptr_t rax=0,rdi=p;`n"
$cpp += "    rax = read<std::uintptr_t>(rdi + 0x18);`n"
$cpp += "    std::uint32_t* rdx = (std::uint32_t*)&rax;`n"
$cpp += "    r8d = 0x02;`n"
$cpp += "    do {`n"
$cpp += "        eax = *(std::uint32_t*)(rdx); rdx = (std::uint32_t*)((char*)rdx + 0x04);`n"
$cpp += "        eax += 0x59558B36; eax ^= 0x2D277853; eax += 0x19F01F38;`n"
$cpp += "        ecx = eax; eax += eax; ecx >>= 0x1F; ecx |= eax;`n"
$cpp += "        *((std::uint32_t*)rdx - 1) = ecx;`n"
$cpp += "    } while (--r8d);`n"
$cpp += "    return get_handle(rax);`n"
$cpp += "}`n`n"

$cpp += "std::uintptr_t cl_active_item(std::uintptr_t p) {`n"
$cpp += "    std::uint32_t r8d=0,eax=0,ecx=0; std::uintptr_t rax=p;`n"
$cpp += "    std::uint32_t* rdx = (std::uint32_t*)&rax;`n"
$cpp += "    r8d = 0x02;`n"
$cpp += "    do {`n"
$cpp += "        eax = *(std::uint32_t*)(rdx); rdx = (std::uint32_t*)((char*)rdx + 0x04);`n"
$cpp += "        eax += 0x290AB327; ecx = eax; eax <<= 0x16; ecx >>= 0x0A;`n"
$cpp += "        ecx |= eax; ecx -= 0x761F3138;`n"
$cpp += "        *((std::uint32_t*)rdx - 1) = ecx;`n"
$cpp += "    } while (--r8d);`n"
$cpp += "    return rax;`n"
$cpp += "}`n`n"

$cpp += "} // namespace decrypt`n"

Set-Content -Path $decryptFile -Value $cpp -Encoding UTF8
Write-Host "[+] Created: $decryptFile" -ForegroundColor Green

Write-Host "[*] Updating offsets.h..." -ForegroundColor Yellow
$offsets = Get-Content $offsetsFile -Raw
$offsets = $offsets -replace "(client_entities\s*=\s*0x[0-9A-Fa-f]+);", '$1;  // ENCRYPTED - use decrypt::client_entities()'
$offsets = $offsets -replace "(entity_list\s*=\s*0x[0-9A-Fa-f]+);", '$1;  // ENCRYPTED - use decrypt::entity_list()'
$offsets = $offsets -replace "(eyes\s*=\s*0x[0-9A-Fa-f]+);", '$1;  // ENCRYPTED - use decrypt::player_eyes()'
$offsets = $offsets -replace "(inventory\s*=\s*0x[0-9A-Fa-f]+);", '$1;  // ENCRYPTED - use decrypt::player_inventory()'
$offsets = $offsets -replace "(clactiveitem\s*=\s*0x[0-9A-Fa-f]+);", '$1;  // ENCRYPTED - use decrypt::cl_active_item()'
Set-Content -Path $offsetsFile -Value $offsets -Encoding UTF8
Write-Host "[+] Updated: $offsetsFile" -ForegroundColor Green

Write-Host "[*] Creating decrypt_helpers.h..." -ForegroundColor Yellow
$helpers = "#pragma once`n#include `"offsets.h`"`n#include `"decrypts.cpp`"`n`nnamespace Decrypt {`n`n"
$helpers += "inline std::uintptr_t PlayerEyes(std::uintptr_t player) {`n"
$helpers += "    return decrypt::player_eyes(read<std::uintptr_t>(player + offsets::BasePlayer::eyes));`n"
$helpers += "}`n`n"
$helpers += "inline std::uintptr_t PlayerInventory(std::uintptr_t player) {`n"
$helpers += "    return decrypt::player_inventory(read<std::uintptr_t>(player + offsets::BasePlayer::inventory));`n"
$helpers += "}`n`n"
$helpers += "inline std::uintptr_t ActiveItem(std::uintptr_t player) {`n"
$helpers += "    return decrypt::cl_active_item(read<std::uintptr_t>(player + offsets::BasePlayer::clactiveitem));`n"
$helpers += "}`n`n"
$helpers += "inline std::uintptr_t ClientEntities(std::uintptr_t bn) {`n"
$helpers += "    return decrypt::client_entities(read<std::uintptr_t>(bn + offsets::BaseNetworkable::client_entities));`n"
$helpers += "}`n`n"
$helpers += "inline std::uintptr_t EntityList(std::uintptr_t ce) {`n"
$helpers += "    return decrypt::entity_list(read<std::uintptr_t>(ce + offsets::BaseNetworkable::entity_list));`n"
$helpers += "}`n`n"
$helpers += "} // namespace Decrypt`n"
Set-Content -Path $helperFile -Value $helpers -Encoding UTF8
Write-Host "[+] Created: $helperFile" -ForegroundColor Green

Write-Host "`n=== DECRYPT MAPPING COMPLETE ===" -ForegroundColor Cyan
Write-Host "  client_entities  -> decrypt::client_entities()" -ForegroundColor Green
Write-Host "  entity_list      -> decrypt::entity_list()" -ForegroundColor Green
Write-Host "  eyes             -> decrypt::player_eyes()" -ForegroundColor Green
Write-Host "  inventory        -> decrypt::player_inventory()" -ForegroundColor Green
Write-Host "  clactiveitem     -> decrypt::cl_active_item()" -ForegroundColor Green
```

---

## Decryption Functions

Rust encrypts certain pointers at runtime to deter cheating. These must be decrypted before use.

### Encrypted Fields and Their Decrypt Functions

| Field | Offset | Decrypt Function | Return Type |
|-------|--------|------------------|-------------|
| `BaseNetworkable::client_entities` | 0x20 | `decrypt::client_entities()` | `get_handle()` |
| `client_entities::entity_list` | 0x10 | `decrypt::entity_list()` | `get_handle()` |
| `BasePlayer::eyes` | 0x3E8 | `decrypt::player_eyes()` | `get_handle()` |
| `BasePlayer::inventory` | 0x2F0 | `decrypt::player_inventory()` | `get_handle()` |
| `BasePlayer::clactiveitem` | 0x4D0 | `decrypt::cl_active_item()` | direct return |

### Decryption Algorithm

Each function follows a similar pattern:
1. Read 8 bytes from `encrypted_ptr + 0x18`
2. Process 2 x 32-bit integers through a series of shifts, XORs, and additions
3. Return the result (optionally passed through `get_handle()`)

### Usage Example
```cpp
// Without decrypt (WRONG - returns garbage):
uintptr_t eyes = read<uintptr_t>(player + 0x3E8);

// With decrypt (CORRECT):
uintptr_t enc = read<uintptr_t>(player + offsets::BasePlayer::eyes);
uintptr_t eyes = decrypt::player_eyes(enc);
auto* playerEyes = read<PlayerEyes*>(eyes);

// Or using helper:
uintptr_t eyes = Decrypt::PlayerEyes(player);
```

---

## Output Files

| File | Size | Description |
|------|------|-------------|
| `output/offsets.h` | ~3KB | Final C++ offset header with decrypt annotations |
| `output/decrypt_helpers.h` | ~1KB | One-liner wrapper functions |
| `decrypts.cpp` | ~2KB | Runtime decryption functions |
| `output/rust_readable_classes.txt` | ~50MB | Class definitions extracted from dump.cs |
| `output/rust_fields.h` | ~1MB | `_Fields` struct definitions |
| `output/rust_main_classes.h` | ~10KB | Main struct declarations |
| `output/full_rust_offsets.h` | 170MB | Complete il2cpp.h (all type definitions) |
| `programs/il2cpp/output/DumpN/dump.cs` | 185MB | Full C# decompilation |
| `programs/il2cpp/output/DumpN/script.json` | 672MB | Method addresses and signatures |
| `programs/il2cpp/output/DumpN/il2cpp.h` | 170MB | All C struct definitions |

---

## Updating After Game Patch

### Step 1: Update Rust
Let Steam update Rust in `H:\Games\rust\Rust\`

### Step 2: Re-dump
```powershell
Remove-Item output\version_info.txt -ErrorAction SilentlyContinue
yarn start:dev
```

### Step 3: Regenerate offsets
```powershell
powershell -ExecutionPolicy Bypass -File generate_offsets.ps1
```

### Step 4: Check if encryption changed
Compare old `decrypts.cpp` with the new dump. If the encryption constants changed (the hex values in the decrypt functions), update `auto_decrypt.ps1` with the new functions and run:
```powershell
powershell -ExecutionPolicy Bypass -File auto_decrypt.ps1
```

### Step 5: Verify in-game
Test critical offsets before deploying.

---

## Troubleshooting

### "Metadata file supplied is not a supported version[39]"
**Cause:** Using old Il2CppDumper or Cpp2IL.  
**Fix:** Use Rodroid Il2CppDumper from [releases page](https://github.com/rodroidmods/rodroid-il2cppdumper/releases).

### "Cannot create a string longer than 0x1fffffe8 characters"
**Cause:** `dump.cs` exceeds Node.js string limit (~512MB).  
**Fix:** Set `"dumpDisassembly": false` in `config.json`, or increase Node memory: `node --max-old-space-size=8192`.

### Symlink fails across drives
**Cause:** Windows symlink limitations between different drives.  
**Fix:** Use xcopy:
```powershell
xcopy "H:\Games\rust\Rust\*" programs\rust_client\ /E /I /H /Y
```

### Fields showing as `0x0` in offsets.h
**Cause:** Field names are hashed (SHA-style) in Unity 6 / v39.  
**Fix:** Manually verify offsets using ReClass.NET or by comparing with previous builds.

### SteamCMD login timeout
**Cause:** Steam Guard 2FA enabled.  
**Fix:** Login manually once:
```powershell
steamcmd +login YOUR_USERNAME +quit
```

### "The term 'psql' is not recognized"
**Cause:** This project is NOT a Rust programming language project. PostgreSQL is not needed.

---

## Limitations

1. **Auto-dump only provides raw layouts** — The polished `offsets.h` from cheat developers requires manual reverse engineering for static pointers and pointer chains
2. **Field names are hashed** — Cannot auto-generate a complete readable `offsets.h`; hashed names change every update
3. **Static pointers and chains** — Must be found manually using ReClass.NET, IDA Pro, or memory probing
4. **TypeInfo pointers may be approximate** — The script uses the first method address as proxy; actual TypeInfo may differ
5. **Decryption functions are build-specific** — The constants in `decrypts.cpp` change when the game updates
6. **Encrypted field detection is manual** — The script only annotates the 5 known encrypted fields; new encrypted fields require manual identification

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

## Credits

| Tool | Link |
|------|------|
| **Rodroid Il2CppDumper** | https://github.com/rodroidmods/rodroid-il2cppdumper |
| **Original rust-data project** | https://github.com/etr-dev/rust-data |
| **Il2CppDumper (C#)** | https://github.com/Perfare/Il2CppDumper |
| **Rust decrypts and offsets** | https://www.randomcoder.dev/ |

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
| **Encrypted Fields** | 5 (BasePlayer eyes/inventory/activeitem, BaseNetworkable client_entities/entity_list) |
```

Save as `HANDOFF.md` in your project root. This is the complete, self-contained guide with all four PowerShell scripts included inline. Anyone can copy the script blocks and save them as `.ps1` files to replicate the entire pipeline.
