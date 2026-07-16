# CC := cc
# CFLAGS :=
# LDFLAGS :=

.PHONY: all clean run


all: bin/bang


bin/bang: bin/bang.o
	ld $< -o $@

bin/bang.o: bin/bang.asm
	nasm -f elf64 $< -o $@


clean:
	rm -f bin/bang bin/bang.o

run: bin/bang
	-./bin/bang; \
	EXIT_CODE=$$?; \
	echo "Program exited with code: $$EXIT_CODE"
