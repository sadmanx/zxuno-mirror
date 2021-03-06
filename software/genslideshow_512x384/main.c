// (C)2015-2017 AZXUNO association.
// This file is part of the ZX-UNO project.
//
//     This program is free software: you can redistribute it and/or modify
//     it under the terms of the GNU General Public License as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.
//
//     This program is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY; without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//     GNU General Public License for more details.
//
//     You should have received a copy of the GNU General Public License
//     along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "stb_image.h"

typedef unsigned char u8;
typedef unsigned short u16;

void Binarize  (stbi_uc *img, u8 *grey);
void SplitVert (u8 *img, u8 *even, u8 *odd);
void SplitPage (u8 *img, u8 *page0, u8 *page1);
void AddBytes  (u8 *buffer, u16 addr, u16 lg, char *fname, int seq, FILE *ftzx);
void AddTZXHeader   (FILE *ftzx);
void AddStopCommand (FILE *ftzx);
void AddNormalBlock (FILE *ftzx, u8 *block, u16 lg, u8 flag);
int  AddImageToTZX (FILE *ftzx, char *imgfile);
void SpectrumScramble (u8 *buffer, u8 *spbuffer);
void SaveRAW (char *fname, u8 *buffer, int lg);

int main (int argc, char *argv[])
{
	FILE *ftzx, *ftext;
	char pngfile[256]; 
	
	if (argc<2)
	{
		fprintf (stderr, "Usage: %s text-file-with-pngs-to-show\n", argv[0]);
		exit(1);
	}
	
	ftext = fopen (argv[1], "rt");
	if (!ftext)
	{
		fprintf (stderr, "ERROR: %s couldn't be opened\n", argv[1]);
		exit(1);
	}
	
	
	ftzx = fopen ("slideshow.tzx", "wb");
	if (!ftzx)
	{
		fprintf (stderr, "ERROR: slideshow.tzx couldn't be created\n");
		exit(1);
	}
	
	AddTZXHeader (ftzx);
	
	pngfile[0] = '\0';
	fgets(pngfile, 255, ftext);
	if (pngfile[0])
		pngfile[strlen(pngfile)-1] = '\0';
	while (strlen(pngfile)>0)
	{
		fprintf (stderr, "Adding %s... ", pngfile);
		if (!AddImageToTZX (ftzx, pngfile))
			exit(1);
		
		fprintf (stderr, "OK!\n");
		pngfile[0] = '\0';
		fgets(pngfile, 255, ftext);
		if (pngfile[0])
		{
			pngfile[strlen(pngfile)-1] = '\0';		
			AddStopCommand (ftzx);
		}
	}
	fclose (ftext);
	fclose (ftzx);

	fprintf (stderr, "\nFile slideshow.tzx created.\n");
}

int AddImageToTZX (FILE *ftzx, char *imgfile)
{
	stbi_uc *img;
	int x, y, comp;
	u8 *imgbin, *odd, *even, *page0, *page1;

	img = stbi_load (imgfile, &x, &y, &comp, STBI_rgb);
	if (!img)
	{
		printf ("Error loading %s!\n", imgfile);
		return 0;
	}
	
	if (x!=512 || y!=384 || comp!=STBI_rgb)
	{
		fprintf (stderr, "Dimensions of %s must be 512x384x24 bit color. This has %dx%dx%d\n", imgfile, x, y, 1<<comp);
		free (img);
		return 0;
	}

	imgbin = malloc(512*384*sizeof *imgbin);
	Binarize (img, imgbin);
	free (img);
	
	even = malloc (64*192*sizeof *even);
	odd = malloc (64*192*sizeof *odd);
	SplitVert (imgbin, even, odd);
	free (imgbin);
	
	page0 = malloc (32*192*sizeof *page0);
	page1 = malloc (32*192*sizeof *page1);
	SplitPage (even, page0, page1);
	free (even);
	AddBytes (page0, 16384, 6144, imgfile, 0, ftzx);
	AddBytes (page1, 24576, 6144, imgfile, 1, ftzx);
	SplitPage (odd, page0, page1);
	free (odd);
	AddBytes (page0, 49152, 6144, imgfile, 2, ftzx);
	AddBytes (page1, 57344, 6144, imgfile, 3, ftzx);
	free (page0);
	free (page1);
	return 1;
}
	

