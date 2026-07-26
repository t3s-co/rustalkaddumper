# Auto-Decryptor Script v2
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
