#include <stdio.h>
#include <stdlib.h>
#include <cufft.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <driver_functions.h>
#include "BeatCalculatorParallel.h"

#ifndef LIBINC
#define LIBINC
#include <mpg123.h>
#include <kiss_fftr.h>
#endif

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
    if (code != cudaSuccess) {
        fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
        if (abort) exit(code);
    }
}

__global__ void differentiate_kernel(int size, unsigned short* array, cufftReal* differentiated) {
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    if (index == 0 || index == size - 1) {
        differentiated[index] = array[index];
    }
    else if (index < size) {
        differentiated[index] = 44100 * (array[index+1]-array[index-1])/2;
    }
}

int BeatCalculatorParallel::cuda_detect_beat(char* s) {
    int max_freq = 4096;
    int sample_size = 2.2 * 2 * max_freq;
    int threadsPerBlock = 512;
    int blocks = (sample_size + threadsPerBlock - 1)/threadsPerBlock;

    // Load mp3
    unsigned short* sample = (unsigned short*)malloc(sizeof(unsigned short) * sample_size);
    readMP3(s, sample);

    // Step 2: Differentiate
    unsigned short* deviceSample;
    cufftReal* deviceDifferentiatedSample;

    gpuErrchk( cudaMalloc(&deviceSample, sizeof(unsigned short) * sample_size));
    gpuErrchk( cudaMalloc(&deviceDifferentiatedSample, sizeof(cufftReal) * sample_size));

    gpuErrchk( cudaMemcpy(deviceSample, sample, sample_size * sizeof(unsigned short), cudaMemcpyHostToDevice));

    differentiate_kernel<<<blocks, threadsPerBlock>>>(sample_size, deviceSample, deviceDifferentiatedSample);
    gpuErrchk( cudaDeviceSynchronize());

    // Perform FFT
    cufftHandle plan1D;
    cufftComplex* deviceFFTOut;

    int out_size = sample_size/2 + 1;
    gpuErrchk( cudaMalloc(&deviceFFTOut, sizeof(cufftComplex) * out_size));
    
    if (cufftPlan1d(&plan1D, sample_size, CUFFT_R2C, 1) != CUFFT_SUCCESS) {
        printf("CUFFT Error - plan creation failed\n");
        return 0;
    }
    if (cufftExecR2C(plan1D, deviceDifferentiatedSample, deviceFFTOut) != CUFFT_SUCCESS) {
        printf("CUFFT Error - execution of FFT failed\n");
        return 0;
    }

    gpuErrchk(cudaFree(deviceSample));
    gpuErrchk(cudaFree(deviceDifferentiatedSample));
    return 0;
}
