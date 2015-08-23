//============================================================================
// Z80 Top level using the direct module declaration
//============================================================================
`timescale 1us/ 100 ns
`default_nettype none

module z80_top_direct_n(
    output wire nM1,
    output wire nMREQ,
    output wire nIORQ,
    output wire nRD,
    output wire nWR,
    output wire nRFSH,
    output wire nHALT,
    output wire nBUSACK,

    input wire nWAIT,
    input wire nINT,
    input wire nNMI,
    input wire nRESET,
    input wire nBUSRQ,

    input wire CLK,
    output wire [15:0] A,
    inout wire [7:0] D
);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Include core A-Z80 level connecting all internal modules
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
`include "core.vh"

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Address, Data and Control bus drivers connecting to external pins
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
address_pins   address_pins_(
    .clk(clk),
	.bus_ab_pin_we(bus_ab_pin_we),
	.pin_control_oe(pin_control_oe),
	.address(address),
    .abus(A[15:0]) 
    );
    
data_pins      data_pins_   (
	.bus_db_pin_oe(bus_db_pin_oe),
	.bus_db_pin_re(bus_db_pin_re),
	.ctl_bus_db_we(ctl_bus_db_we),
	.bus_db_oe(bus_db_oe),
	.clk(clk),
    .db(db0[7:0]), 
    .D(D[7:0]) 
    );
    
control_pins_n control_pins_(
	.busack(busack),
	.pin_control_oe(pin_control_oe),
	.in_halt(in_halt),
	.nM1_out(nM1_out),
	.nRFSH_out(nRFSH_out),
	.nRD_out(nRD_out),
	.nWR_out(nWR_out),
	.nIORQ_out(nIORQ_out),
	.nMREQ_out(nMREQ_out),
	.nmi(nmi),
	.busrq(busrq),
	.clk(clk),
	.intr(intr),
	.mwait(mwait),
	.reset_in(reset_in),
    .pin_nM1      (nM1),
    .pin_nMREQ    (nMREQ),
    .pin_nIORQ    (nIORQ),
    .pin_nRD      (nRD),
    .pin_nWR      (nWR),
    .pin_nRFSH    (nRFSH),
    .pin_nHALT    (nHALT),
    .pin_nWAIT    (nWAIT),
    .pin_nBUSACK  (nBUSACK),
    .pin_nINT     (nINT),
    .pin_nNMI     (nNMI),
    .pin_nRESET   (nRESET),
    .pin_nBUSRQ   (nBUSRQ),
    .CPUCLK       (CLK)
 );

endmodule