void Binarize (stbi_uc *img, u8 *grey)
{
	int i;
	
	for (i=0;i<(512*384);i++)
	{
		grey[i] = (img[i*3]*30+img[i*3+1]*59+img[i*3+2]*11)/100;
		if (grey[i]>127)
			grey[i] = 255;
	    else
	        grey[i] = 0;
	}
}

void SplitVert (u8 *img, u8 *even, u8 *odd)
{
	int x,y;
	u8 byte;
	
	for (y=0;y<384;y++)
	{
		if ((y&1)==0)
		{
			for (x=0;x<512;x+=8)
			{
				byte = (img[y*512+x+0]&0x80) |
                       (img[y*512+x+1]&0x40) |
                       (img[y*512+x+2]&0x20) |
                       (img[y*512+x+3]&0x10) |
                       (img[y*512+x+4]&0x08) |
                       (img[y*512+x+5]&0x04) |
                       (img[y*512+x+6]&0x02) |
                       (img[y*512+x+7]&0x01);
                even[(y/2)*64+(x/8)] = byte;
			}
		}
		else
		{
			for (x=0;x<512;x+=8)
			{
				byte = (img[y*512+x+0]&0x80) |
                       (img[y*512+x+1]&0x40) |
                       (img[y*512+x+2]&0x20) |
                       (img[y*512+x+3]&0x10) |
                       (img[y*512+x+4]&0x08) |
                       (img[y*512+x+5]&0x04) |
                       (img[y*512+x+6]&0x02) |
                       (img[y*512+x+7]&0x01);
                odd[(y/2)*64+(x/8)] = byte;
			}
		}
	}
}
			
void SplitPage (u8 *img, u8 *page0, u8 *page1)
{
	int i;
	
	for (i=0;i<(64*192);i++)
		if ((i&1)==0)
			page0[i/2] = img[i];
		else
			page1[i/2] = img[i];
}

