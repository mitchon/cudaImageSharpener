#include "Targa.h"

char Array2Targa(const char *path, const unsigned char *data, unsigned w, unsigned h, unsigned bpp) {
    unsigned char TargaMagic[12] = {0,0,0,0,0,0,0,0,0,0,0,0};
    if (bpp==8)
        TargaMagic[2]=3;
    else
        TargaMagic[2]=2;
    FILE *File = fopen(path, "wb");
    if (File == NULL)
        return 1;
    if(fwrite(TargaMagic,1,sizeof(TargaMagic),File)!=sizeof(TargaMagic)) {
        fclose(File);
        return 1;
    }
    unsigned char Header[6]={0};
    Header[5]=32;
    Header[0]=w&0xFF; Header[1]=(w>>8)&0xFF;
    Header[2]=h&0xFF; Header[3]=(h>>8)&0xFF;
    Header[4]=bpp;
    unsigned int ImageSize=w*h*(bpp)/8;
    if(fwrite(Header,1,sizeof(Header),File)!=sizeof(Header)) {
        fclose(File);
        return 1;
    }
    if(fwrite(data,1,ImageSize,File)!=ImageSize) {
        fclose(File);
        return 1;
    }
    fclose(File);
    return 0;
}

char Targa2Array(const char *path, unsigned char **pdata, unsigned *pw, unsigned *ph, unsigned *pbpp) {
    //const unsigned char TargaMagic[12] = {0,0,0,0,0,0,0,0,0,0,0,0};
    unsigned char FileMagic[12];
    unsigned char Header[6];
    FILE *File = fopen(path, "rb");
    if(File == NULL)
        return 1;
    if(fread(FileMagic,1,sizeof(FileMagic),File)!=sizeof(FileMagic)) {
        fclose(File);
        return 1;
    }
    unsigned char ImageType=FileMagic[2];
    FileMagic[2]=0;
    if(/*memcmp(TargaMagic,FileMagic,sizeof(TargaMagic))!=0 ||*/ fread(Header,1,sizeof(Header),File)!=sizeof(Header)) {
        fclose(File);
        return 1;
    }
    *pw=Header[1]*256+Header[0];
    *ph=Header[3]*256+Header[2];

    *pbpp=Header[4];
    unsigned int Bpp=*pbpp/8;
    if(*pw <= 0 || *ph <= 0 || (ImageType==2&&Bpp!=3&&Bpp!=4) || (ImageType==3&&Bpp!=1)) {
        fclose(File);
        return 1;
    }
    unsigned int ImageSize=*pw**ph*Bpp;
    unsigned char *data=(unsigned char *)malloc(ImageSize);
    
    if(data==NULL||fread(data,1,ImageSize,File)!=ImageSize) {
        free(data);
        fclose(File);
        return 1;
    }
    
    fclose (File);
    *pdata=data;
    return 0;
}

char TrueColorToMonochrome(unsigned char **pdata, char flipped, unsigned w, unsigned h, unsigned *pbpp) {
    unsigned int Bpp=*pbpp/8;
    unsigned int ImageSize = w*h*Bpp;
    unsigned int CompressedSize = ImageSize/Bpp+((ImageSize%Bpp)!=0);
    unsigned char *data = *pdata;
    unsigned char *compressed=(unsigned char *)malloc(CompressedSize);
    *pbpp=8;
    if (flipped == 0) {
        for (unsigned int i = 0; i < CompressedSize; i++) {
            compressed[i]=(data[i*3]+data[i*3+1]+data[i*3+2])/3;
        }
        free(data);
        *pdata=compressed;
    }
    else {
        unsigned char *flip=(unsigned char *)malloc(CompressedSize);
        for (unsigned int i = 0; i < CompressedSize; i++) {
            flip[CompressedSize-1-i]=(data[i*3]+data[i*3+1]+data[i*3+2])/3;
        }
        for (unsigned int i = 0; i < h; i++) {
            for (unsigned int j = 0; j < w; j++)
                compressed[i*w+w-j]=flip[i*w+j];
        }
        free(flip);
        free(data);
        *pdata=compressed;
    }
    return 0;

}
