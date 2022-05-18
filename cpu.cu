#include <stdio.h>
#include "Targa.h"
#include <cuda_runtime.h>
#include <device_launch_parameters.h>

int main(int argc, char **argv)
{
    if (argc!=3)
        return 1;
    unsigned char *data;
    unsigned w=0, h=0, bpp=0;
    if(Targa2Array(argv[1],&data,&w,&h,&bpp) == 1)
        return 1;
    
    if (bpp/8 == 3)
        TrueColorToMonochrome(&data, 0, w, h, &bpp);

    float a = 0.1;
	printf("Введите a: ");
	scanf("%f", &a);

    float elapsedTime;
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
    
    int x = w/5+((w%5)!=0);
    int y = h/5+((h%5)!=0);

    cudaEventRecord(start, 0);
    
    int yIndex, xIndex;

    unsigned char *unsharp=(unsigned char *)malloc(h * w);
    for (int i = 0; i < y; i++) {
        for (int j = 0; j < x; j++) {
            int avg = 0;
            for (int yCounter = 0; yCounter < 5; yCounter++) {
                if (yCounter+i*5 < h) yIndex = yCounter + i*5;
                else yIndex = h - 1;
                int horSum = 0;
                for (int xCounter = 0; xCounter < 5; xCounter++) {
                    if (xCounter+j*5 < w) xIndex = xCounter + j*5;
                    else xIndex = w - 1;
                    horSum += data[yIndex*w+xIndex];
                }
                avg += horSum;
            }
            avg = avg / 25;

            for (int yCounter = 0; yCounter < 5; yCounter++)
                if (yCounter+i*5 < h)
                    for (int xCounter = 0; xCounter < 5; xCounter++)
                        if (xCounter+j*5 < w) {
                            int substraction = (int)data[(yCounter+i*5)*w+(xCounter+j*5)] - avg;
                            if (substraction < 0) substraction = 0;
                            int sum = (int)data[(yCounter+i*5)*w+(xCounter+j*5)]+(int)(a * substraction);
                            if (sum > 255) sum = 255;
                            unsharp[(yCounter+i*5)*w+(xCounter+j*5)]=sum;                 
                        }
        }
    }
    
    cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&elapsedTime, start, stop);
    
    Array2Targa(argv[2],unsharp,w,h,bpp);
    free(data);
    free(unsharp);

    printf("Elapsed time (ms) = %f\n", elapsedTime);
    return 0;
}