void AddTZXHeader (FILE *ftzx)
{
	u8 hdr[]="ZXTape!\x1a\x1\x14";
    u8 loader[555] = {
	0x10, 0xE8, 0x03, 0x13, 0x00, 0x00, 0x00, 0x73, 0x68, 0x77, 0x35, 0x31,
	0x32, 0x78, 0x33, 0x38, 0x34, 0x0C, 0x02, 0x0A, 0x00, 0x0C, 0x02, 0x17,
	0x10, 0xE8, 0x03, 0x0E, 0x02, 0xFF, 0x00, 0x00, 0xA2, 0x00, 0xEA, 0x3A,
	0x5C, 0x5B, 0xCB, 0x67, 0x28, 0x0E, 0xCB, 0x6F, 0x20, 0x0A, 0xE6, 0x07,
	0xFE, 0x00, 0x28, 0x09, 0xFE, 0x07, 0x28, 0x05, 0x3E, 0x10, 0x32, 0x5C,
	0x5B, 0xF3, 0x01, 0xFD, 0x7F, 0x3A, 0x5C, 0x5B, 0xE6, 0xF8, 0xF6, 0x07,
	0x32, 0x5C, 0x5B, 0xED, 0x79, 0x21, 0x00, 0x80, 0x11, 0x00, 0xC0, 0x01,
	0x00, 0x38, 0xED, 0xB0, 0x3E, 0x3E, 0xD3, 0xFF, 0xAF, 0x32, 0x08, 0x5C,
	0x01, 0xFD, 0x7F, 0xFB, 0x76, 0x3A, 0x08, 0x5C, 0xFE, 0x73, 0x20, 0x06,
	0xAF, 0x32, 0x08, 0x5C, 0x18, 0xF2, 0xB7, 0x20, 0x0C, 0x3A, 0x5C, 0x5B,
	0xEE, 0x08, 0x32, 0x5C, 0x5B, 0xED, 0x79, 0x18, 0xE3, 0x3A, 0x5C, 0x5B,
	0xE6, 0x17, 0x32, 0x5C, 0x5B, 0xED, 0x79, 0xAF, 0x32, 0x08, 0x5C, 0x76,
	0x3A, 0x08, 0x5C, 0xB7, 0x20, 0xF5, 0xAF, 0xD3, 0xFF, 0xC9, 0x30, 0x31,
	0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33,
	0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35,
	0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
	0x38, 0x39, 0x30, 0x0D, 0x00, 0x0A, 0x0D, 0x00, 0xFD, 0x34, 0x37, 0x39,
	0x39, 0x39, 0x0E, 0x00, 0x00, 0x7F, 0xBB, 0x00, 0x0D, 0x00, 0x14, 0x26,
	0x00, 0xF5, 0xAC, 0x39, 0x0E, 0x00, 0x00, 0x09, 0x00, 0x00, 0x2C, 0x37,
	0x0E, 0x00, 0x00, 0x07, 0x00, 0x00, 0x3B, 0x22, 0x35, 0x31, 0x32, 0x78,
	0x33, 0x38, 0x34, 0x20, 0x73, 0x6C, 0x69, 0x64, 0x65, 0x73, 0x68, 0x6F,
	0x77, 0x22, 0x0D, 0x00, 0x18, 0x5D, 0x00, 0xF5, 0xAC, 0x31, 0x31, 0x0E,
	0x00, 0x00, 0x0B, 0x00, 0x00, 0x2C, 0x33, 0x0E, 0x00, 0x00, 0x03, 0x00,
	0x00, 0x3B, 0x22, 0x50, 0x72, 0x65, 0x73, 0x73, 0x20, 0x27, 0x73, 0x27,
	0x20, 0x74, 0x6F, 0x20, 0x73, 0x77, 0x61, 0x70, 0x20, 0x66, 0x69, 0x65,
	0x6C, 0x64, 0x73, 0x22, 0x3B, 0xAC, 0x31, 0x32, 0x0E, 0x00, 0x00, 0x0C,
	0x00, 0x00, 0x2C, 0x33, 0x0E, 0x00, 0x00, 0x03, 0x00, 0x00, 0x3B, 0x22,
	0x41, 0x6E, 0x79, 0x20, 0x6F, 0x74, 0x68, 0x65, 0x72, 0x20, 0x74, 0x6F,
	0x20, 0x62, 0x65, 0x67, 0x69, 0x6E, 0x2F, 0x61, 0x64, 0x76, 0x61, 0x6E,
	0x63, 0x65, 0x22, 0x0D, 0x00, 0x1A, 0x5D, 0x00, 0xF1, 0x66, 0x3D, 0xBE,
	0x32, 0x33, 0x36, 0x33, 0x35, 0x0E, 0x00, 0x00, 0x53, 0x5C, 0x00, 0x2B,
	0x32, 0x35, 0x36, 0x0E, 0x00, 0x00, 0x00, 0x01, 0x00, 0x2A, 0xBE, 0x32,
	0x33, 0x36, 0x33, 0x36, 0x0E, 0x00, 0x00, 0x54, 0x5C, 0x00, 0x2B, 0x35,
	0x0E, 0x00, 0x00, 0x05, 0x00, 0x00, 0x3A, 0xEB, 0x6E, 0x3D, 0x30, 0x0E,
	0x00, 0x00, 0x00, 0x00, 0x00, 0xCC, 0x31, 0x31, 0x38, 0x0E, 0x00, 0x00,
	0x76, 0x00, 0x00, 0x3A, 0xF4, 0x34, 0x38, 0x30, 0x30, 0x30, 0x0E, 0x00,
	0x00, 0x80, 0xBB, 0x00, 0x2B, 0x6E, 0x2C, 0xBE, 0x28, 0x66, 0x2B, 0x6E,
	0x29, 0x3A, 0xF3, 0x6E, 0x0D, 0x00, 0x1E, 0x17, 0x00, 0xF4, 0x32, 0x33,
	0x37, 0x33, 0x39, 0x0E, 0x00, 0x00, 0xBB, 0x5C, 0x00, 0x2C, 0x31, 0x31,
	0x31, 0x0E, 0x00, 0x00, 0x6F, 0x00, 0x00, 0x0D, 0x00, 0x28, 0x2A, 0x00,
	0xEF, 0x22, 0x22, 0xAF, 0x3A, 0xEF, 0x22, 0x22, 0xAF, 0x3A, 0xEF, 0x22,
	0x22, 0xAF, 0x33, 0x32, 0x37, 0x36, 0x38, 0x0E, 0x00, 0x00, 0x00, 0x80,
	0x00, 0x3A, 0xEF, 0x22, 0x22, 0xAF, 0x34, 0x30, 0x39, 0x36, 0x30, 0x0E,
	0x00, 0x00, 0x00, 0xA0, 0x00, 0x0D, 0x00, 0x32, 0x0E, 0x00, 0xF9, 0xC0,
	0x34, 0x38, 0x30, 0x30, 0x30, 0x0E, 0x00, 0x00, 0x80, 0xBB, 0x00, 0x0D,
	0x00, 0x3C, 0x0A, 0x00, 0xEC, 0x34, 0x30, 0x0E, 0x00, 0x00, 0x28, 0x00,
	0x00, 0x0D, 0xC7
};
	fwrite (hdr, 1, 10, ftzx);
	fwrite (loader, 1, sizeof loader, ftzx);
}

