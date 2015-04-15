#include <iostream>
#include <stdio.h>
#include <mpg123.h>
#include <kiss_fftr.h>
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
int readMP3(char* song, int* a, int* b) {
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

    mpg123_param(mh, MPG123_ADD_FLAGS, MPG123_FORCE_FLOAT, 0);
    if (mpg123_open(mh, song) != MPG123_OK ||
            mpg123_getformat(mh, &rate, &channels, &encoding) != MPG123_OK) {
        fprintf(stderr, "Trouble with mpg123: %s\n", mpg123_strerror(mh));
        cleanup(mh);
        return -1;
    }



    return 0;
}

/* detect_beat
 * Returns the BPM of the given mp3 file
 * @Params: s - the path to the desired mp3
 */
int BeatCalculator::detect_beat(char* s) {
    // Step 1: Get a 5-second sample of our desired mp3
    // Assume the max frequency is 4096
    int max_freq = 4096;
    int sample_size = 2.2 * 2 * max_freq; //This is the sample length of our 5 second snapshot

    // Load mp3

    return 0;
}

// Replicates the "control" part of the Matlab code
int BeatCalculator::control() {
    // Step 1 : Get a 5-second sample of our desired mp3

    // Assume that we are at
    return 0;
}
