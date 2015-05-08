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
        differentiated[index] = (cufftReal)array[index];
    }
    else if (index < size) {
        differentiated[index] = 44100 * ((cufftReal)array[index+1]-(cufftReal)array[index-1])/2;
    }
}

//TODO: look up best way to reduce an array with CUDA
//      Currently use first thread in each block to reduce the array corresponding to that block, then return size N array
//      Once best found, make this function return single integer
<<<<<<< HEAD
__global__ void calculate_energy(cufftComplex* sample, cufftComplex* combs, int* tempEnergies, int * energies, int sample_size, int N) {
    int combIdx = blockIdx.x * sample_size;
||||||| merged common ancestors
__global__ void calculate_energy(cufftComplex* sample, cufftComplex* combs, int* tempEnergies, int * energies, int sample_size, int N) {
    int combIdx = blockIdx.x * blockDim.x;
=======
__global__ void calculate_energy(cufftComplex* sample, cufftComplex* combs, int* tempEnergies, int* energies, int sample_size, int N) {
    int combIdx = blockIdx.x * sample_size;
>>>>>>> some more changes
    int sampleIdx = threadIdx.x;

    if (sampleIdx < sample_size) {
      int a = sample[sampleIdx].x * combs[combIdx + sampleIdx].x - sample[sampleIdx].y * combs[combIdx + sampleIdx].y;
      int b = sample[sampleIdx].x * combs[combIdx + sampleIdx].y + sample[sampleIdx].y * combs[combIdx + sampleIdx].x;
      tempEnergies[combIdx + sampleIdx] = a * a + b * b;
    }

    __syncthreads();

    if (sampleIdx == 0) {
      int energy = 0;
      for (int i=0; i < sample_size; i++) {
        energy += tempEnergies[combIdx+i];
      }
      energies[blockIdx.x] = energy;
    }
}

//TODO: write kernel function to do this
void generateCombs(int BPM_init, int N, int size, int AmpMax, cufftReal* hostDataIn) {
    for(int i = 0; i < N; i++) {
      int BPM = BPM_init + i*5;
      int Ti = 60 * 44100/BPM;
      int start = size * i; //compute offset for this comfilter

      for(int k = 0; k < size; k+=2) {
        if (k % Ti == 0) {
          hostDataIn[start+k] = AmpMax;
          hostDataIn[start+k+1] = AmpMax;
        }
        else {
          hostDataIn[k] = 0;
          hostDataIn[k+1] = 0;
        }
      }
    }
}

void combFilterFFT(int BPM_init, int BPM_final, int N, int fft_input_size, cufftComplex* deviceDataOut) {

    // Assign Variables
    cufftHandle plan;
    cufftReal* deviceDataIn, *hostDataIn;


    int AmpMax = 65535;
     
    // Malloc Variables 
    gpuErrchk( cudaMalloc(&deviceDataIn, sizeof(cufftReal) * fft_input_size * N) );

    hostDataIn = (cufftReal*)malloc(sizeof(cufftReal) * fft_input_size * N);
    
    //Generate all Combs
    generateCombs(BPM_init, N, fft_input_size, AmpMax, hostDataIn);

    int n[1] = {fft_input_size};

    gpuErrchk( cudaMemcpy(deviceDataIn, hostDataIn, fft_input_size * N * sizeof(cufftReal), cudaMemcpyHostToDevice) );

    // Now run the fft
    if (cufftPlanMany(&plan, 1, n, NULL, 1, fft_input_size, NULL, 1, fft_input_size, CUFFT_R2C, N) != CUFFT_SUCCESS) {
        printf("CUFFT Error - plan creation failed\n");
        exit(-1);
    }
    if (cufftExecR2C(plan, deviceDataIn, deviceDataOut) != CUFFT_SUCCESS) {
        printf("CUFFT Error - execution of FFT failed\n");
        exit(-1);
    }

    gpuErrchk( cudaDeviceSynchronize() );

    // Cleanup
    if (cufftDestroy(plan) != CUFFT_SUCCESS) {
      printf("CUFFT Error - plan destruction failed\n");
      exit(-1);
    }

    gpuErrchk( cudaFree(deviceDataIn) );
    free(hostDataIn);

    return;
}

int combFilterAnalysis(cufftComplex* sample, cufftComplex* combs, int out_size, int N) {
    //Launch a kernel to calculate the instant energy at position $k$ in the filtered sample, for all k, for all N filters

    //Run Kernel to determine energies
    int *tempEnergies, *deviceEnergies, *hostEnergies;
    gpuErrchk( cudaMalloc(&tempEnergies, sizeof(int) * out_size * N) );
    gpuErrchk( cudaMalloc(&deviceEnergies, sizeof(int) * N) );

    hostEnergies = (int*)malloc(N * sizeof(int));

    const int blocks = N; //want a block for each comb

    const int tpb = 512;

    calculate_energy<<<blocks, tpb>>>(sample, combs, tempEnergies, deviceEnergies, out_size, N);
    gpuErrchk( cudaPeekAtLastError() );
    gpuErrchk( cudaDeviceSynchronize() );

    //free temp array
    gpuErrchk( cudaFree(tempEnergies) );
    
    //Loop through final array to find the best one
    gpuErrchk( cudaMemcpy(hostEnergies, deviceEnergies, sizeof(int) * N, cudaMemcpyDeviceToHost) );

    //Calculate max of 
    int max = -1;
    int index = -1;
    for (int i = 0; i < 30; i++) {
        if (hostEnergies[i] > max) {
            max = hostEnergies[i];
            index = i;
        }
    }
    
    gpuErrchk( cudaFree(deviceEnergies) );

    return 60 + index * 5;
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

    //free sample array on host
    free(sample);

    //differentiate sample on device
    differentiate_kernel<<<blocks, threadsPerBlock>>>(sample_size, deviceSample, deviceDifferentiatedSample);
    gpuErrchk( cudaPeekAtLastError() );
    gpuErrchk( cudaDeviceSynchronize() );

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
    
    //free diff'd sample (we don't need it anymore)
    gpuErrchk( cudaFree(deviceDifferentiatedSample) );

    //Create Combs + FFT them
    cufftComplex* combFFTOut;
    int BPM_init = 60;
    int BPM_final = 210;
    int N = (BPM_final - BPM_init)/5;
    gpuErrchk( cudaMalloc(&combFFTOut, sizeof(cufftComplex) * out_size * N) );
    
    combFilterFFT(BPM_init, BPM_final, N, sample_size, combFFTOut);

    //perform analysis
    int BPM = combFilterAnalysis(deviceFFTOut, combFFTOut, out_size, N);

    gpuErrchk(cudaFree(combFFTOut));
    gpuErrchk(cudaFree(deviceFFTOut));
    
    return BPM;
}
