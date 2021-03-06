---------------------------------------------------------------------------------
-- Space Invaders Arcade Port to ZX-UNO by Quest 2017 
---------------------------------------------------------------------------------

-- Space Invaders top level for
-- ps/2 keyboard interface with sound and scan doubler MikeJ
--
-- Version : 0300
--
-- Copyright (c) 2002 Daniel Wallner (jesus@opencores.org)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-- The latest version of this file can be found at:
--      http://www.fpgaarcade.com
--
-- Limitations :
--
-- File history :
--
--      0241 : First release
--
--      0242 : added the ROM from mw8080.vhd
--
--      0300 : MikeJ tidy up for audio release

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

library UNISIM;
  use UNISIM.Vcomponents.all;

entity invaders_top is
	port(
		sram_addr : out std_logic_vector(20 downto 0);
		sram_dq   : inout std_logic_vector(1 downto 0);
		sram_we_n : out std_logic;
		
		O_VIDEO_R         : out   std_logic_vector(2 downto 0);
		O_VIDEO_G         : out   std_logic_vector(2 downto 0);
		O_VIDEO_B         : out   std_logic_vector(2 downto 0);
		O_HSYNC           : out   std_logic;
		O_VSYNC           : out   std_logic;

		O_AUDIO_L         : out   std_logic;
		O_AUDIO_R         : out   std_logic;

		JOYSTICK          : in    std_logic_vector(5 downto 0);

		OSC_IN            : in    std_logic;

		O_LED             : out   std_logic;		

		ps2_clk  : in std_logic;
		ps2_data : in std_logic;	 
		
		PAL	: out std_logic;
		NTSC  : out std_logic
		);
end invaders_top;

architecture rtl of invaders_top is

	signal I_RESET_L       : std_logic;
	signal Clk             : std_logic;
	signal Clk_x2          : std_logic;
	signal Rst_n_s         : std_logic;

	signal DIP             : std_logic_vector(8 downto 1);
	signal RWE_n           : std_logic;
	signal Video           : std_logic;
	signal VideoRGB        : std_logic_vector(2 downto 0);
	signal VideoRGB_X2     : std_logic_vector(7 downto 0);
	signal HSync           : std_logic;
	signal VSync           : std_logic;
	signal HSync_X2        : std_logic;
	signal VSync_X2        : std_logic;

	signal AD              : std_logic_vector(15 downto 0);
	signal RAB             : std_logic_vector(12 downto 0);
	signal RDB             : std_logic_vector(7 downto 0);
	signal RWD             : std_logic_vector(7 downto 0);
	signal IB              : std_logic_vector(7 downto 0);
	signal SoundCtrl3      : std_logic_vector(5 downto 0);
	signal SoundCtrl5      : std_logic_vector(5 downto 0);

	signal Buttons         : std_logic_vector(8 downto 0);
	signal Buttons_n       : std_logic_vector(8 downto 1);

	signal Tick1us         : std_logic;

	signal Reset           : std_logic;

	signal rom_data_0      : std_logic_vector(7 downto 0);
	signal rom_data_1      : std_logic_vector(7 downto 0);
	signal rom_data_2      : std_logic_vector(7 downto 0);
	signal rom_data_3      : std_logic_vector(7 downto 0);
	signal ram_we          : std_logic;
	--
	signal HCnt            : std_logic_vector(11 downto 0);
	signal VCnt            : std_logic_vector(11 downto 0);
	signal HSync_t1        : std_logic;
	signal Overlay_G1      : boolean;
	signal Overlay_G2      : boolean;
	signal Overlay_R1      : boolean;
	signal Overlay_G1_VCnt : boolean;
  --
   signal button_in        : std_logic_vector(7 downto 0);
   signal button_debounced : std_logic_vector(7 downto 0);
	--
	signal Audio           : std_logic_vector(7 downto 0);
	signal AudioPWM        : std_logic;
	signal comp_sync_l : std_logic;
	signal dbl_scan        : std_logic;
  
	signal resetKey : std_logic;
	signal resetClk : std_logic;
	signal master_reset : std_logic;
	signal scanSW   : std_logic_vector(10 downto 0);

	signal buttonsJ        : std_logic_vector(7 downto 0);
	signal joystick_reg   : std_logic_vector(5 downto 0);

	signal scandblctrl   : std_logic_vector(1 downto 0);
  
