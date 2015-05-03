#include <stdio.h>
#include <kiss_fftr.h>
#include <cufft.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <driver_functions.h>

__global__ void memAssign(int N, unsigned short* in, cufftReal* out) {
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    if (index < N) {
        out[index] = in[index];
        printf("CUDA: float: %f, short: %i\n", out[index], in[index]);
    }
}

__global__ void printData(int N, cufftComplex* out) {
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    if (index < N) 
        printf("CUDA: Output FFT %f %f\n", out[index].x, out[index].y);
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
    if (cudaGetLastError() != cudaSuccess) {
        printf("Failed to allocate stuff on GPU\n");
        return 0;
    }

    // Copy memory over
     if (cudaMemcpy(deviceShortArray, sample, size, cudaMemcpyHostToDevice) != cudaSuccess) {
         printf("Failed to copy shorts over\n");
         return 0;
     }

    // Run a Kernel to convert to the cufftReal format
    int threadsPerBlock = 512;
    int blocks = (size + threadsPerBlock - 1)/threadsPerBlock;
    memAssign<<<blocks, threadsPerBlock>>>(size, deviceShortArray, deviceDataIn);
    cudaDeviceSynchronize();

    // Now run the fft
    if (cufftPlan1d(&plan, size, CUFFT_R2C, 1) != CUFFT_SUCCESS) {
        printf("CUFFT Error - plan creation failed\n");
        return 0;
    }
    if (cufftExecR2C(plan, deviceDataIn, deviceDataOut) != CUFFT_SUCCESS) {
        printf("CUFFT Error - execution of FFT failed\n");
        return 0;
    }
    if (cudaDeviceSynchronize() != cudaSuccess) {
        printf("Failed to sync\n");
        return 0;
    }
    // Get data back from GPU
    if (cudaMemcpy(hostDataOut, deviceDataOut, size/2+1, cudaMemcpyDeviceToHost) != cudaSuccess) {
        printf("Failed to get memory back\n");
    }

    // Print out data 
    printData<<<blocks, threadsPerBlock>>>(size/2+1, deviceDataOut);
    cudaDeviceSynchronize();

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
