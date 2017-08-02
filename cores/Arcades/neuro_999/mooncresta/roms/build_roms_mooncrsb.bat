@echo off

REM SHA1 sums of files required
REM GFX
REM 4755609bd974976f04855d51e08ec0d62ab4bc07 *1h.bin        0x0000 - 0x0800 
REM a9795d8b7388f404f3b0e2c6ce15d713a4c5bafa *1k.bin        0x0800 - 0x0800
REM PROMS
REM f382ad5a34d282056c78a5ec00c30ec43772bae2 *6l.bpr        0x0000 - 0x0020
REM MAIN CPU
REM e65f74e35b1bfaccd407e168ea55678ae9b68edf *galmidw.u		0x0000 - 0x0800
REM 02fdcd95d8511e64c0d2b007b874112d53e41045 *galmidw.v     0x0800 - 0x0800
REM 0046b9ed697a34d088de1aead8bd7cbe526a2396 *galmidw.w     0x1000 - 0x0800
REM 18d8714e5ef52f63ba8888ecc5a25b17b3bf17d1 *galmidw.y     0x1800 - 0x0800
REM 8b44b0f74420871454e27894d0f004859f9e59a9 *7l            0x2000 - 0x0800


REM ROM_START( mooncrst )
REM 	ROM_REGION( 0x8000, "maincpu", 0 )
REM 	ROM_LOAD( "mc1",          0x0000, 0x0800, CRC(7d954a7a) SHA1(a93ee403cfd7887538ad12d33f6dd6c71bea2a32) )
REM 	ROM_LOAD( "mc2",          0x0800, 0x0800, CRC(44bb7cfa) SHA1(349c2e23a9fce73f95bb8168d369082fa129fe3d) )
REM 	ROM_LOAD( "mc3",          0x1000, 0x0800, CRC(9c412104) SHA1(1b40054ebb1ace965a8522119bb23f09797bc5f6) )
REM 	ROM_LOAD( "mc4",          0x1800, 0x0800, CRC(7e9b1ab5) SHA1(435f603c0c3e788a509dd144a7916a34e791ae44) )
REM 	ROM_LOAD( "mc5.7r",       0x2000, 0x0800, CRC(16c759af) SHA1(3b48050411f65f9d3fb41ff22901e22d82bf1cf6) )
REM 	ROM_LOAD( "mc6.8d",       0x2800, 0x0800, CRC(69bcafdb) SHA1(939c8c6ed1cd4660a3d99b8f17ed99cbd7e1352a) )
REM 	ROM_LOAD( "mc7.8e",       0x3000, 0x0800, CRC(b50dbc46) SHA1(4fa084fd1ba5f78e7703e684c57af15ca7a844e4) )
REM 	ROM_LOAD( "mc8",          0x3800, 0x0800, CRC(18ca312b) SHA1(39219059003b949e38305553fea2d33071062c64) )
REM 
REM 	ROM_REGION( 0x2000, "gfx1", 0 )
REM 	ROM_LOAD( "mcs_b",        0x0000, 0x0800, CRC(fb0f1f81) SHA1(38a6679a8b69bc1870a0e67e692131c42f9535c8) )
REM 	ROM_LOAD( "mcs_d",        0x0800, 0x0800, CRC(13932a15) SHA1(b8885c555c6ad7021be55c6925a0a0872c1b6abd) )
REM 	ROM_LOAD( "mcs_a",        0x1000, 0x0800, CRC(631ebb5a) SHA1(5bc9493afa76c55858b8c8849524cbc77dc838fc) )
REM 	ROM_LOAD( "mcs_c",        0x1800, 0x0800, CRC(24cfd145) SHA1(08c6599db170dd6ee364c44f70a0f5c0f881b6ef) )
REM 
REM 	ROM_REGION( 0x0020, "proms", 0 )
REM 	ROM_LOAD( "mmi6331.6l", 0x0000, 0x0020, CRC(6a0c7d87) SHA1(140335d85c67c75b65689d4e76d29863c209cf32) ) /* Compatible with 82s123 prom */
REM ROM_END
REM ROM_START( mooncrsb )
REM 	ROM_REGION( 0x8000, "maincpu", 0 )
REM ROM_LOAD( "bepr194",      0x0000, 0x0800, CRC(6a23ec6d) SHA1(df2214bdde26a71db59ffd39a745052076563f65) )
REM 	ROM_LOAD( "bepr195",      0x0800, 0x0800, CRC(ee262ff2) SHA1(4e2202023ad53109ea58304071735d2425a617f3) )
REM 	ROM_LOAD( "f03.bin",      0x1000, 0x0800, CRC(29a2b0ab) SHA1(e9fc7161d0566e36307c45b7132e2262c0af4845) )
REM 	ROM_LOAD( "f04.bin",      0x1800, 0x0800, CRC(4c6a5a6d) SHA1(366516f63c9b5239e703e4dfb672659049ddbf44) )
REM 	ROM_LOAD( "e5",           0x2000, 0x0800, CRC(06d378a6) SHA1(99dbe9fc7f95f8fdce86eb5c32bd1ca1bea0ca3c) )
REM 	ROM_LOAD( "bepr199",      0x2800, 0x0800, CRC(6e84a927) SHA1(82e8e825d157c3c947a3a222bca059a735169c7d) )
REM 	ROM_LOAD( "e7",           0x3000, 0x0800, CRC(b45af1e8) SHA1(d7020774707234acdaef5c655f667d5ee9e54a13) )
REM 	ROM_LOAD( "bepr201",      0x3800, 0x0800, CRC(66da55d5) SHA1(39e2f6107e77ee97860147f64b9673cd9a2ae612) )
REM 
REM 	ROM_REGION( 0x2000, "gfx1", 0 )
REM 	ROM_LOAD( "epr203",       0x0000, 0x0800, CRC(be26b561) SHA1(cc27de6888eaf4ee18c0d37d9bcb528dd282b838) )
REM 	ROM_LOAD( "mcs_d",        0x0800, 0x0800, CRC(13932a15) SHA1(b8885c555c6ad7021be55c6925a0a0872c1b6abd) )
REM 	ROM_LOAD( "epr202",       0x1000, 0x0800, CRC(26c7e800) SHA1(034192e5e2cbac4b66a9828f5ec2311c2c368781) )
REM 	ROM_LOAD( "mcs_c",        0x1800, 0x0800, CRC(24cfd145) SHA1(08c6599db170dd6ee364c44f70a0f5c0f881b6ef) )
REM 
REM 	ROM_REGION( 0x0020, "proms", 0 )
REM 	ROM_LOAD( "mmi6331.6l", 0x0000, 0x0020, CRC(6a0c7d87) SHA1(140335d85c67c75b65689d4e76d29863c209cf32) ) /* Compatible with 82s123 prom */
REM ROM_END


