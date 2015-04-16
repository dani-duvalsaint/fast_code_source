#include <iostream>
#include <stdio.h>
#include <BeatCalculator.h>

int main() {
  BeatCalculator *calculator = new BeatCalculator();
  int BPM = calculator->detect_beat("songs/headhunterz.mp3");
  delete calculator;
  printf("Done calling all Detector Functions\n");
  float error = (float)(BPM - 155)/155;
  printf("Error: %f\n", error);
  return 0;
}
