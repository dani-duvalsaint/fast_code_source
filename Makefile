FINAL_PROJECT_PATH = $(shell pwd)

INCLUDES = -I$(FINAL_PROJECT_PATH)/include -I$(FINAL_PROJECT_PATH)/lib -I$(FINAL_PROJECT_PATH)/kiss_fft130 -I$(FINAL_PROJECT_PATH)/kiss_fft130/tools -I$(FINAL_PROJECT_PATH)/src/BeatCalculator -I$(FINAL_PROJECT_PATH)/src/BeatCalculatorParallel
#### Handler stuff
CU_FILES := CudaTest.cu
CU_DEPS :=
NVCC=nvcc
NVCCFLAGS=-O3 -m64 $(INCLUDES)
OBJDIR=objs
OBJS=$(OBJDIR)/kissfft.o $(OBJDIR)/kissfftr.o $(OBJDIR)/cuda.o $(OBJDIR)/beatcalculatorcuda.o $(OBJDIR)/beatcalculatorpar.o $(OBJDIR)/beatcalculator.o $(OBJDIR)/main.o

CXX = g++ -m64
CXXFLAGS = -g $(INCLUDES)
LIBFLAGS = -L$(FINAL_PROJECT_PATH)/lib -L/usr/local/cuda/lib64/ -lcufft -lcudart -lmpg123
SRCDIR = $(FINAL_PROJECT_PATH)/src

EXECUTABLE = calculatebeat

#Suffix Rules
.SUFFIXES: .cc

#Files 

default : $(EXECUTABLE)

all : fft_test_real fft_test_complex mp3_test handler

handler : $(SRCDIR)/BeatCalculator/BeatCalculator.cpp $(SRCDIR)/BeatCalculatorParallel/BeatCalculatorParallel.cpp $(SRCDIR)/Handler/main.cpp
	$(CXX) $(SRCDIR)/Handler/main.cpp $(SRCDIR)/BeatCalculator/BeatCalculator.cpp $(SRCDIR)/BeatCalculatorParallel/BeatCalculatorParallel.cpp kiss_fft130/kiss_fft.c kiss_fft130/tools/kiss_fftr.c (CXXFLAGS) $(LIBFLAGS) -lmpg123 -o calculatebeat

dirs: 
	mkdir -p $(OBJDIR)/

clean:
	rm -rf $(OBJDIR) *.ppm *~ $(EXECUTABLE)

$(EXECUTABLE): dirs $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $(OBJS) $(LIBFLAGS)


$(OBJDIR)/kissfft.o: kiss_fft130/kiss_fft.c
	$(CXX) $< $(CXXFLAGS) -c -o $@


$(OBJDIR)/kissfftr.o: kiss_fft130/tools/kiss_fftr.c
	$(CXX) $< $(CXXFLAGS) -c -o $@


$(OBJDIR)/beatcalculator.o: $(SRCDIR)/BeatCalculator/BeatCalculator.cpp
	$(CXX) $< $(CXXFLAGS) -c -o $@

$(OBJDIR)/beatcalculatorcuda.o: $(SRCDIR)/BeatCalculatorParallel/BeatCalculatorCuda.cu
	$(NVCC) $< $(NVCCFLAGS) -c -o $@

$(OBJDIR)/beatcalculatorpar.o: $(SRCDIR)/BeatCalculatorParallel/BeatCalculatorParallel.cpp
	$(CXX) $< $(CXXFLAGS) -c -o $@


$(OBJDIR)/main.o: $(SRCDIR)/Handler/main.cpp
	$(CXX) $< $(CXXFLAGS) -c -o $@


$(OBJDIR)/cuda.o: $(SRCDIR)/BeatCalculatorParallel/CudaTest.cu
	$(NVCC) $< $(NVCCFLAGS) -c -o $@

fft_test_real : tests/fft_test_real.cpp
	$(CXX) tests/fft_test_real.cpp kiss_fft130/kiss_fft.c kiss_fft130/tools/kiss_fftr.c $(CXXFLAGS) -o fft_test_real

fft_test_complex : tests/fft_test_complex.cpp
	$(CXX) tests/fft_test_complex.cpp kiss_fft130/kiss_fft.c $(CXXFLAGS) -o fft_test_complex

mp3_test : tests/mp3_test.cpp
	$(CXX) tests/mp3_test.cpp kiss_fft130/kiss_fft.c kiss_fft130/tools/kiss_fftr.c $(CXXFLAGS) $(LIBFLAGS) -lmpg123 -o mp3_test 

