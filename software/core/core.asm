; (C)2019 AZXUNO association.
; This file is core.asm, part of the ZX-UNO project.
; .CORE . A ESXDOS dot command to boot a new core in the ZX-UNO
;
;     core.asm is free software: you can redistribute it and/or modify
;     it under the terms of the GNU General Public License as published by
;     the Free Software Foundation, either version 3 of the License, or
;     (at your option) any later version.
;
;     core.asm is distributed in the hope that it will be useful,
;     but WITHOUT ANY WARRANTY; without even the implied warranty of
;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;     GNU General Public License for more details.
;
;     You should have received a copy of the GNU General Public License
;     along with dmaplayw.  If not, see <http://www.gnu.org/licenses/>.

;Para ensamblar con PASMO como archivo binario: pasmo --bin core.asm core

ZXUNOADDR           equ 0fc3bh
ZXUNODATA           equ 0fd3bh
COREADDR            equ 0fch
COREBOOT            equ 0fdh

                    org 2000h  ;comienzo de la ejecuci�n de los comandos ESXDOS.

Main                proc
                    ld a,h
                    or l
                    jr z,PrintAndExit
                    call RecogerParam
                    call ParseParam
                    jr c,Exit

NoError             ld a,h
                    or l
                    call nz,BootZX3   ;en principio, no se vuelve de esta rutina

                    ld hl,ErrorBoot
                    jr Exit

PrintAndExit        ld hl,UsageText
Exit                call PrintString
                    or a
                    ret
                    endp
;------------------------------------------------------

RecogerParam        proc   ;HL apunta a los argumentos
                    ld de,BufferParam
CheckCaracter       ld a,(hl)
                    or a
                    jr z,FinRecoger
                    cp ":"
                    jr z,FinRecoger
                    cp 13
                    jr z,FinRecoger
                    ldi
                    jr CheckCaracter
FinRecoger          xor a
                    ld (de),a
                    ret
                    endp
;------------------------------------------------------

ParseParam          proc
                    ld bc,BufferParam
                    ld hl,0   ;HL = core number
ParseDigit          ld a,(bc)
                    or a
                    ret z
                    cp 48
                    jr c,ErrorInvalidArg
                    cp 58
                    jr nc,ErrorInvalidArg
                    sub 48
                    ld d,h
                    ld e,l
                    add hl,hl
                    add hl,hl
                    add hl,hl  ;HL = HL*8
                    ex de,hl   ;DE = HL*8
                    add hl,hl  ;HL = HL*2
                    add hl,de  ;HL = HL*10
                    ld e,a
                    ld d,0
                    add hl,de  ;a�adimos un digito a HL
                    inc bc
                    jr ParseDigit

ErrorInvalidArg     ld hl,ErrorMsg
                    scf
                    ret
                    endp
;------------------------------------------------------

BootZX3             proc
                    ld b,h
                    ld c,l      ; BC = core elegido (1 en adelante)
                    ld hl,0010h ; bits 31 a 16 de la direcci�n. Los bits 15 a 0 valen 0
                    ld de,0012h ; tama�o de cada core (bits 31 a 16 del tama�o)
SumaTamCore         dec bc
                    ld a,b
                    or c
                    jr z,DoBoot
                    add hl,de
                    jr SumaTamCore

DoBoot              ld bc,ZXUNOADDR
                    ld a,COREADDR
                    out (c),a
                    inc b
                    out (c),h   ; bits 31 a 24
                    out (c),l   ; bits 23 a 16
                    xor a
                    out (c),a   ; bits 15 a 8 (siempre son 0)
                    dec b
                    ld a,COREBOOT
                    out (c),a
                    inc b
                    out (c),a   ;escritura de cualquier valor para disparar el comando IPROG en la FPGA
                    ret         ;en condiciones normales, jam�s llegamos aqu�
                    endp
;------------------------------------------------------

PrintString         proc
BucPrintMsg         ld a,(hl)
                    or a
                    ret z
                    rst 10h
                    inc hl
                    jr BucPrintMsg
                    endp
;------------------------------------------------------

                    ;   01234567890123456789012345678901
UsageText           db "CORE",13
                    db "Boots selected core inmediately",13,13
                    db "Usage: .core N",13
                    db " where N is the order number",13
                    db " of the desired core as shown",13
                    db " in the BIOS core list page.",13
                    db 0

ErrorMsg            db 13,"ERROR: argument must be a",13
                    db "positive integer number",13,0

ErrorBoot           db 13,"ERROR: ICAP didn't answer.",13,0

BufferParam         equ $   ;resto de la RAM para el nombre del fichero