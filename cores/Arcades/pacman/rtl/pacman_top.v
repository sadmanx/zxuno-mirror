//---------------------------------------------------------------------------------
//-- Pacman Arcade Port to ZX-UNO by Quest 2017 
//---------------------------------------------------------------------------------
// A simulation model of Pacman hardware
// Copyright (c) MikeJ - January 2006
//

`timescale 1 ps / 1 ps

module pacman_top (
  input  wire SYS_CLK,
  input  wire [5:0] JOYSTICK,
  output [2:0] vga_red, 
  output [2:0] vga_green, 
  output [2:0] vga_blue,
  output vga_hsync,
  output vga_vsync,
  
  output [20:0] sram_addr,
  input  [1:0]  sram_dq,
  output sram_we_n,

  output O_NTSC,
  output O_PAL,
  
  output wire audio_l,
  output wire audio_r,
  
  input wire ps2_clk,
  input wire ps2_data,
  
  output wire LED
  
);

  wire [1:0] scandblctrl;

  wire pllclk0, pllclk1, pllclk2;
  wire pclkx2, pclkx10, pll_lckd;
  wire clkfbout;
  wire reset;
  

  BUFG pclkbufg (.I(pllclk1), .O(pclk));

  //////////////////////////////////////////////////////////////////
  // 2x pclk is going to be used to drive OSERDES2
  // on the GCLK side
  //////////////////////////////////////////////////////////////////
  BUFG pclkx2bufg (.I(pllclk2), .O(pclkx2));

  //////////////////////////////////////////////////////////////////
  // 10x pclk is used to drive IOCLK network so a bit rate reference
  // can be used by OSERDES2
  //////////////////////////////////////////////////////////////////
  PLL_BASE # (
    .CLKIN_PERIOD(20),
    .CLKFBOUT_MULT(20),  //10 //set VCO to 10x of CLKIN
    .CLKOUT0_DIVIDE(4),  //2
    .CLKOUT1_DIVIDE(41), //20
    .CLKOUT2_DIVIDE(20), //10
    .COMPENSATION("INTERNAL")
  ) PLL_OSERDES (
    .CLKFBOUT(clkfbout),
    .CLKOUT0(pllclk0),
    .CLKOUT1(pllclk1),
    .CLKOUT2(pllclk2),
    .CLKOUT3(),
    .CLKOUT4(),
    .CLKOUT5(),
    .LOCKED(pll_lckd),
    .CLKFBIN(clkfbout),
    .CLKIN(SYS_CLK),
    .RST(1'b0)
  );

  wire serdesstrobe;
  wire bufpll_lock;
  BUFPLL #(.DIVIDE(5)) ioclk_buf (.PLLIN(pllclk0), .GCLK(pclkx2), .LOCKED(pll_lckd),
           .IOCLK(pclkx10), .SERDESSTROBE(serdesstrobe), .LOCK(bufpll_lock));

  synchro #(.INITIALIZE("LOGIC1"))
  synchro_reset (.async(!pll_lckd),.sync(reset),.clk(pclk));

  assign O_NTSC = 1'b0;
  assign O_PAL = 1'b1;

  // PACMAN 
  reg [7:0] delay_count;
  reg pm_reset;
  wire ena_12;
  wire ena_6;
  
  always @ (posedge pclk or negedge pll_lckd) begin
    if (!pll_lckd) begin
      delay_count <= 8'd0;
      pm_reset <= 1'b1;
    end else begin
      delay_count <= delay_count + 1'b1;
      if (delay_count == 8'hff)
        pm_reset <= 1'b0;        
    end
  end
    
  assign ena_12 = delay_count[0];
  assign ena_6 = delay_count[0] & ~delay_count[1];
  
  wire resetKey, master_reset;
  wire [10:0]scanSW;
  
 assign LED = scanSW[9];  
  
  PACMAN pm (
    .O_VIDEO_R(vga_red),
    .O_VIDEO_G(vga_green),
    .O_VIDEO_B(vga_blue),
    .O_HSYNC(vga_hsync),
    .O_VSYNC(vga_vsync),
    .O_BLANKING(vga_blanking),
    .O_AUDIO_L(audio_l),
    .O_AUDIO_R(audio_r),
    .I_JOYSTICK_A(JOYSTICK),
    .I_JOYSTICK_B(JOYSTICK),
    .JOYSTICK_A_GND(),
    .JOYSTICK_B_GND(),
    .I_RESET(pm_reset),
    .I_CLK_REF(pclkx2),
    .I_CLK(pclk),
    .I_ENA_12(ena_12),
    .I_ENA_6(ena_6),
	 .scanSW(scanSW[9:0]),
	 .resetKey(resetKey),
	 .scandblctrl(scandblctrl)
  );
  

 // 0x8FD5 SRAM (SCANDBLCTRL ZXUNO REG)  
 assign sram_addr = 21'b000001000111111010101; 	
 assign scandblctrl = sram_dq[1:0];  
 assign sram_we_n = 1'b1;

  keyboard keyb (
		.CLOCK(pclk),
		.PS2_CLK(ps2_clk),
		.PS2_DATA(ps2_data),
		.resetKey(resetKey),
		.MRESET(master_reset),
		.scanSW(scanSW)
	);
  
//-----------------Multiboot-------------
	multiboot el_multiboot (
	  .clk_icap(pclk),
	  .REBOOT(master_reset)
	);  

endmodule
