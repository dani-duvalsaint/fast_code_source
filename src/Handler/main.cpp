#include <iostream>
#include <stdio.h>
#include <BeatCalculator.h>
#include <BeatCalculatorParallel.h>

int main() {
  printf("Only testing parallel version - check code for improvement\n");

  // Test CPU Version
  BeatCalculator *calculator = new BeatCalculator();
  clock_t begin = clock();
  int BPM;
  //Pick song to test
  BPM = calculator->detect_beat("songs/headhunterz.mp3");
  //BPM = calculator->detect_beat("songs/uz.mp3");
  //BPM = calculator->detect_beat("songs/120bpm.mp3");
  clock_t end = clock();
  double elapsed_secs = double(end-begin)/CLOCKS_PER_SEC;
  delete calculator;
  float error = (float)(BPM - 155)/155;
  printf("Error (CPU OpenMP): BPM: %d \t Error: %f \t Time: %f\n", BPM, error, elapsed_secs);

  // Test GPU Version
  BeatCalculatorParallel *calculator_par = new BeatCalculatorParallel();
  begin = clock();
  BPM = calculator_par->detect_beat("songs/headhunterz.mp3");
  //BPM = calculator->detect_beat("songs/uz.mp3");
  //BPM = calculator_par->detect_beat("songs/120bpm.mp3");
  end = clock();
  elapsed_secs = double(end-begin)/CLOCKS_PER_SEC;
  delete calculator_par;
  error = (float)(BPM-155)/155;
  printf("Error (GPU Cuda): BPM: %d \t Error: %f \t Time: %f\n", BPM, error, elapsed_secs);

  return 0;
}
