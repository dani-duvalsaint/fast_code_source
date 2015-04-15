#include <iostream>
#include <stdio.h>
#include <BeatCalculator.h>

int main() {
  BeatCalculator calculator;
  calculator.detect_beat("");
  printf("Done calling all Detector Functions\n");
  return 0;
}
