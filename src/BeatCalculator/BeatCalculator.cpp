#include <iostream>
#include <stdio.h>
#include "BeatCalculator.h"

BeatCalculator::BeatCalculator() {
    printf("Initialized Beat Calculator\n");
}

int BeatCalculator::detect_beat(char* s) {
    control();
    return 0;
}

// Replicates the "control" part of the Matlab code
int BeatCalculator::control() {
    printf("We're in Control!\n");
    return 0;
}