void AddBytes (u8 *buffer, u16 addr, u16 lg, char *fname, int seq, FILE *ftzx)
{
	u8 header[17];
	u8 *spbuffer;
	
	memset (header+1, ' ', 10);
	header[0] = 3;
	strncpy (header+1, fname, 8);
	if (strlen(fname)<8)
		if (header[1+strlen(fname)]==0)
			header[1+strlen(fname)]=' ';
	header[9] = '.';
	header[10] = seq+'0';
	header[11] = lg&0xff;
	header[12] = (lg>>8)&0xff;
	header[13] = addr&0xff;
	header[14] = (addr>>8)&0xff;
	header[15] = 0x00;
	header[16] = 0x80;
	
	AddNormalBlock (ftzx, header, 17, 0);
	spbuffer = malloc(6144);
	SpectrumScramble (buffer, spbuffer);
	AddNormalBlock (ftzx, spbuffer, lg, 255);
	free (spbuffer);
}

void AddStopCommand (FILE *ftzx)
{
	u8 stopcmd[]="\x20\x0\x0";
	
	fwrite (stopcmd, 1, 3, ftzx);
}

void AddNormalBlock (FILE *ftzx, u8 *block, u16 lg, u8 flag)
{
	u8 chks;
	int i;
	u8 header[]="\x10\x64\x0\x0\x0\x0";
	
	header[3] = (lg+2)&0xff;
	header[4] = ((lg+2)>>8)&0xff;
	header[5] = flag;
	
	chks = flag;
	for (i=0;i<lg;i++)
		chks ^= block[i];
		
	fwrite (header, 1, 6, ftzx);
	fwrite (block, 1, lg, ftzx);
	fwrite (&chks, 1, 1, ftzx);
}
	
void SaveRAW (char *fname, u8 *buffer, int lg)
{
	FILE *f;
	
	f = fopen (fname, "wb");
	fwrite (buffer, 1, lg, f);
	fclose (f);
}

void SpectrumScramble (u8 *buffer, u8 *spbuffer)
{
	int tercio, fila,scan;
	
	for (tercio=0;tercio<3;tercio++)
	{
		for (fila=0;fila<8;fila++)
		{
			for (scan=0;scan<8;scan++)
			{
				memcpy (spbuffer+tercio*2048+fila*256+scan*32, buffer+tercio*2048+scan*256+fila*32, 32);
			}
		}
	}
}
