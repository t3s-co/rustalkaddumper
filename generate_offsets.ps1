$scriptJson = Get-Content "C:\Users\Administrator\rust-data\programs\il2cpp\output\Dump3\script.json" -Raw | ConvertFrom-Json

# Output file
$output = "#pragma once`n`nnamespace offsets {`n"

# Helper to find TypeInfo addresses from script.json
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

# BasePlayer - based on actual dump
$output += "    namespace BasePlayer {`n"
$output += "        inline int playerFlags = 0x6B8;        // VERIFIED from dump`n"
$output += "        inline int CameraMode = 0x35C;         // BasePlayer.CameraMode`n"
$output += "        inline int BaseMovement = 0x788;       // PlayerWalkMovement`n"  
$output += "        inline int ModelState = 0x0;           // TODO: find in dump`n"
$output += "        inline int displayName_ = 0x0;         // TODO: find in dump`n"
$output += "        inline int playerModel = 0x500;        // PlayerModel`n"
$output += "        inline int clactiveitem = 0x0;         // TODO: find HeldEntity ref`n"
$output += "        inline int inventory = 0x2F0;          // PlayerInventory`n"
$output += "        inline int playerInput = 0x518;        // PlayerInput`n"
$output += "        inline int eyes = 0x3E8;              // PlayerEyes`n"
$output += "        inline int currentTeam = 0x538;        // VERIFIED from dump`n"
$output += "        inline int userId = 0x0;               // TODO: find in dump`n"
$output += "        inline int lifestate = 0x0;            // from BaseCombatEntity`n"
$output += "        inline int metabolism = 0x510;         // PlayerMetabolism`n"
$output += "        inline int blueprints = 0x6F0;         // TODO: verify`n"
$output += "        inline int PetEntity = 0x5E0;          // VERIFIED from dump`n"
$output += "        inline int GestureViewModel = 0x418;   // VERIFIED from dump`n"
$output += "    }`n`n"

# BaseProjectile
$output += "    namespace BaseProjectile {`n"
$output += "        inline int recoil = 0x3F0;            // RecoilProperties`n"
$output += "        inline int automatic = 0x380;          // bool`n"
$output += "        inline int viewModel = 0x0;            // TODO`n"
$output += "        inline int primaryMagazine = 0x3C8;    // Magazine`n"
$output += "        inline int reloadTime = 0x3C0;         // float`n"
$output += "        inline int aiming = 0x41D;             // bool`n"
$output += "        inline int numShotsFired = 0x43C;      // int`n"
$output += "        inline int repeatDelay = 0x0;          // TODO`n"
$output += "        inline int deployDelay = 0x0;          // TODO`n"
$output += "        inline int isBurstWeapon = 0x0;        // TODO`n"
$output += "        inline int is_reloading = 0x0;         // TODO`n"
$output += "    }`n`n"

# BaseCombatEntity  
$output += "    namespace BaseCombatEntity {`n"
$output += "        inline int lifestate = 0x298;           // VERIFIED from dump`n"
$output += "        inline int _health = 0x0;               // TODO`n"
$output += "        inline int _maxHealth = 0x0;            // TODO`n"
$output += "        inline int model = 0x0;                 // TODO`n"
$output += "    }`n`n"

# PlayerModel
$output += "    namespace PlayerModel {`n"
$output += "        inline int BoneTransforms = 0x50;       // Model::boneTransforms`n"
$output += "        inline int position = 0x0;              // TODO`n"
$output += "        inline int velocity = 0x0;              // TODO`n"
$output += "        inline int isVisible = 0x0;             // TODO`n"
$output += "    }`n`n"

# PlayerWalkMovement
$output += "    namespace PlayerWalkMovement {`n"
$output += "        inline int groundAngle = 0x0;           // TODO`n"
$output += "        inline int gravityMultiplier = 0x0;     // TODO`n"
$output += "        inline int maxVelocity = 0x0;           // TODO`n"
$output += "    }`n`n"

# PlayerEyes
$output += "    namespace PlayerEyes {`n"
$output += "        inline int body_rotation = 0x44;        // Quaternion`n"
$output += "        inline int view_offset = 0x0;           // TODO`n"
$output += "        inline int eye_rotation = 0x0;          // TODO`n"
$output += "    }`n`n"

# Item
$output += "    namespace item {`n"
$output += "        inline int item_definition = 0x0;       // TODO`n"
$output += "        inline int item_uid = 0x0;              // TODO`n"
$output += "        inline int amount = 0x0;                // TODO`n"
$output += "    }`n`n"

# Close
$output += "};`n"

$output | Out-File "C:\Users\Administrator\rust-data\output\offsets.h"
Write-Host "Generated output/offsets.h"
Write-Host ""
Write-Host "Fields marked 0x0 need manual lookup in:"
Write-Host "  output/rust_readable_classes.txt"