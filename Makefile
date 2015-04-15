BASEDIR = /afs/andrew.cmu.edu/usr4/apenugon/private/15418/finalproject

INCLUDES = -I$(FINAL_PROJECT_PATH)/include -I$(FINAL_PROJECT_PATH)/lib -I$(FINAL_PROJECT_PATH)/kiss_fft130 -I$(FINAL_PROJECT_PATH)/kiss_fft130/tools

CXX = g++
CXXFLAGS = -g $(INCLUDES)
LIBFLAGS = -L$(FINAL_PROJECT_PATH)/lib

#Suffix Rules
.SUFFIXES: .cc

#Files 
fft_test_real : fft_test_real.cpp
	$(CXX) fft_test_real.cpp kiss_fft130/kiss_fft.c kiss_fft130/tools/kiss_fftr.c $(CXXFLAGS) -o fft_test_real

fft_test_complex : fft_test_complex.cpp
	$(CXX) fft_test_complex.cpp kiss_fft130/kiss_fft.c $(CXXFLAGS) -o fft_test_complex

mp3_test : mp3_test.cpp
	$(CXX) mp3_test.cpp kiss_fft130/kiss_fft.c kiss_fft130/tools/kiss_fftr.c $(CXXFLAGS) $(LIBFLAGS) -lmpg123 -o mp3_test 

clean :
	rm mp3_test fft_test_real
