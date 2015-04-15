#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string>
#include <mpg123.h>
#include <kiss_fftr.h>

#ifndef M_PI
#define M_PI 3.14159265358979324
#endif

#define N 16

void TestFftReal(const char* title, const kiss_fft_scalar in[N], kiss_fft_cpx out[N / 2 + 1])
{
  kiss_fftr_cfg cfg;

  printf("%s\n", title);

  if ((cfg = kiss_fftr_alloc(N, 0/*is_inverse_fft*/, NULL, NULL)) != NULL)
  {
    size_t i;

    kiss_fftr(cfg, in, out);
    free(cfg);

    for (i = 0; i < N; i++)
    {
      printf(" in[%2zu] = %+f    ",
             i, in[i]);
      if (i < N / 2 + 1)
        printf("out[%2zu] = %+f , %+f",
               i, out[i].r, out[i].i);
      printf("\n");
    }
  }
  else
  {
    printf("not enough memory?\n");
    exit(-1);
  }
}

void cleanup(mpg123_handle *mh) {
    mpg123_close(mh);
    mpg123_delete(mh);
    mpg123_exit();
}

int* readMp3(std::string s) {
  mpg123_handle *mh = NULL;
  unsigned char* buffer = NULL;
  size_t buffer_size = 0;
  size_t done = 0;
  int err = MPG123_OK;
  int channels = 0, encoding = 0;
  long rate = 0;
  off_t samples = 0;

  err = mpg123_init();
  if (err != MPG123_OK || (mh = mpg123_new(NULL, &err)) == NULL) {
    fprintf(stderr, "Basic setup is going bad: %s\n", mpg123_plain_strerror(err));
    cleanup(mh);
    return NULL;
  }

  mpg123_param(mh, MPG123_ADD_FLAGS, MPG123_FORCE_FLOAT, 0.);
  if (mpg123_open(mh, "headhunterz.wav") != MPG123_OK ||
      mpg123_getformat(mh, &rate, &channels, &encoding) != MPG123_OK) {
    fprintf(stderr, "Trouble with mpg123: %s\n", mpg123_strerror(mh));
    cleanup(mh);
    return NULL;
  }

  if (encoding != MPG123_ENC_SIGNED_16 && encoding != MPG123_ENC_FLOAT_32) {
    cleanup(mh);
    fprintf(stderr, "Bad encodingL 0x%x!\n", encoding);
    return NULL;
  }
  // Ensure output format does not change
  mpg123_format_none(mh);
  mpg123_format(mh, rate, channels, encoding);

  // Actually read mp3
  mpg123_scan(mh);
  samples = mpg123_length(mh);
  int spf = mpg123_spf(mh);
  double tpf = mpg123_tpf(mh);
  printf("Number of samples: %i, spf: %i, tpf: %f, Length: %f\n", samples, spf, tpf, samples/spf * tpf);

  buffer_size = mpg123_outblock(mh);
  buffer = (unsigned char*)malloc(buffer_size * sizeof(char));

  //mpg123_read(mh, buffer, buffer_size, done);

  cleanup(mh);

  return NULL;
}
int main(void)
{
  readMp3("");
  return 0;
}
