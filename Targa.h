#ifndef TARGA_H_
#define TARGA_H_

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

char Array2Targa(const char *path, const unsigned char *data, unsigned w, unsigned h, unsigned bpp);
char Targa2Array(const char *path, unsigned char **pdata, unsigned *pw, unsigned *ph, unsigned *pbpp);
char TrueColorToMonochrome(unsigned char **pdata, char flipped, unsigned w, unsigned h, unsigned *pbpp);


#endif