#!/bin/sh

cd matlab_reference
sed '1s/.*/sample_size='$1'/' findsongbpm.m > runscript.m
time matlab -nojvm -nodisplay -nosplash < runscript.m
rm -f runscript.m
cd ..
time ./calculatebeat $1
time ./calculatebeatpar $1
