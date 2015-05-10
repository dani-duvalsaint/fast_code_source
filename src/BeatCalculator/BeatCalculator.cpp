#include <iostream>
#include <stdio.h>
#include <mpg123.h>
#include "omp.h"
#include <kiss_fftr.h>
#include <cmath>
#include "BeatCalculator.h"

BeatCalculator::BeatCalculator() {
    printf("Initialized Beat Calculator\n");
}

BeatCalculator::~BeatCalculator() {
    printf("Terminated Beat Calculator\n");
}

void cleanup(mpg123_handle* mh) {
    mpg123_close(mh);
    mpg123_delete(mh);
    mpg123_exit();
}

/*
 * Reads the values in the mp3 file indicated, and
 * stores them in the a and b arrays.
 * @Params: song - file path of the mp3 file
 *          a - holds left ear data
 *          b - holds right ear data
 */
int readMP3(char* song, float* sample, int sample_size) {
    mpg123_handle *mh = NULL;
    int err = MPG123_OK;
    int channels = 0, encoding = 0;
    long rate;
    err = mpg123_init();
    if (err != MPG123_OK || (mh = mpg123_new(NULL, &err)) == NULL) {
        fprintf(stderr, "Basic setup is going bad: %s\n", mpg123_plain_strerror(err));
        cleanup(mh);
        return -1;
    }

    mpg123_param(mh, MPG123_ADD_FLAGS, MPG123_FORCE_FLOAT | MPG123_MONO_MIX, 0);
    if (mpg123_open(mh, song) != MPG123_OK ||
            mpg123_getformat(mh, &rate, &channels, &encoding) != MPG123_OK) {
        fprintf(stderr, "Trouble with mpg123: %s\n", mpg123_strerror(mh));
        cleanup(mh);
        return -1;
    }

    printf("Rate: %ld \t Channels: %d \t Encoding: %d \n",rate,channels, mpg123_encsize(encoding));
    if (encoding != MPG123_ENC_SIGNED_16 && encoding != MPG123_ENC_FLOAT_32) {
        cleanup(mh);
        fprintf(stderr, "Bad encoding! 0x%x!\n", encoding);
        return -1;
    }

    if (encoding == MPG123_ENC_FLOAT_32) {
      printf("Using 32-bit floats \n");
    }

    // Ensure format does not change
    mpg123_format_none(mh);
    mpg123_format(mh, rate, channels, encoding);

    //Read mp3
    mpg123_scan(mh);
    size_t buffer_size = mpg123_length(mh);
    float* buffer = (float*)malloc(sizeof(float) * buffer_size);
    size_t done = 0;

    if (mpg123_read(mh, (unsigned char*)buffer, sizeof(float)*buffer_size, &done) != MPG123_OK) {
        cleanup(mh);
        fprintf(stderr, "Read went wrong\n");
        return -1;
    }

    printf("Buffer Size: %d \t Actual number of bytes written: %d \n", buffer_size,done);

    // Calculate sample indices
    int start = buffer_size/2 - sample_size/2;

    //for(int i=start; i< sample_size + start; i++) {
    //  printf("Buffer[%d]: \t %f \n", i, buffer[i]);
    //}

    memcpy(sample, buffer + start, sample_size * sizeof(float));

    free(buffer);

    cleanup(mh);

    return 0;
}

void fftrArray(float* sample, int size, kiss_fft_cpx* out) {
    kiss_fftr_cfg cfg;

    int i;

    if ((cfg = kiss_fftr_alloc(size, 0, NULL, NULL)) == NULL) {
        printf("Not enough memory to allocate fftr!\n");
        exit(-1);
    }
    //#pragma omp parallel for
    //for (int i = 0; i < size; i++) {
    //    in[i] = sample[i];
    //}

  kiss_fftr(cfg, (kiss_fft_scalar*)sample, out);
    free(cfg);
}

void fftArray(unsigned int* sample, int size, kiss_fft_cpx* out) {
  kiss_fft_cpx in[size/2];
  kiss_fft_cfg cfg;
  int i;

  if ((cfg = kiss_fft_alloc(size/2, 0, NULL, NULL)) == NULL) {
    printf("Not Enough Memory?!?");
    exit(-1);
  }

  //set real components to one side of stereo input, complex to other
  for(i=0; i < size; i+=2) {
    in[i/2].r = sample[i];
    in[i/2].i = sample[i+1];
  }

  kiss_fft(cfg, in, out);
  free(cfg);

}

