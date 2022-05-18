#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include "Targa.h"

__shared__ unsigned char data[10000], unsharp[10000];


__global__ void FUN_KERNEL(unsigned char* datag, unsigned char* unsharpg, int w, int h, int x, int y, float a, int S, int T)
{
	int idx_thread = blockIdx.x * blockDim.x + threadIdx.x;//номер потока в задаче
    int yIndex, xIndex;
    int tmp = T;
    if (tmp > x)
        tmp = x;

    for (int sy = 0; sy < y; sy++) {
        int i = sy;
        for (int sx = 0; sx < S; sx++) {
            int jg = sx * T + idx_thread;
            int j = idx_thread;
            if (jg < x) {
                for (int yCounter = 0; yCounter < 5; yCounter++)
                    if (yCounter+i*5 < h)
                        for (int xCounter = 0; xCounter < 5; xCounter++)
                            if (xCounter+jg*5 < w)
                                data[yCounter*tmp*5+(xCounter+j*5)] = datag[(yCounter+i*5)*w+(xCounter+jg*5)];

                int avg = 0;
                for (int yCounter = 0; yCounter < 5; yCounter++) {
                    if (yCounter+i*5 < h) yIndex = yCounter;
                    else yIndex = (h - 1) % 5;
                    int horSum = 0;
                    for (int xCounter = 0; xCounter < 5; xCounter++) {
                        if (xCounter+jg*5 < w) xIndex = xCounter + j*5;
                        else xIndex = (w - 1) % 5;
                        horSum += data[yIndex*tmp*5+(xIndex)];
                    }
                    avg += horSum;
                }
                avg = avg / 25;

                for (int yCounter = 0; yCounter < 5; yCounter++)
                    if (yCounter+i*5 < h)
                        for (int xCounter = 0; xCounter < 5; xCounter++)
                            if (xCounter+jg*5 < w) {
                                int substraction = (int)data[yCounter*tmp*5+(xCounter+j*5)] - avg;
                                if (substraction < 0) substraction = 0;
                                int sum = (int)data[yCounter*tmp*5+(xCounter+j*5)]+(int)(a * substraction);
                                if (sum > 255) sum = 255;
                                unsharp[yCounter*tmp*5+(xCounter+j*5)]=sum; 
                            }

                for (int yCounter = 0; yCounter < 5; yCounter++)
                    if (yCounter+i*5 < h)
                        for (int xCounter = 0; xCounter < 5; xCounter++)
                            if (xCounter+jg*5 < w)
                                unsharpg[(yCounter+i*5)*w+(xCounter+jg*5)] = unsharp[yCounter*tmp*5+(xCounter+j*5)];
            }
        }

    }
}

int main(int argc, char **argv)
{

    if (argc!=3)
        return 1;
    int blocks, blocksize, steps, threadsTotal;
    unsigned char *devData;
    unsigned char *data;
    unsigned char *devUnsharp;
    unsigned char *unsharp;

    unsigned w=0, h=0, bpp=0;
    if(Targa2Array(argv[1],&data,&w,&h,&bpp) == 1)
        return 1;

    if (bpp/8 == 3)
        TrueColorToMonochrome(&data, 0, w, h, &bpp);

    float a = 0.1;
	printf("Введите a: ");
	scanf("%f", &a);
    
    float elapsedTime, copyTime1, copyTime2, deviceTime;
	cudaEvent_t start, stop, event1, event2;
	cudaEventCreate(&start);
	cudaEventCreate(&event1);
	cudaEventCreate(&event2);
	cudaEventCreate(&stop);

	printf("Введите количество блоков: ");
	scanf("%i", &blocks);
	printf("Введите количество нитей: ");
	scanf("%i", &blocksize);

    unsigned int ImageSize = w*h;

    int x = w/5+((w%5)!=0);
    int y = h/5+((h%5)!=0);
	threadsTotal = blocks * blocksize;
    steps = x / threadsTotal + ((x % threadsTotal) != 0);
    printf("X: %d\n", x);
    printf("S: %d\n", steps);

	cudaMalloc((void**)&devData, ImageSize * sizeof(unsigned char));
	cudaMalloc((void**)&devUnsharp, ImageSize * sizeof(unsigned char));
    unsharp = (unsigned char *)malloc(ImageSize);

    cudaEventRecord(start, 0);
    cudaMemcpy(devData, data, ImageSize * sizeof(unsigned char), cudaMemcpyHostToDevice);
    cudaEventRecord(event1, 0);

    FUN_KERNEL <<< blocks, blocksize >>> (devData, devUnsharp, w, h, x, y, a, steps, threadsTotal);
    
    cudaEventRecord(event2, 0);
    cudaMemcpy(unsharp, devUnsharp, ImageSize * sizeof(unsigned char), cudaMemcpyDeviceToHost);

    cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&elapsedTime, start, stop);
	cudaEventElapsedTime(&copyTime1, start, event1);
	cudaEventElapsedTime(&deviceTime, event1, event2);
	cudaEventElapsedTime(&copyTime2, event2, stop);
    
    Array2Targa(argv[2],unsharp,w,h,bpp);

	cudaFree(devData);
	cudaFree(devUnsharp);
    
    free(data);
    free(unsharp);

    printf("Elapsed time (ms) =\t%f\n", elapsedTime);
    printf("Copy time (ms) =\t%f\n", copyTime1 + copyTime2);
    printf("Device time (ms) =\t%f\n", deviceTime);
    return 0;
}