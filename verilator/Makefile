N=smstang_top
D=../src
SRCS=$D/smstang_top.sv \
	 $D/jt89/jt89.v $D/jt89/jt89_mixer.v $D/jt89/jt89_noise.v $D/jt89/jt89_tone.v $D/jt89/jt89_vol.v \
	 $D/t80/t80s.v $D/t80/t80.v $D/t80/t80_alu.v $D/t80/t80_mcode.v $D/t80/t80_reg.v \
	 $D/vm2413_verilog/vm2413.sv $D/vm2413_verilog/attacktable.sv $D/vm2413_verilog/controller.sv $D/vm2413_verilog/envelopegenerator.sv \
	 $D/vm2413_verilog/envelopememory.sv $D/vm2413_verilog/feedbackmemory.sv $D/vm2413_verilog/lineartable.sv \
	 $D/vm2413_verilog/opll.sv $D/vm2413_verilog/outputgenerator.sv $D/vm2413_verilog/outputmemory.sv $D/vm2413_verilog/phasegenerator.sv \
	 $D/vm2413_verilog/phasememory.sv $D/vm2413_verilog/registermemory.sv $D/vm2413_verilog/sinetable.sv $D/vm2413_verilog/slotcounter.sv \
	 $D/vm2413_verilog/temporalmixer.sv $D/vm2413_verilog/voicememory.sv $D/vm2413_verilog/voicerom.sv $D/vm2413_verilog/operator.sv \
	 $D/verilator/sdram_sim.v $D/verilator/test_loader.v \
	 $D/audiomix.v $D/dpram.v $D/hybrid_pwm_sd.v $D/io.v $D/MC8123.v $D/parts.v \
	 $D/SEGASYS1_PRGDEC.v $D/spram.v $D/sprom.v $D/system.v $D/vdp.v $D/vdp_background.v \
	 $D/vdp_cram.v $D/vdp_main.v $D/vdp_sprites.v $D/vdp_sprite_shifter.v $D/video.v \
	 $D/cheatcodes.sv $D/compressor.sv $D/lightgun.sv

DEPS=
INCLUDES=-I$D

CFLAGS_SDL=$(shell sdl2-config --cflags) -g -O2
LIBS_SDL=$(shell sdl2-config --libs) -g

.PHONY: build sim verilate clean gtkwave audio
	
build: ./obj_dir/V$N

verilate: ./obj_dir/V$N.cpp

./obj_dir/V$N.cpp: sim_main.cpp $(SRCS) $(DEPS)
	@echo
	@echo "### VERILATE ####"
	mkdir -p obj_dir
	verilator --top-module $N +1800-2023ext+sv --trace-fst -Wno-PINMISSING -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -cc --exe -CFLAGS "$(CFLAGS_SDL)" -LDFLAGS "$(LIBS_SDL)" $(INCLUDES) $(SRCS) sim_main.cpp
#	verilator --top-module $N --timing --trace-fst -Wno-WIDTH -Wno-PINMISSING -Wno-UNOPTFLAT -cc --exe -CFLAGS "$(CFLAGS_SDL)" -LDFLAGS "$(LIBS_SDL)" $(INCLUDES) $(SRCS) sim_main.cpp

./obj_dir/V$N: verilate
	@echo
	@echo "### BUILDING SIM ###"
	make -C obj_dir -f V$N.mk V$N
	cp -a $D/mboot.hex .
	ln -sf obj_dir/V$N smstang
	@echo
	@echo "Use ./smstang to run the simulation"

sim: ./obj_dir/V$N
	@echo
	@echo "### SIMULATION (GUI) ###"
	obj_dir/V$N

trace: ./obj_dir/V$N
	@echo
	@echo "### SIMULATION (trace) ###"
	obj_dir/V$N -t

gtkwave:
	gtkwave obj_dir/waveform.fst

audio:
	ffmpeg -y -f s16le -ar 48k -ac 2 -i sms.aud sms.wav

clean:
	rm -rf obj_dir
