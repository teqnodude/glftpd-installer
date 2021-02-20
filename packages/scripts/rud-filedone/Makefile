# Keep this in sync with Tcl script which will print to partyline what version it uses
VERSION := 0.4

CC := gcc
CFLAGS := -c -Wall -O2

rud-filedone : rud-filedone.o

samplescript : CFLAGS += -DSAMPLESCRIPT
samplescript : rud-filedone

%.o : %.c .FORCE
	$(CC) $(CFLAGS) -o $@ $<

clean :
	rm -f rud-filedone rud-filedone.o

test: rud-filedone
ifndef BIN
	$(error Usage: make test BIN=<path to rud-filedone>)
else
  ifeq (,$(wildcard $(BIN)))
	$(error $(BIN) doesn't exist.)
  else
	@./rud-filedone-test.tcl $(BIN)
  endif
endif

.FORCE :

.PHONY: install clean test
