zx7b      logo256x192.rcs       logo256x192.rcs.zx7b
sjasmplus firmware.asm
fcut      firmware_strings.rom  8000 -8000  strings.bin
zx7b      strings.bin           strings.bin.zx7b
sjasmplus firmware.asm
fcut      firmware_strings.rom  0000  4000  firmware.rom
GenRom    0 0 0 0 'BIOS' firmware.rom firmware.tap
CgLeches  firmware.tap firmware.wav