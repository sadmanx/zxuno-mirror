`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:57:54 11/09/2015 
// Design Name: 
// Module Name:    vga_scandoubler 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module vga_scandoubler (
	input wire clkvideo,
	input wire clkvga,
    input wire enable_scandoubling,
    input wire disable_scaneffect,  // 1 to disable scanlines
	input wire [2:0] ri,
	input wire [2:0] gi,
	input wire [2:0] bi,
	input wire hsync_ext_n,
	input wire vsync_ext_n,
	output reg [2:0] ro,
	output reg [2:0] go,
	output reg [2:0] bo,
	output reg hsync,
	output reg vsync
   );
	
	parameter [31:0] CLKVIDEO = 12000;
	
	// http://www.epanorama.net/faq/vga2rgb/calc.html
	// SVGA 800x600
	// HSYNC = 3.36us  VSYNC = 114.32us
	
	parameter [63:0] HSYNC_COUNT = (CLKVIDEO * 3360 * 2)/1000000;
	parameter [63:0] VSYNC_COUNT = (CLKVIDEO * 114320 * 2)/1000000;
	
	reg [10:0] addrvideo = 11'd0, addrvga = 11'b00000000000;
	reg [9:0] totalhor = 10'd0;

	// Para generar scanlines:
	wire [2:0] rout, gout, bout;
	reg scaneffect = 1'b0;
	wire [2:0] ro_vga = (scaneffect | disable_scaneffect)? rout : {1'b0, rout[2:1]};
	wire [2:0] go_vga = (scaneffect | disable_scaneffect)? gout : {1'b0, gout[2:1]};
	wire [2:0] bo_vga = (scaneffect | disable_scaneffect)? bout : {1'b0, bout[2:1]};
	
	// Memoria de doble puerto que guarda la informaci�n de dos scans
	// Cada scan puede ser de hasta 1024 puntos, incluidos aqu� los
	// puntos en negro que se pintan durante el HBlank
	vgascanline_dport memscan (
		.clk(clkvga),
		.addrwrite(addrvideo),
		.addrread(addrvga),
		.we(1'b1),
		.din({ri,gi,bi}),
		.dout({rout,gout,bout})
	);
	
	// Voy alternativamente escribiendo en una mitad o en otra del scan buffer
	// Cambio de mitad cada vez que encuentro un pulso de sincronismo horizontal
	// En "totalhor" mido el n�mero de ciclos de reloj que hay en un scan
	always @(posedge clkvideo) begin
		if (hsync_ext_n == 1'b0 && addrvideo[9:7] != 3'b000) begin
			totalhor <= addrvideo[9:0];
			addrvideo <= {~addrvideo[10],10'b0000000000};
		end
		else
			addrvideo <= addrvideo + 11'd1;
	end
	
	// Recorro el scanbuffer al doble de velocidad, generando direcciones para
	// el scan buffer. Cada vez que el video original ha terminado una linea,
	// cambio de mitad de buffer. Cuando termino de recorrerlo pero a�n no
	// estoy en un retrazo horizontal, simplemente vuelvo a recorrer el scan buffer
	// desde el mismo origen
	// Cada vez que termino de recorrer el scan buffer basculo "scaneffect" que
	// uso despu�s para mostrar los p�xeles a su brillo nominal, o con su brillo
	// reducido para un efecto chachi de scanlines en la VGA
	always @(posedge clkvga) begin
		if (hsync_ext_n == 1'b0 && addrvga[9:7] != 3'b000) begin
			addrvga <= {~addrvga[10],10'b000000000};
			scaneffect <= ~scaneffect;
		end
		else if (addrvga[9:0] == totalhor && hsync_ext_n == 1'b1) begin
			addrvga <= {addrvga[10], 10'b000000000};
			scaneffect <= ~scaneffect;
		end
		else
			addrvga <= addrvga + 11'd1;
	end

	// El HSYNC de la VGA est� bajo s�lo durante HSYNC_COUNT ciclos a partir del comienzo
	// del barrido de un scanline
    reg hsync_vga, vsync_vga;
    
	always @* begin
		if (addrvga[9:0] < HSYNC_COUNT[9:0])
			hsync_vga = 1'b0;
		else
			hsync_vga = 1'b1;
	end
	
	// El VSYNC de la VGA est� bajo s�lo durante VSYNC_COUNT ciclos a partir del flanco de
	// bajada de la se�al de sincronismo vertical original
	reg [15:0] cntvsync = 16'hFFFF;
	initial vsync_vga = 1'b1;
	always @(posedge clkvga) begin
		if (vsync_ext_n == 1'b0) begin
			if (cntvsync == 16'hFFFF) begin
				cntvsync <= 16'd0;
				vsync_vga <= 1'b0;
			end
			else if (cntvsync != 16'hFFFE) begin
				if (cntvsync == VSYNC_COUNT[15:0]) begin
					vsync_vga <= 1'b1;
					cntvsync <= 16'hFFFE;
				end
				else
					cntvsync <= cntvsync + 16'd1;
			end
		end
		else if (vsync_ext_n == 1'b1)
			cntvsync <= 16'hFFFF;
	end

    always @* begin
        if (enable_scandoubling == 1'b0) begin // 15kHz output
            ro = ri;
            go = gi;
            bo = bi;
            hsync = hsync_ext_n ^ ~vsync_ext_n; // this is how the SAM Coup� generates vertical sync for composite output
            vsync = 1'b1;
        end
        else begin  // VGA output
            ro = ro_vga;
            go = go_vga;
            bo = bo_vga;
            hsync = hsync_vga;
            vsync = vsync_vga;
        end
    end
    
endmodule

// Una memoria de doble puerto: uno para leer, y otro para
// escribir. Es de 2048 direcciones: 1024 se emplean para
// guardar un scan, y otros 1024 para el siguiente scan
module vgascanline_dport (
	input wire clk,
	input wire [10:0] addrwrite,
	input wire [10:0] addrread,
	input wire we,
	input wire [8:0] din,
	output reg [8:0] dout
	);
	
	reg [8:0] scan[0:2047]; // two scanlines
	always @(posedge clk) begin
		dout <= scan[addrread];
		if (we == 1'b1)
			scan[addrwrite] <= din;
	end
endmodule
