#include <iostream>
#include <stdio.h>
#include <BeatCalculator.h>
#include <BeatCalculatorParallel.h>

int main() {
  printf("Only testing parallel version - check code for improvement\n");

  // Test CPU Version
  BeatCalculator *calculator = new BeatCalculator();
  clock_t begin = clock();
  int BPM = calculator->detect_beat("songs/headhunterz.mp3");
  clock_t end = clock();
  double elapsed_secs = double(end-begin)/CLOCKS_PER_SEC;
  delete calculator;
  float error = (float)(BPM - 155)/155;
  printf("Error (CPU OpenMP): %f, Time: %f\n", error, elapsed_secs);

  // Test GPU Version
  BeatCalculatorParallel *calculator_par = new BeatCalculatorParallel();
  begin = clock();
  BPM = calculator_par->detect_beat("songs/headhunterz.mp3");
  end = clock();
  elapsed_secs = double(end-begin)/CLOCKS_PER_SEC;
  delete calculator_par;
  error = (float)(BPM-155)/155;
  printf("Error (GPU Cuda): %f, Time: %f\n", error, elapsed_secs);

  return 0;
}
