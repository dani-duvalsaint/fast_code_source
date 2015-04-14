BASEDIR = /afs/andrew.cmu.edu/usr4/apenugon/private/15418/finalproject

INCLUDES = -I/afs/andrew.cmu.edu/usr4/apenugon/private/15418/finalproject/include -I/afs/andrew.cmu.edu/usr4/apenugon/private/15418/finalproject/lib -I/afs/andrew.cmu.edu/usr4/apenugon/private/15418/finalproject/kiss_fft130 -I/afs/andrew.cmu.edu/usr4/apenugon/private/15418/finalproject/kiss_fft130/tools

CXX = g++
CXXFLAGS = -g $(INCLUDES)

#Suffix Rules
.SUFFIXES: .cc
#Files 
fft_test : 
	$(CXX) fft_test_real.cpp kiss_fft130/kiss_fft.c kiss_fft130/tools/kiss_fftr.c $(CXXFLAGS) -o fft_test_real