begin

  I_RESET_L <= not resetKey;
  
  u_clocks : entity work.INVADERS_CLOCKS
	port map (
	   I_CLK_REF  => OSC_IN,
	   I_RESET_L  => '1',
	   --
	   O_CLK      => Clk,
	   O_CLK_X2   => Clk_x2
	 );

	Buttons_n <= not Buttons(8 downto 1);
	DIP <= "00000000";

	core : entity work.invaders
		port map(
			Rst_n      => I_RESET_L,
			Clk        => Clk,
			MoveLeft   => Buttons(0),
			MoveRight  => Buttons(1),
			Coin       => Buttons(2),
			Sel1Player => Buttons(3),
			Sel2Player => Buttons(5), 
			Fire       => Buttons(4),
			DIP        => DIP,
			RDB        => RDB,
			IB         => IB,
			RWD        => RWD,
			RAB        => RAB,
			AD         => AD,
			SoundCtrl3 => SoundCtrl3,
			SoundCtrl5 => SoundCtrl5,
			Rst_n_s    => Rst_n_s,
			RWE_n      => RWE_n,
			Video      => Video,
			HSync      => HSync,
			VSync      => VSync
			);
	--
	-- ROM
	--
	u_rom : entity work.INVADERS_ROM
	  port map (
		CLK         => Clk,
		ENA         => '1',
		ADDR        => AD(12 downto 0),
		DATA        => IB
		);
	--
	-- RAM
	--
	ram_we <= not RWE_n;

	rams : for i in 0 to 3 generate
	  u_ram : component RAMB16_S2
	  port map (
		do   => RDB((i*2)+1 downto (i*2)),
		addr => RAB,
		clk  => Clk,
		di   => RWD((i*2)+1 downto (i*2)),
		en   => '1',
		ssr  => '0',
		we   => ram_we
		);
	end generate;
	--
	-- Glue
	--
	process (Rst_n_s, Clk)
		variable cnt : unsigned(3 downto 0);
	begin
		if Rst_n_s = '0' then
			cnt := "0000";
			Tick1us <= '0';
		elsif Clk'event and Clk = '1' then
			Tick1us <= '0';
			if cnt = 9 then
				Tick1us <= '1';
				cnt := "0000";
			else
				cnt := cnt + 1;
			end if;
		end if;
	end process;

  joystick_reg <= JOYSTICK;
  
--  button_in(8) <= not scanSW(7);
  button_in(7) <= not scanSW(7); --pause
  button_in(5) <= joystick_reg(5) and not scanSW(5); --fire2 / x / lwin
  button_in(6) <= joystick_reg(4) and not scanSW(4); -- fire1 / enter / z / space

  button_in(4) <= joystick_reg(5) and not scanSW(5); -- fire1 / enter / z / space
  button_in(2) <= joystick_reg(3) and not scanSW(3); -- right
  button_in(3) <= joystick_reg(2) and not scanSW(2); -- left
  button_in(0) <= joystick_reg(1) and not scanSW(1); -- down
  button_in(1) <= joystick_reg(0) and not scanSW(0); -- up
  
  --Swap directions for horizontal screen help
  buttonsJ(0) <= button_in(0) when scanSW(9) = '0' else button_in(2);
  buttonsJ(1) <= button_in(1) when scanSW(9) = '0' else button_in(3);
  buttonsJ(2) <= button_in(2) when scanSW(9) = '0' else button_in(1);
  buttonsJ(3) <= button_in(3) when scanSW(9) = '0' else button_in(0);
  buttonsJ(7 downto 4) <= button_in(7 downto 4); 

  u_debounce : entity work.BUTTON_DEBOUNCE
  generic map (
    G_WIDTH => 8
    )
  port map (
    I_BUTTON => buttonsJ, --button_in,
    O_BUTTON => button_debounced,
    CLK      => clk
    );

  p_input_registers : process
	begin
    wait until rising_edge(Clk);
	  if I_RESET_L = '0' then
			Buttons <= (others => '0');
		end if;
		if Rst_n_s = '0' then
			Buttons <= (others => '0');
		else
			Buttons(0) <= button_debounced(2); -- Left
			Buttons(1) <= button_debounced(3); -- Right
			Buttons(2) <= button_debounced(6); -- Coin
