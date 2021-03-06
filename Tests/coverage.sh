#!/bin/sh
./tests.o
gcov *Tests.cpp
lcov -c --rc lcov_branch_coverage=1 -d . -o coverage.info
lcov --remove coverage.info "/boot/system*" -o coverage.info 
lcov --remove coverage.info "c++*" -o coverage.info 
genhtml coverage.info --rc lcov_branch_coverage=1 --output-directory out

