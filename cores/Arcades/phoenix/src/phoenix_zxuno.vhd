---------------------------------------------------------------------------------
-- ZX-UNO Port & Top level by Quest 2017
---------------------------------------------------------------------------------
-- DE2-35 by Dar (darfpga@aol.fr) (April 2016)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity phoenix_zxuno is
port
(
	CLK50			: in  std_logic;
	LED			: out std_logic;
	O_VIDEO_R	: out std_logic_vector(2 downto 0); 
	O_VIDEO_G	: out std_logic_vector(2 downto 0);
	O_VIDEO_B	: out std_logic_vector(2 downto 0);
	O_HSYNC		: out std_logic;
	O_VSYNC		: out std_logic;

	sram_addr	: out std_logic_vector(20 downto 0);
	sram_dq		: in  std_logic_vector(1 downto 0);
	sram_we_n	: out std_logic;

	O_AUDIO_L 	: out std_logic;
	O_AUDIO_R 	: out std_logic;
	
	JOYSTICK		: in std_logic_vector(5 downto 0);	
	
	NTSC			: out std_logic;
	PAL 			: out std_logic;
	 
	ps2_clk 		: in std_logic;
	ps2_data		: in std_logic
);
end;

architecture struct of phoenix_zxuno is

	signal clk        : std_logic;
	signal clk44      : std_logic;
	signal ena22      : std_logic;
	signal ena11      : std_logic;
	signal reset      : std_logic;
	signal pll_locked : std_logic;

	signal audio      : std_logic_vector(11 downto 0);
	signal audio_out	: std_logic;
	signal video_r		: std_logic_vector(1 downto 0);
	signal video_g		: std_logic_vector(1 downto 0);
	signal video_b		: std_logic_vector(1 downto 0);
	signal vsync		: std_logic;
	signal hsync		: std_logic;

	signal dip_switch : std_logic_vector(7 downto 0);
	signal ce_pix     : std_logic;

	signal scanlines   : std_logic_vector(1 downto 0);
	signal comp_sync_l : std_logic;
	signal video_r_x2  : std_logic_vector(3 downto 0);
	signal video_g_x2  : std_logic_vector(3 downto 0);
	signal video_b_x2  : std_logic_vector(3 downto 0);
	signal hsync_x2    : std_logic;
	signal vsync_x2    : std_logic;  

	signal div_cnt     : std_logic_vector(1 downto 0);

	signal resetKey	  : std_logic;
	signal master_reset : std_logic;
	signal scanSW		  : std_logic_vector(10 downto 0);

	signal buttons      : std_logic_vector(7 downto 0);
	signal button_in    : std_logic_vector(7 downto 0);
	signal joystick_reg : std_logic_vector(5 downto 0);

	signal scandblctrl  : std_logic_vector(1 downto 0); 
	signal dbl_scan	  : std_logic; 
  

begin
 
	relojes: entity work.relojes
	port map(
      CLK_IN1  => clk50, 
		CLK_OUT1 => clk44,
      LOCKED	=> pll_locked
	);
	
	NTSC <= '0';
	PAL <= '1';
 
	dac : entity work.pwm_sddac
	port  map(
		clk_i	=> clk44,
		reset	=> reset,
		dac_i	=> audio,
		dac_o	=> audio_out,
		we		=> '1'
	);
	
	O_AUDIO_R <= audio_out;
	O_AUDIO_L <= audio_out;

	reset <= not pll_locked or resetKey; 
	
	phoenix : entity work.phoenix
	port map
	(
		clk          => ena11, --clk,
		reset        => reset,
		ce_pix       => ce_pix,
		dip_switch   => dip_switch,
		btn_coin     => not buttons(4),
		btn_player_start(0) => not buttons(5),
		btn_player_start(1) => not buttons(7),
		btn_left     => not buttons(3),
		btn_right    => not buttons(2),
		btn_barrier  => not buttons(4),
		btn_fire     => not buttons(5),
		video_r      => video_r,
		video_g      => video_g,
		video_b      => video_b,
		video_hs     => hsync,
		video_vs     => vsync,
		audio_select => "000",
		audio        => audio
	);	

  dbl_scan <=  scandblctrl(0) xor scanSW(6); -- 1 = VGA  0 = RGB
  
  ----genera sincro compuesta
  comp_sync_l <= not (vsync xor hsync);

  p_video_ouput : process
  begin
    wait until rising_edge(clk44);
		 if (dbl_scan = '0') then  
		  O_VIDEO_R <= video_r & '0';
		  O_VIDEO_G <= video_g & '0';
		  O_VIDEO_B <= video_b & '0';
		  
		  O_HSYNC <= comp_sync_l;
		  O_VSYNC <= '1';
		else  
		  O_VIDEO_R <= video_r_x2(3 downto 1);
		  O_VIDEO_G <= video_g_x2(3 downto 1);
		  O_VIDEO_B <= video_b_x2(3 downto 1);
		  
		  O_HSYNC <= hsync_x2;
		  O_VSYNC <= vsync_x2;
		end if;
	end process;
  
