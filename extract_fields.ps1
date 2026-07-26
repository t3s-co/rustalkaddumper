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