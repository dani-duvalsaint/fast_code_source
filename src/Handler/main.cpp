#include <iostream>
#include <stdio.h>
#include <BeatCalculator.h>

int main() {
  BeatCalculator *calculator = new BeatCalculator();
  calculator->detect_beat("");
  delete calculator;
  printf("Done calling all Detector Functions\n");
  return 0;
}
