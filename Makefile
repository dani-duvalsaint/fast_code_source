BASEDIR = /afs/andrew.cmu.edu/usr4/apenugon/private/15418/finalproject

INCLUDES = -I$(FINAL_PROJECT_PATH)/include -I$(FINAL_PROJECT_PATH)/lib -I$(FINAL_PROJECT_PATH)/kiss_fft130 -I$(FINAL_PROJECT_PATH)/kiss_fft130/tools -I$(FINAL_PROJECT_PATH)/src/BeatCalculator
CXX = g++
CXXFLAGS = -g $(INCLUDES)
LIBFLAGS = -L$(FINAL_PROJECT_PATH)/lib
SRCDIR = $(FINAL_PROJECT_PATH)/src

#Suffix Rules
.SUFFIXES: .cc

#Files 

default : handler

all : fft_test_real fft_test_complex mp3_test handler

handler : $(SRCDIR)/BeatCalculator/BeatCalculator.h $(SRCDIR)/BeatCalculator/BeatCalculator.cpp $(SRCDIR)/Handler/main.cpp
	$(CXX) $(SRCDIR)/Handler/main.cpp $(SRCDIR)/BeatCalculator/BeatCalculator.cpp kiss_fft130/kiss_fft.c kiss_fft130/tools/kiss_fftr.c $(CXXFLAGS) $(LIBFLAGS) -lmpg123 -o calculatebeat

fft_test_real : tests/fft_test_real.cpp
	$(CXX) tests/fft_test_real.cpp kiss_fft130/kiss_fft.c kiss_fft130/tools/kiss_fftr.c $(CXXFLAGS) -o fft_test_real

fft_test_complex : tests/fft_test_complex.cpp
	$(CXX) tests/fft_test_complex.cpp kiss_fft130/kiss_fft.c $(CXXFLAGS) -o fft_test_complex

mp3_test : tests/mp3_test.cpp
	$(CXX) tests/mp3_test.cpp kiss_fft130/kiss_fft.c kiss_fft130/tools/kiss_fftr.c $(CXXFLAGS) $(LIBFLAGS) -lmpg123 -o mp3_test 

clean :
	rm mp3_test fft_test_real fft_test_complex calculatebeat
