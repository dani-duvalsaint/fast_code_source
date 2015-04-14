#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <strings.h>
#include <mpg123.h>
#include <tools/kiss_fftr.h>

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
int* readMp3(String s) {
  mpg123_handle *mh = NULL;
  unsigned char* buffer = NULL;
  size_t buffer_size = 0;
  bool done = false;
  mpg123_param(mh, MPG123_ADD_FLAGS, MPG123_FORCE_FLOAT, 0.);
  return NULL;
}
int main(void)
{

  return 0;
}
