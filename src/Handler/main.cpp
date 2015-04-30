#include <iostream>
#include <stdio.h>
#include <BeatCalculator.h>
#include <BeatCalculatorParallel.h>

int main() {
  printf("Only testing parallel version - check code for improvement\n");
  //BeatCalculator *calculator = new BeatCalculator();
  //int BPM = calculator->detect_beat("songs/headhunterz.mp3");
  //delete calculator;
  //float error = (float)(BPM - 155)/155;
  //printf("Error (Single-threaded): %f\n", error);
  BeatCalculatorParallel *calculator_par = new BeatCalculatorParallel();
  int BPM = calculator_par->detect_beat("songs/headhunterz.mp3");
  delete calculator_par;
  float error = (float)(BPM-155)/155;
  printf("Error (Single-threaded): %f\n", error);

  return 0;
}
