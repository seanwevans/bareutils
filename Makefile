# bareutils makefile

ASM=nasm
LD=ld

SRC=$(wildcard src/*.asm)
OBJ=$(patsubst src/%.asm,build/%.o,$(SRC))
BIN=$(patsubst src/%.asm,bin/%,$(SRC))

all: $(BIN)

build/%.o: src/%.asm
	$(ASM) -f elf64 $< -o $@
    
bin/%: build/%.o
	$(LD) -o $@ $<

clean:
	rm -f build/*.o bin/*
