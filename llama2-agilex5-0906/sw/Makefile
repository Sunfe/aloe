CROSS  ?= aarch64-linux-gnu-
CC      = $(CROSS)gcc
CFLAGS  = -O3 -march=armv8.2-a -fopenmp -Wall
LDLIBS  = -lm

all: run run_accel accel_selftest

run: run.c
	$(CC) $(CFLAGS) $< $(LDLIBS) -o $@

run_accel: run.c accel/accel.c
	$(CC) $(CFLAGS) -DUSE_ACCEL $^ $(LDLIBS) -o $@

accel_selftest: accel/accel_selftest.c accel/accel.c
	$(CC) $(CFLAGS) $^ $(LDLIBS) -o $@

clean:
	rm -f run run_accel accel_selftest