#ifndef BEAT_CALCULATOR_PAR_H
#define BEAT_CALCULATOR_PAR_H

#ifndef LIBINC
#define LIBINC
#include <mpg123.h>
#include <kiss_fftr.h>
#endif

class BeatCalculatorParallel {
    private:
        int timecomb();
        int control();
        int hwindow();
        int filterbank();
        int diffrect();
        void cleanup(mpg123_handle* mh);
        int readMP3(char* song, unsigned short* sample);
        void fftrArray(unsigned short* sample, int size, kiss_fft_cpx* out);
        void fftArray(unsigned short* sample, int size, kiss_fft_cpx* out);
        int combfilter(kiss_fft_cpx* fft_array, int size, int sample_size);
    public:
        BeatCalculatorParallel();
        int detect_beat(char* s);
        ~BeatCalculatorParallel();
};

#endif