vga: entity work.scandoubler
	port map(
		clk_sys => ena22,
		scanlines => scandblctrl(1) xor scanSW(8),
		r_in   => video_r & video_r,
		g_in   => video_g & video_g,
		b_in   => video_b & video_b,
		hs_in  => hsync,
		vs_in  => vsync,
		r_out  => video_r_x2(3 downto 1),
		g_out  => video_g_x2(3 downto 1),
		b_out  => video_b_x2(3 downto 1),
		hs_out => hsync_x2,
		vs_out => vsync_x2
	);
		
  p_clk_div : process(pll_locked, clk44)
  begin
    if (pll_locked = '0') then
      div_cnt <= (others => '0');
      ena22   <= '0';
      ena11   <= '0';
    elsif rising_edge(clk44) then
      div_cnt <= div_cnt + "1";
      ena22   <= div_cnt(0);
      ena11   <= div_cnt(0) and not div_cnt(1);
    end if;
  end process;		

  joystick_reg <= JOYSTICK;

	--  button_in(8) <= not scanSW(7);
	button_in(7) <= not scanSW(7); --pause
	button_in(5) <= joystick_reg(5) and not scanSW(5); -- fire2 / x / lwin
	button_in(6) <= joystick_reg(4) and not scanSW(4); -- fire1 / enter / z / space

	button_in(4) <= joystick_reg(4) and not scanSW(4); -- fire1 / enter / z / space
	button_in(2) <= joystick_reg(3) and not scanSW(3); -- right
	button_in(3) <= joystick_reg(2) and not scanSW(2); -- left
	button_in(0) <= joystick_reg(1) and not scanSW(1); -- down
	button_in(1) <= joystick_reg(0) and not scanSW(0); -- up

	--Swap directions for horizontal screen help
	buttons(0) <= button_in(0) when scanSW(9) = '0' else button_in(2);
	buttons(1) <= button_in(1) when scanSW(9) = '0' else button_in(3);
	buttons(2) <= button_in(2) when scanSW(9) = '0' else button_in(1);
	buttons(3) <= button_in(3) when scanSW(9) = '0' else button_in(0);
	buttons(7 downto 4) <= button_in(7 downto 4); 

	LED <= scanSW(9); --pad directions switch status  
  
	--0x8FD5 SRAM (SCANDBLCTRL ZXUNO REG)  
	sram_addr <= "000001000111111010101"; 	
	scandblctrl <= sram_dq(1 downto 0);  
	sram_we_n <= '1';
  
	---- keyboard module
	keyboard : entity work.keyboard 
	port map (
		CLOCK 	=> ena11, --clk,
		PS2_CLK	=> ps2_clk,
		PS2_DATA => ps2_data,
		resetKey => resetKey,
		MRESET	=> master_reset,
		scanSW	=> scanSW
	);
  
-----------------Multiboot-------------
	multiboot : entity work.multiboot 
	port map (
	  clk_icap	=> ena11, --clk,
	  REBOOT		=> master_reset
	);  	
	
---------------------------------------

	--   SWITCH 1:     SWITCH 2:    NUMBER OF SPACESHIPS:
	--   ---------     ---------    ---------------------
	--     OFF           OFF                  6
	--     ON            OFF                  5
	--     OFF           ON                   4
	--     ON            ON                   3
	--                               FIRST FREE     SECOND FREE
	--   SWITCH 3:     SWITCH 4:     SHIP SCORE:    SHIP SCORE:
	--  ---------     ---------     -----------    -----------
	--     OFF           OFF           6,000          60,000
	--     ON            OFF           5,000          50,000
	--     OFF           ON            4,000          40,000
	--     ON            ON            3,000          30,000
	 
	--Cocktail,Factory,Factory,Factory,Bonus2,Bonus1,Ships2,Ships1
	dip_switch <= "00001111";	
	
end struct;
