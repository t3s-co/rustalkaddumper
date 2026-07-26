$content = Get-Content "C:\Users\Administrator\rust-data\programs\il2cpp\output\Dump3\il2cpp.h"
$output = @()

for ($i=0; $i -lt $content.Length; $i++) {
    if ($content[$i] -match "^struct (BasePlayer|BaseEntity|BaseCombatEntity|PlayerWalkMovement|PlayerEyes|PlayerInventory|PlayerModel|BaseProjectile|BaseMelee|StorageContainer|BaseOven|CodeLock|Door|BuildingBlock|ToolCupboard|BaseCorpse|HeldEntity|AttackEntity|BaseLauncher|RPGLauncher|AssaultRifle|Revolver|FlameThrower|BaseWeapon|GunShot)_o \{") {
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

$output | Out-File "C:\Users\Administrator\rust-data\output\rust_main_classes.h"
Write-Host "Done! Extracted to output/rust_main_classes.h"
Write-Host "Classes found: $($className)"