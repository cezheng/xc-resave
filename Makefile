CC=gcc
SOURCE=main.m
CFLAGS=-Wall -Werror -arch x86_64 -v -Os $(SOURCE)
LDFLAGS= -framework Foundation
OUT=-o xc-resave
all:
	$(CC) $(CFLAGS) $(LDFLAGS) $(OUT)
