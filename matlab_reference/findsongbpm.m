x1 = wavread('../songs/headhunterz.wav');
maxfreq = 4096;
bandlimits = [0 200 400 800 1600 3200];
short_length = length(x1);
 sample_size = floor(2.2*2*maxfreq); 
  

start = floor(short_length/2 - sample_size/2)
stop = floor(short_length/2 + sample_size/2)
  
short_sample = x1(start:stop);  

a = filterbank(short_sample, bandlimits, maxfreq);
  b = hwindow(a, 0.2, bandlimits, maxfreq);
  c = diffrect(b, length(bandlimits));
  
  % Recursively calls timecomb to decrease computational time
  
  d = timecomb(c, 2, 60, 240, bandlimits, maxfreq);
