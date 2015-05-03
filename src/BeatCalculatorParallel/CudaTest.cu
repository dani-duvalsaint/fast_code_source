#include <stdio.h>
#include <kiss_fftr.h>
#include <cufft.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <driver_functions.h>

__global__ void memAssign(int N, unsigned short* in, cufftReal* out) {
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    if (index < N) 
        out[index] = (cufftReal)in[index];
}

void cudaTest() {
    printf("Inside Cuda file\n");
}

int cudaFFT(unsigned short* sample, int size, kiss_fft_cpx* out) {

    // Assign Variables
    cufftHandle plan;
    cufftReal* deviceDataIn;
    cufftComplex* deviceDataOut;
    cufftComplex* hostDataOut;
    unsigned short* deviceShortArray;

    // Malloc Variables 
    cudaMalloc(&deviceDataIn, sizeof(cufftReal) * size);
    cudaMalloc(&deviceDataOut, sizeof(cufftReal) * (size/2 + 1));
    cudaMalloc(&deviceShortArray, sizeof(unsigned short) * size);
    hostDataOut = (cufftComplex*)malloc(sizeof(cufftComplex) * (size/2+1));

    // Copy memory over
    cudaMemcpy(deviceShortArray, sample, size, cudaMemcpyHostToDevice);

    // Run a Kernel to convert to the cufftReal format
    int threadsPerBlock = 32;
    int blocks = size/threadsPerBlock + 1;
    memAssign<<<blocks, threadsPerBlock>>>(size, deviceShortArray, deviceDataIn);
    cudaDeviceSynchronize();

    // Now run the fft
    cufftPlan1d(&plan, size, CUFFT_R2C, 1);
    cufftExecR2C(plan, deviceDataIn, deviceDataOut);
    cudaDeviceSynchronize();
    // Get data back from GPU
    cudaMemcpy(hostDataOut, deviceDataOut, size/2+1, cudaMemcpyDeviceToHost);

    // Copy to out
    for (int i = 0; i < size/2 + 1; i++) {
        out[i].r = hostDataOut[i].x;
        out[i].i = hostDataOut[i].y;
    }

    // Cleanup
    cufftDestroy(plan);
    cudaFree(deviceDataIn);
    cudaFree(deviceDataOut);
    cudaFree(deviceShortArray);

    return 0;
}
