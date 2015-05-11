sample_size = 
tic
x1 = wavread('../songs/headhunterz.wav');
maxfreq = 4096;
bandlimits = [0 200 400 800 1600 3200];
short_length = length(x1);
maxfreq = sample_size/4.4;

start = floor(short_length/2 - sample_size/2)
stop = floor(short_length/2 + sample_size/2)
  
short_sample = x1(start:stop);  

a = filterbank(short_sample, bandlimits, maxfreq);
  b = hwindow(a, 0.2, bandlimits, maxfreq);
  tic
  c = diffrect(b, length(bandlimits));
  
  % Recursively calls timecomb to decrease computational time
  x1 = wavread('../songs/headhunterz.wav');
  d = timecomb(c, 2, 60, 240, bandlimits, maxfreq)
  toc