set rom_path_src=mooncrsb
set rom_path=..\source\roms
set romgen_path=romgen

REM concatenate consecutive ROM regions
REM copy /b/y %rom_path_src%\1h.bin + %rom_path_src%\1k.bin %rom_path%\gfx1.bin > NUL
copy /b/y %rom_path_src%\bepr194 + %rom_path_src%\bepr195 + %rom_path_src%\f03.bin + %rom_path_src%\f04.bin + %rom_path_src%\e5 + %rom_path_src%\bepr199 + %rom_path_src%\e7 + %rom_path_src%\bepr201 %rom_path%\main.bin > NUL
copy /b/y %rom_path_src%\epr203 + %rom_path_src%\mcs_d %rom_path_src%\1h.bin > NUL
copy /b/y %rom_path_src%\epr202 + %rom_path_src%\mcs_c %rom_path_src%\1k.bin > NUL
copy galaxian_fire.vhd %rom_path%\galaxian_fire.vhd
copy galaxian_hit.vhd %rom_path%\galaxian_hit.vhd

REM generate RTL code for small PROMS
REM %romgen_path%\romgen %rom_path_src%\6l.bpr    GALAXIAN_6L  5 c     > %rom_path%\galaxian_6l.vhd
%romgen_path%\romgen %rom_path_src%\mmi6331.6l    GALAXIAN_6L  5 l r e     > %rom_path%\galaxian_6l.vhd

REM generate RAMB structures for larger ROMS
REM %romgen_path%\romgen %rom_path%\gfx1.bin        GFX1      12 l r e > %rom_path%\gfx1.vhd
%romgen_path%\romgen %rom_path%\main.bin        ROM_PGM_0 14 l r e > %rom_path%\rom0.vhd

%romgen_path%\romgen %rom_path_src%\1h.bin    GALAXIAN_1H 11 l r e > %rom_path%\galaxian_1h.vhd
%romgen_path%\romgen %rom_path_src%\1k.bin    GALAXIAN_1K 11 l r e > %rom_path%\galaxian_1k.vhd

REM %romgen_path%\romgen %rom_path_src%\mc_wav_2.bin GALAXIAN_WAV 18 l r e > %rom_path%\galaxian_wav.vhd

echo done
pause
