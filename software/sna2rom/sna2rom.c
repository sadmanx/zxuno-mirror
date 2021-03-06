#include <stdio.h>
#include <stdlib.h>
#define  LREG   0x3901
#define  LLEN   0x1d
unsigned char image[0xc01b], temp[0x401d];
unsigned short af, pos;
FILE *fi, *fo;

int main(int argc, char *argv[]){
  if( argc==1 )
    printf("\n"
    "sna2rom, generates +2A/+3 ROM from 48K SNA file. Antonio Villena 2016-06-17\n\n"
    "  sna2rom <input_file> <output_file>\n\n"
    "  <input_file>  SNA input file\n"
    "  <output_file> ROM output file\n\n"),
    exit(0);
  if( argc!=3 )
    printf("\nInvalid number of parameters\n"),
    exit(-1);
  fi= fopen("rompatch.rom", "rb");
  if( !fi )
    printf("\nFile rompatch.rom not found"),
    exit(-1);
  fread(temp, 1, 0x401d, fi);
  fclose(fi);
  fi= fopen(argv[1], "rb");
  if( !fi )
    printf("\nInput file not found: %s\n", argv[1]),
    exit(-1);
  fo= fopen(argv[2], "wb+");
  if( !fo )
    printf("\nCannot create output file: %s\n", argv[2]),
    exit(-1);
  fread(image, 1, 0xc01b, fi);
  pos= *(unsigned short*)(image+23);                // SP
  af= *(unsigned short*)(image+21);                 // AF
  fwrite(temp+0x4000, 1, LLEN, fo);
  fwrite(image+0x1b, 1, 0xc000-LLEN, fo);
  memcpy(temp+LREG, image+0xc01b-LLEN, LLEN);
  temp[LREG+LLEN]= image[0];                        // I
  temp[LREG+LLEN+1]= image[25]-1;                   // IM
  memcpy(temp+LREG+LLEN+2,  image+1,  8);           // HL',DE',BC',AF'
  memcpy(temp+LREG+LLEN+10, image+11, 8);           // DE,BC,IY,IX
  *(unsigned short*)(temp+LREG+LLEN+18)= af;
  temp[LREG+LLEN+20]= 0x21;                         // HL
  *(unsigned short*)(temp+LREG+LLEN+21)= *(unsigned short*)(image+9);
  temp[LREG+LLEN+23]= 0x31;                         // SP
  *(unsigned short*)(temp+LREG+LLEN+24)= pos;
  temp[LREG+LLEN+26]= 0xf3|image[19]<<1&8;          // IFF
  temp[LREG+LLEN+27]= 0xc9;                         // ret
  fwrite(temp, 1, 0x4000, fo);
  fclose(fi);
  fclose(fo);
}
