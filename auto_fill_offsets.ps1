$readableFile = "C:\Users\Administrator\rust-data\output\rust_readable_classes.txt"
$offsetsFile = "C:\Users\Administrator\rust-data\output\offsets.h"
$scriptJson = Get-Content "C:\Users\Administrator\rust-data\programs\il2cpp\output\Dump3\script.json" -Raw | ConvertFrom-Json

# Helper: search readable_classes for a field offset in a class
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

# Helper: search ALL fields in a class
function Get-AllFields {
    param($className)
    $lines = Get-Content $readableFile
    $inClass = $false
    $braceCount = 0
    $classPattern = "class $className "
    $fields = @()

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $classPattern) {
            $inClass = $true
            $braceCount = 0
            continue
        }
        if ($inClass) {
            if ($lines[$i] -match '\{') { $braceCount++ }
            if ($lines[$i] -match '\}') { 
                $braceCount--
                if ($braceCount -le 0) { break }
            }
            
            # Match: "public/private Type fieldName; // 0xOFFSET"
            if ($lines[$i] -match '(public|private|protected|internal)\s+(\S+)\s+(\w+);\s*//\s*(0x[0-9A-Fa-f]+)') {
                $fields += @{
                    Type = $matches[2]
                    Name = $matches[3]
                    Offset = $matches[4]
                }
            }
        }
    }
    return $fields
}

# Helper: Get TypeInfo
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

# Find missing offsets
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

# Update offsets.h
Write-Host "`nUpdating offsets.h..." -ForegroundColor Green

$content = Get-Content $offsetsFile -Raw

# Replace known offsets
$replacements = @{
    'inline int ModelState = 0x0;'           = "inline int ModelState = $($foundOffsets['BasePlayer.ModelState']);"
    'inline int displayName_ = 0x0;'         = "inline int displayName_ = $($foundOffsets['BasePlayer.displayName']);"
    'inline int clactiveitem = 0x0;'         = "inline int clactiveitem = $($foundOffsets['BasePlayer.clactiveitem']);"
    'inline int userId = 0x0;'               = "inline int userId = $($foundOffsets['BasePlayer.userId']);"
    'inline int lifestate = 0x0;'            = "inline int lifestate = $($foundOffsets['BasePlayer.lifestate']);"
    'inline int blueprints = 0x6F0;'         = "inline int blueprints = $($foundOffsets['BasePlayer.blueprints']);"
    'inline int _health = 0x0;'              = "inline int _health = $($foundOffsets['BaseCombatEntity._health']);"
    'inline int _maxHealth = 0x0;'           = "inline int _maxHealth = $($foundOffsets['BaseCombatEntity._maxHealth']);"
    'inline int model = 0x0;'                = "inline int model = $($foundOffsets['BaseCombatEntity.model']);"
    'inline int viewModel = 0x0;'            = "inline int viewModel = $($foundOffsets['BaseProjectile.viewModel']);"
    'inline int repeatDelay = 0x0;'          = "inline int repeatDelay = $($foundOffsets['BaseProjectile.repeatDelay']);"
    'inline int deployDelay = 0x0;'          = "inline int deployDelay = $($foundOffsets['BaseProjectile.deployDelay']);"
    'inline int isBurstWeapon = 0x0;'        = "inline int isBurstWeapon = $($foundOffsets['BaseProjectile.isBurstWeapon']);"
    'inline int is_reloading = 0x0;'         = "inline int is_reloading = $($foundOffsets['BaseProjectile.is_reloading']);"
    'inline int position = 0x0;'             = "inline int position = $($foundOffsets['PlayerModel.position']);"
    'inline int velocity = 0x0;'             = "inline int velocity = $($foundOffsets['PlayerModel.velocity']);"
    'inline int isVisible = 0x0;'            = "inline int isVisible = $($foundOffsets['PlayerModel.isVisible']);"
    'inline int groundAngle = 0x0;'          = "inline int groundAngle = $($foundOffsets['PlayerWalkMovement.groundAngle']);"
    'inline int gravityMultiplier = 0x0;'    = "inline int gravityMultiplier = $($foundOffsets['PlayerWalkMovement.gravityMultiplier']);"
    'inline int maxVelocity = 0x0;'          = "inline int maxVelocity = $($foundOffsets['PlayerWalkMovement.maxVelocity']);"
    'inline int view_offset = 0x0;'          = "inline int view_offset = $($foundOffsets['PlayerEyes.view_offset']);"
    'inline int eye_rotation = 0x0;'         = "inline int eye_rotation = $($foundOffsets['PlayerEyes.eye_rotation']);"
    'inline int item_definition = 0x0;'      = "inline int item_definition = $($foundOffsets['Item.item_definition']);"
    'inline int item_uid = 0x0;'             = "inline int item_uid = $($foundOffsets['Item.item_uid']);"
    'inline int amount = 0x0;'               = "inline int amount = $($foundOffsets['Item.amount']);"
}

foreach ($key in $replacements.Keys) {
    $content = $content.Replace($key, $replacements[$key])
}

# Update TypeInfo pointers that are 0x0
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