--			Buttons(3) <= button_debounced(7) or button_debounced(6); -- Player1 --or para coin y start en 1
			Buttons(3) <= button_debounced(5); -- Player1 --or para coin y start en 1
			Buttons(4) <= button_debounced(4); -- Fire
			Buttons(5) <= button_debounced(7); --2Player start
		end if;
	end process;
  --
  -- Video Output
  --
  p_overlay : process(Rst_n_s, Clk)
	variable HStart : boolean;
  begin
	if Rst_n_s = '0' then
	  HCnt <= (others => '0');
	  VCnt <= (others => '0');
	  HSync_t1 <= '0';
	  Overlay_G1_VCnt <= false;
	  Overlay_G1 <= false;
	  Overlay_G2 <= false;
	  Overlay_R1 <= false;
	elsif Clk'event and Clk = '1' then
	  HSync_t1 <= HSync;
	  HStart := (HSync_t1 = '0') and (HSync = '1');-- rising

	  if HStart then
		HCnt <= (others => '0');
	  else
		HCnt <= HCnt + "1";
	  end if;

	  if (VSync = '0') then
		VCnt <= (others => '0');
	  elsif HStart then
		VCnt <= VCnt + "1";
	  end if;

	  if HStart then
		if (Vcnt = x"1F") then
		  Overlay_G1_VCnt <= true;
		elsif (Vcnt = x"95") then
		  Overlay_G1_VCnt <= false;
		end if;
	  end if;

	  if (HCnt = x"027") and Overlay_G1_VCnt then
		Overlay_G1 <= true;
	  elsif (HCnt = x"046") then
		Overlay_G1 <= false;
	  end if;

	  if (HCnt = x"046") then
		Overlay_G2 <= true;
	  elsif (HCnt = x"0B6") then
		Overlay_G2 <= false;
	  end if;

	  if (HCnt = x"1A6") then
		Overlay_R1 <= true;
	  elsif (HCnt = x"1E6") then
		Overlay_R1 <= false;
	  end if;

	end if;
  end process;

  p_video_out_comb : process(Video, Overlay_G1, Overlay_G2, Overlay_R1)
  begin
	if (Video = '0') then
	  VideoRGB  <= "000";
	else
	  if Overlay_G1 or Overlay_G2 then
		VideoRGB  <= "010";
	  elsif Overlay_R1 then
		VideoRGB  <= "100";
	  else
		VideoRGB  <= "111";
	  end if;
	end if;
  end process;

  u_dblscan : entity work.DBLSCAN
	port map (
	  RGB_IN(7 downto 3) => "00000",
	  RGB_IN(2 downto 0) => VideoRGB,
	  HSYNC_IN           => HSync,
	  VSYNC_IN           => VSync,

	  RGB_OUT            => VideoRGB_X2,
	  HSYNC_OUT          => HSync_X2,
	  VSYNC_OUT          => VSync_X2,
	  --  NOTE CLOCKS MUST BE PHASE LOCKED !!
	  CLK                => Clk,
	  CLK_X2             => Clk_x2,
	  scanlines    =>  scandblctrl(1) xor scanSW(8)	  
	);
	
  dbl_scan <=  scandblctrl(0) xor scanSW(6); -- 1 = VGAS  0 = RGB	

  p_comp_sync : process(HSync, VSync)
   begin
     comp_sync_l <= (VSync) and (HSync);
   end process;

  p_video_ouput : process(clk_x2)
  begin
    if rising_edge(clk_x2) then
		if (dbl_scan = '1') then	
		----VGA
		  O_VIDEO_R <= VideoRGB_X2(2) & VideoRGB_X2(5) & '0';
		  O_VIDEO_G <= VideoRGB_X2(1) & VideoRGB_X2(4) & '0';
		  O_VIDEO_B <= VideoRGB_X2(0) & VideoRGB_X2(3) & '0';
		  O_HSYNC   <= not HSync_X2;
		  O_VSYNC   <= not VSync_X2;
		else
		-- RGB  
		  O_VIDEO_R <= VideoRGB(2) & VideoRGB(2) & '0';
		  O_VIDEO_G <= VideoRGB(1) & VideoRGB(1) & '0';
		  O_VIDEO_B <= VideoRGB(0) & VideoRGB(0) & '0';
		  O_HSYNC   <= comp_sync_l;
		  O_VSYNC   <= '1';
		end if;
	end if;
  end process;
  
  O_LED <= scanSW(9); --pad directions switch status
  
  PAL <= '1';
  NTSC <= '0';
  
  --
  -- Audio
  --
  u_audio : entity work.invaders_audio
	port map (
	  Clk => Clk,
	  S1  => SoundCtrl3,
	  S2  => SoundCtrl5,
	  Aud => Audio
	  );

  u_dac : entity work.dac
	generic map(
	  msbi_g => 7
	)
	port  map(
	  clk_i   => Clk,
	  res_n_i => Rst_n_s,
	  dac_i   => Audio,
	  dac_o   => AudioPWM
	);

  O_AUDIO_L <= AudioPWM;
  O_AUDIO_R <= AudioPWM;


 --0x8FD5 SRAM (SCANDBLCTRL ZXUNO REG)  
 sram_addr <= "000001000111111010101"; 	
 scandblctrl <= sram_dq(1 downto 0);  
 sram_we_n <= '1';
  
---- keyboard module
  keyboard : entity work.keyboard 
	  port map (
		CLOCK => Clk_x2,
		PS2_CLK => ps2_clk,
		PS2_DATA => ps2_data,
		resetKey => resetKey,
		MRESET => master_reset,
		scanSW => scanSW
	);
  
-----------------Multiboot-------------
	multiboot : entity work.multiboot 
	port map (
	  clk_icap => Clk,
	  REBOOT => master_reset
	);  
  

end;
