#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <kiss_fftr.h>
#include <cufft.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <driver_functions.h>

#ifndef M_PI
#define M_PI 3.14159265358979324
#endif
#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
  if (code != cudaSuccess) 
  {
    fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
  }
}

__global__ void memAssignShort(int N, unsigned short* in, cufftReal* out) {
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    if (index < N) {
        out[index] = in[index];
        //printf("CUDA: float: %f, short: %i\n", out[index], in[index]);
    }
}

__global__ void printData(int N, cufftComplex* out) {
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    if (index < N) 
        printf("CUDA: Output FFT %f %f\n", out[index].x, out[index].y);
}

__global__ void memAssignFloat(int N, float* in, cufftReal* out) {
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    if (index < N) 
        out[index] = (cufftReal)in[index];
}

void cudaTestR() {
    printf("Starting Test of CUDA FFT \n");
    
    int size = 16; //use small sample for testing
    float *onesSample, *zerosSample, *sineSample;
    cufftHandle plan;
    cufftReal* fftDataIn;
    cufftComplex* fftDataOut;
    float* testArrayOnes;
    float* testArrayZeros;
    float* testArraySine;
    float2* retArrayOnes;
    float2* retArrayZeros;
    float2* retArraySine;
    int i;

    printf("Mallocing \n");
    // Malloc Variables 
    gpuErrchk( cudaMalloc(&fftDataIn, sizeof(cufftReal) * size) );
    gpuErrchk( cudaMalloc(&fftDataOut, sizeof(cufftReal) * (size/2 + 1)) );
    gpuErrchk( cudaMalloc(&testArrayOnes, sizeof(float) * size) );
    gpuErrchk( cudaMalloc(&testArrayZeros, sizeof(float) * size) );
    gpuErrchk( cudaMalloc(&testArraySine, sizeof(float) * size) );
    onesSample = (float*)malloc(size * sizeof(float));
    zerosSample = (float*)malloc(size * sizeof(float));
    sineSample = (float*)malloc(size * sizeof(float));
    retArrayOnes = (float2*)malloc((size/2 +1) * sizeof(float2));
    retArrayZeros = (float2*)malloc((size/2 +1) * sizeof(float2));
    retArraySine = (float2*)malloc((size/2 +1) * sizeof(float2));

    //Set up tests
    for (i = 0; i < size; i++) {
      onesSample[i] = 1;
      zerosSample[i] = 0;
      sineSample[i] = sin(2 * M_PI * 4 * i / size);
    }

    printf("Memcpy \n");
    // Copy memory over
    gpuErrchk( cudaMemcpy(testArrayOnes, onesSample, size, cudaMemcpyHostToDevice) );
    gpuErrchk( cudaMemcpy(testArrayZeros, zerosSample, size, cudaMemcpyHostToDevice) );
    gpuErrchk( cudaMemcpy(testArraySine, sineSample, size, cudaMemcpyHostToDevice) );


    //Testing wave of Ones
    printf("Run Ones Test \n");

    // Run a Kernel to convert to the cufftReal format
    int threadsPerBlock = 32;
    int blocks = size/threadsPerBlock + 1;
    memAssignFloat<<<blocks, threadsPerBlock>>>(size, testArrayOnes, fftDataIn);
    gpuErrchk( cudaPeekAtLastError() );
    gpuErrchk( cudaDeviceSynchronize() );
    
    // Now run the fft
    cufftPlan1d(&plan, size, CUFFT_R2C, 1);
    cufftExecR2C(plan, fftDataIn, fftDataOut);

    // Get data back from GPU
    gpuErrchk( cudaMemcpy(retArrayOnes,fftDataOut, size/2 +1, cudaMemcpyDeviceToHost) );

    //Testing wave of Zeros
    printf("Run Zeros Test \n");
    memAssignFloat<<<blocks, threadsPerBlock>>>(size, testArrayZeros, fftDataIn);
    gpuErrchk( cudaPeekAtLastError() );
    gpuErrchk( cudaDeviceSynchronize() );

    cufftPlan1d(&plan, size, CUFFT_R2C, 1);
    cufftExecR2C(plan, fftDataIn, fftDataOut);

    gpuErrchk( cudaMemcpy(retArrayZeros,fftDataOut, size/2 +1, cudaMemcpyDeviceToHost) );
   
    //Testing sine wave 
    printf("Run Sine Test \n");

    memAssignFloat<<<blocks, threadsPerBlock>>>(size, testArraySine, fftDataIn);
    gpuErrchk( cudaPeekAtLastError() );
    gpuErrchk( cudaDeviceSynchronize() );

    cufftPlan1d(&plan, size, CUFFT_R2C, 1);
    cufftExecR2C(plan, fftDataIn, fftDataOut);

    gpuErrchk( cudaMemcpy(retArraySine,fftDataOut, size/2 +1, cudaMemcpyDeviceToHost) );
    
    //Ones Data
    printf("Ones Result\n");
    for (i = 0; i < size; i++) {
      printf(" in[%2zu] = %+f    ", i, onesSample[i]);
      if (i < size / 2 + 1)
        printf("out[%2zu] = %+f , %+f", i, retArrayOnes[i].x, retArrayOnes[i].y);
      printf("\n");
    }  
    
    //Zeros Data
    printf("Ones Result\n");
    for (i = 0; i < size; i++) {
      printf(" in[%2zu] = %+f    ", i, zerosSample[i]);
      if (i < size / 2 + 1)
        printf("out[%2zu] = %+f , %+f", i, retArrayZeros[i].x, retArrayZeros[i].y);
      printf("\n");
    }  
    
    //Sine Data
    printf("Ones Result\n");
    for (i = 0; i < size; i++) {
      printf(" in[%2zu] = %+f    ", i, sineSample[i]);
      if (i < size / 2 + 1)
        printf("out[%2zu] = %+f , %+f", i, retArraySine[i].x, retArraySine[i].y);
      printf("\n");
    } 
 
    // Cleanup CUDA Side
    cufftDestroy(plan);
    cudaFree(fftDataIn);
    cudaFree(fftDataOut);
    cudaFree(testArrayOnes);
    cudaFree(testArrayZeros);
    cudaFree(testArraySine);
    
    //Free arrays
    free(onesSample);
    free(zerosSample);
    free(sineSample);
    free(retArrayOnes);
    free(retArrayZeros);
    free(retArraySine);

}

