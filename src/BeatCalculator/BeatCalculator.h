#ifndef BEAT_CALCULATOR_H
#define BEAT_CALCULATOR_H

class BeatCalculator {
    private:
        int timecomb();
        int control();
        int hwindow();
        int filterbank();
        int diffrect();
    public:
        BeatCalculator();
        int detect_beat(char* s);
        ~BeatCalculator();
};

#endif
