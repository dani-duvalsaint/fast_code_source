#!/bin/sh

cd matlab_reference
time matlab -nojvm -nodisplay -nosplash < findsongbpm.m
cd ..
time ./calculatebeat
time ./calculatebeatpar