void cudaTest() {
  printf("Inside CUDA File\n");

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
    cudaMalloc(&deviceDataOut, sizeof(cufftComplex) * (size/2 + 1));
    cudaMalloc(&deviceShortArray, sizeof(unsigned short) * size);
    hostDataOut = (cufftComplex*)malloc(sizeof(cufftComplex) * (size/2+1));
    if (cudaGetLastError() != cudaSuccess) {
        printf("Failed to allocate stuff on GPU\n");
        return 0;
    }

       // Copy memory over
     if (cudaMemcpy(deviceShortArray, sample, size * sizeof(unsigned short), cudaMemcpyHostToDevice) != cudaSuccess) {
         printf("Failed to copy shorts over\n");
         return 0;
     }

    // Run a Kernel to convert to the cufftReal format
    int threadsPerBlock = 512;
    int blocks = (size + threadsPerBlock - 1)/threadsPerBlock;
    memAssignShort<<<blocks, threadsPerBlock>>>(size, deviceShortArray, deviceDataIn);
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
    if (cudaMemcpy(hostDataOut, deviceDataOut, (size/2+1) * sizeof(cufftComplex), cudaMemcpyDeviceToHost) != cudaSuccess) {
        printf("Failed to get memory back\n");
    }

    // Print out data 
    //printData<<<blocks, threadsPerBlock>>>(size/2+1, deviceDataOut);
    cudaDeviceSynchronize();

    // Copy to out
    for (int i = 0; i < size/2 + 1; i++) {
        out[i].r = hostDataOut[i].x;
        out[i].i = hostDataOut[i].y;
        //printf("Host: %f %f, Out: %f %f\n", hostDataOut[i].x, hostDataOut[i].y, out[i].r, out[i].i);
    }

    // Cleanup
    cufftDestroy(plan);
    cudaFree(deviceDataIn);
    cudaFree(deviceDataOut);
    cudaFree(deviceShortArray);

    return 0;
}
