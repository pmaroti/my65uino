
PROGRAM=fpga_6502

default:
	yosys -q \
	  -p "synth_gowin -top $(PROGRAM) -json $(PROGRAM).json -family gw1n" \
	  src/$(PROGRAM).v src/ALU.v src/cpu_65c02.v src/rom.v src/RIOT.v
	nextpnr-himbaechel -r \
	  --json $(PROGRAM).json \
	  --write $(PROGRAM)_pnr.json \
	  --freq 27 \
	  --vopt family=GW1N-9C \
	  --vopt cst=tangnano9k.cst \
	  --device GW1NR-LV9QN88PC6/I5
	gowin_pack -d GW1N-9C -o $(PROGRAM).fs $(PROGRAM)_pnr.json


test6532:
	yosys -q \
	  -p "synth_gowin -top test6532 -json test6532.json -family gw1n" \
	  src/test6532.v  src/RIOT.v
	nextpnr-himbaechel -r \
	  --json test6532.json \
	  --write test6532_pnr.json \
	  --freq 27 \
	  --vopt family=GW1N-9C \
	  --vopt cst=tangnano9k.cst \
	  --device GW1NR-LV9QN88PC6/I5
	gowin_pack -d GW1N-9C -o test6532.fs test6532_pnr.json


test6850:
	yosys -q \
	  -p "synth_gowin -top test6850 -json test6850.json -family gw1n" \
	  src/test6850.v  src/acia_6850.v
	nextpnr-himbaechel -r \
	  --json test6850.json \
	  --write test6850_pnr.json \
	  --freq 27 \
	  --vopt family=GW1N-9C \
	  --vopt cst=tangnano9k.cst \
	  --device GW1NR-LV9QN88PC6/I5
	gowin_pack -d GW1N-9C -o test6850.fs test6850_pnr.json	

copyrom:
	hexdump -v -e '16/1 "%02X " "\n"' ../monitor.bin > src/rom.hex

	@echo "Copied ROM!"

clean:
	@rm -f $(PROGRAM).fs $(PROGRAM).json $(PROGRAM)_pnr.json $(PROGRAM).asc
	@echo "Clean!"

