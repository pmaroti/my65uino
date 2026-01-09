# Find all .asm source files in the current directory
ASM_SOURCES := $(wildcard *.asm)

# Generate list of target .bin files by replacing .asm extension with .bin
BIN_TARGETS := $(ASM_SOURCES:.asm=.bin)

# Generate list of .lst files that naken_asm creates
LST_FILES := $(ASM_SOURCES:.asm=.lst)

# Default target: build all .bin files
all: $(BIN_TARGETS)

# Print target: display all .asm source files found
print:
	@echo "ASM_SOURCES: $(ASM_SOURCES)"

# Pattern rule: how to build a .bin file from a .asm file
# $< is the first prerequisite (.asm file)
# $@ is the target (.bin file)
%.bin: %.asm
	naken_asm -o $@ -type bin -l $<

# Clean target: remove all generated files
clean:
	rm -f $(BIN_TARGETS) $(LST_FILES)

# Phony targets are not actual files
.PHONY: all clean print
