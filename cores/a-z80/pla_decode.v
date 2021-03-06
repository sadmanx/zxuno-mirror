`default_nettype none

//=====================================================================================
// This file is automatically generated by the z80_pla_checker tool. Do not edit!      
//
//  Copyright (C) 2014  Goran Devic
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//=====================================================================================
module pla_decode (
    input wire [6:0] prefix,
    input wire [7:0] opcode,
    output reg [104:0] pla
    );

    always @* begin
        `include "pla-decode-table.vh";
    
        // Duplicate or ignored entries
        pla[ 18]=1'b0;   // ldi/ldir/ldd/lddr
        pla[ 19]=1'b0;   // cpi/cpir/cpd/cpdr
        pla[ 32]=1'b0;   // ld i,a/a,i/r,a/a,r
        pla[ 36]=1'b0;   // ld(rr),a/a,(rr)
        pla[ 41]=1'b0;   // IX/IY
        pla[ 60]=1'b0;   // rrd/rld
        pla[ 63]=1'b0;   // ld r,*
        pla[ 71]=1'b0;   // rlca/rla/rrca/rra
        pla[ 87]=1'b0;   // ld a,i / ld a,r
        pla[ 90]=1'b0;   // djnz *
        pla[ 93]=1'b0;   // cpi/cpir/cpd/cpdr
        pla[ 94]=1'b0;   // ldi/ldir/ldd/lddr
        pla[ 98]=1'b0;   // out (*),a/in a,(*)
    end

endmodule
