#include <iostream>
#include <stdio.h>
#include <BeatCalculator.h>
#include <BeatCalculatorParallel.h>

int main(int argc, char* argv[]) {
  // Test CPU Version
  BeatCalculatorParallel *calculator = new BeatCalculatorParallel();
  int BPM;
  //Pick song to test
  BPM = calculator->detect_beat("songs/headhunterz-150bpm-clip.mp3", atoi(argv[1]));
  delete calculator;
  float error = (float)(BPM - 155)/155;
  printf("Error (CPU OpenMP): BPM: %d \t Error: %f \t \n", BPM, error);
  return 0;
}
