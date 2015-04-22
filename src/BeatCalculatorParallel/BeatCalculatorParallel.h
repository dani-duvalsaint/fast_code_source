#ifndef BEAT_CALCULATOR_H
#define BEAT_CALCULATOR_H

class BeatCalculatorParallel {
    private:
        int timecomb();
        int control();
        int hwindow();
        int filterbank();
        int diffrect();
    public:
        BeatCalculatorParallel();
        int detect_beat(char* s);
        ~BeatCalculatorParallel();
};

#endif
