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
    
    # Stop after getting enough
    if ($output.Count -gt 10000) { break }
}

$output | Out-File "C:\Users\Administrator\rust-data\output\rust_readable_classes.txt"
Write-Host "Done! $($output.Count) lines extracted."