int combfilter(kiss_fft_cpx fft_array[], int size, int sample_size, int start, int fin, int step) {
    int AmpMax = 2147483647;
    int energyCount = (fin - start)/step;
    double E[energyCount];
    int count = 0;
    // Iterate through all possible BPMs
    //#pragma omp parallel for
    for (int i = 0; i < energyCount; i++) {
        int BPM = start + i * step;
        int Ti = 60 * 44100/BPM;
        float l[sample_size];
        count = 0;
        //printf("BPM: %d Sample Size: %d Ti: %d\n", BPM, sample_size, Ti);

        for (int k = 0; k < sample_size; k+=2) {
            if ((k % Ti) == 0) {
                count++;
                l[k] = (float)AmpMax;
                l[k+1] = (float)AmpMax;
            }
            else {
                l[k] = 0;
                l[k+1] = 0;
            }
        }
        //printf("Number of peaks: %d \n", count);

        kiss_fft_cpx out[sample_size/2+1];

        fftrArray(l, sample_size, out);
        double sum = 0;
        for (int k = 0; k < sample_size/2+1; k++) {
            //printf("sample: %f %f \t %d BPM comb: %f %f \t ",fft_array[k].r, fft_array[k].i, BPM, out[k].r, out[k].i);
            float a = fft_array[k].r * out[k].r - fft_array[k].i * out[k].i;
            float b = fft_array[k].r * out[k].i + fft_array[k].i * out[k].r;
            //printf("a: %f b: %f \t ", a ,b);
            //int temp = (fft_array[k].r * out[k].r) - (fft_array[k].r * out[k].i) - (fft_array[k].i * out[k].r) - (fft_array[k].i * out[k].i);
            double temp = std::sqrt(a*a + b*b);
            sum += temp;
            //printf("Added %f to E[%d], value of %f\n", temp, i, sum);
        }
        //printf("E[%d]: %f\n", i, sum);
        E[i] = sum;
    }

    //Calculate max of E[k]
    double max = -1;
    int index = -1;
    for (int i = 0; i < energyCount; i++) {
        printf("BPM: %d \t Energy: %f\n", start + i*step, E[i]);
        if (E[i] > max) {
            max = E[i];
            index = i;
        }
    }
    return start + index * step;
}


/* detect_beat
 * Returns the BPM of the given mp3 file
 * @Params: s - the path to the desired mp3
 */
int BeatCalculator::detect_beat(char* s) {
    // Step 1: Get a 5-second sample of our desired mp3
    // Assume the max frequency is 4096
    int max_freq = 4096;
    int sample_size = 2.2 * 4 * max_freq; //This is the sample length of our 5 second snapshot

    // Load mp3
    float* sample = (float*)malloc(sizeof(float) * sample_size);
    readMP3(s, sample, sample_size);
    //for (int i = 0; i < sample_size; i++) {
    //    printf("Element %i: %i\n", i, sample[i]);
    //}

    // Step 2: Differentiate
    float* differentiated_sample = (float*)malloc(sizeof(float) * sample_size);
    int Fs = 44100;
    differentiated_sample[0] = sample[0];
    //#pragma omp parallel for
    for (int i = 1; i < sample_size - 1; i++) {
        differentiated_sample[i] = Fs * (sample[i+1]-sample[i-1])/2; //TODO: Look here if this is messing up
    }
    differentiated_sample[sample_size - 1] = sample[sample_size-1];

    // Step 3: Compute the FFT
    kiss_fft_cpx out[sample_size/2+1];
    fftrArray(differentiated_sample, sample_size, out);

    //for (int i = 0; i < sample_size / 2; i++)
    //  printf("out[%2zu] = %+f , %+f\n", i, out[i].r, out[i].i);

    printf("Combfilter performing...\n");

    int BPM = combfilter(out, sample_size / 2 +1, sample_size, 60, 210, 5);
    BPM = combfilter(out, sample_size / 2 + 1, sample_size, BPM-5, BPM+5, 1);

    printf("Final BPM: %i\n", BPM);

    // Step 4: Generate Sub-band array values
    free(sample);

    return BPM;
}

// Replicates the "control" part of the Matlab code
int BeatCalculator::control() {
    // Step 1 : Get a 5-second sample of our desired mp3

    // Assume that we are at
    return 0;
}
