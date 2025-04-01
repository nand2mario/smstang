if {$argc == 0} {
    puts "Usage: $argv0 <device>"
    puts "          device: console60k console138k"
    puts "Currently supports ds2 and usb controller"
    exit 1
}

set dev [lindex $argv 0]

if {$dev eq "console60k"} {
    set_device GW5AT-LV60PG484AC1/I0 -device_version B
    add_file -type cst "src/boards/console.cst"
    add_file -type verilog "src/plla/pll_12.v"
    add_file -type verilog "src/plla/pll_27.v"
    add_file -type verilog "src/plla/pll_53.v"
    add_file -type verilog "src/plla/pll_74.v"
} elseif {$dev eq "console138k"} {
    set_device GW5AT-LV138PG484AC1/I0 -device_version B
    add_file -type cst "src/boards/console.cst"
    add_file -type verilog "src/pll/pll_12.v"
    add_file -type verilog "src/pll/pll_27.v"
    add_file -type verilog "src/pll/pll_53.v"
    add_file -type verilog "src/pll/pll_74.v"
} else {
    error "Unknown device $dev"
}
set_option -output_base_name smstang_${dev}

add_file -type verilog "src/MC8123.v"
add_file -type verilog "src/SEGASYS1_PRGDEC.v"
# add_file -type verilog "src/VM2413/attacktable.sv"
# add_file -type verilog "src/VM2413/controller.sv"
# add_file -type verilog "src/VM2413/envelopegenerator.sv"
# add_file -type verilog "src/VM2413/envelopememory.sv"
# add_file -type verilog "src/VM2413/feedbackmemory.sv"
# add_file -type verilog "src/VM2413/lineartable.sv"
# add_file -type verilog "src/VM2413/operator.sv"
# add_file -type verilog "src/VM2413/opll.sv"
# add_file -type verilog "src/VM2413/outputgenerator.sv"
# add_file -type verilog "src/VM2413/outputmemory.sv"
# add_file -type verilog "src/VM2413/phasegenerator.sv"
# add_file -type verilog "src/VM2413/phasememory.sv"
# add_file -type verilog "src/VM2413/registermemory.sv"
# add_file -type verilog "src/VM2413/sinetable.sv"
# add_file -type verilog "src/VM2413/slotcounter.sv"
# add_file -type verilog "src/VM2413/temporalmixer.sv"
# add_file -type verilog "src/VM2413/vm2413.sv"
# add_file -type verilog "src/VM2413/voicememory.sv"
# add_file -type verilog "src/VM2413/voicerom.sv"
add_file -type verilog "src/ym2413_nuked/ym_lib_sms.v"
add_file -type verilog "src/ym2413_nuked/ym2413.v"
add_file -type verilog "src/audiomix.v"
add_file -type verilog "src/cheatcodes.sv"
add_file -type verilog "src/compressor.sv"
add_file -type verilog "src/dpram.v"
add_file -type verilog "src/hdmi2/audio_clock_regeneration_packet.sv"
add_file -type verilog "src/hdmi2/audio_info_frame.sv"
add_file -type verilog "src/hdmi2/audio_sample_packet.sv"
add_file -type verilog "src/hdmi2/auxiliary_video_information_info_frame.sv"
add_file -type verilog "src/hdmi2/hdmi.sv"
add_file -type verilog "src/hdmi2/packet_assembler.sv"
add_file -type verilog "src/hdmi2/packet_picker.sv"
add_file -type verilog "src/hdmi2/serializer.sv"
add_file -type verilog "src/hdmi2/source_product_description_info_frame.sv"
add_file -type verilog "src/hdmi2/tmds_channel.sv"
add_file -type verilog "src/hybrid_pwm_sd.v"
add_file -type verilog "src/io.v"
add_file -type verilog "src/iosys/controller_ds2.sv"
add_file -type verilog "src/iosys/dualshock_controller.v"
add_file -type verilog "src/iosys/gowin_dpb_menu.v"
add_file -type verilog "src/iosys/iosys_bl616.v"
add_file -type verilog "src/iosys/textdisp.v"
add_file -type verilog "src/iosys/uart_fixed.v"
add_file -type verilog "src/jt89/jt89.v"
add_file -type verilog "src/jt89/jt89_mixer.v"
add_file -type verilog "src/jt89/jt89_noise.v"
add_file -type verilog "src/jt89/jt89_tone.v"
add_file -type verilog "src/jt89/jt89_vol.v"
add_file -type verilog "src/lightgun.sv"
add_file -type verilog "src/parts.v"
add_file -type verilog "src/sdram.v"
add_file -type verilog "src/sms2hdmi.sv"
add_file -type verilog "src/smstang_top.sv"
add_file -type verilog "src/spram.v"
add_file -type verilog "src/sprom.v"
add_file -type verilog "src/system.v"
add_file -type verilog "src/t80/t80.v"
add_file -type verilog "src/t80/t80_alu.v"
add_file -type verilog "src/t80/t80_mcode.v"
add_file -type verilog "src/t80/t80_reg.v"
add_file -type verilog "src/t80/t80pa.v"
add_file -type verilog "src/t80/t80s.v"
add_file -type verilog "src/usb_hid_host.v"
add_file -type verilog "src/vdp.v"
add_file -type verilog "src/vdp_background.v"
add_file -type verilog "src/vdp_cram.v"
add_file -type verilog "src/vdp_main.v"
add_file -type verilog "src/vdp_sprite_shifter.v"
add_file -type verilog "src/vdp_sprites.v"
add_file -type verilog "src/video.v"

set_option -synthesis_tool gowinsynthesis
set_option -top_module smstang_top
set_option -verilog_std sysv2017
set_option -vhdl_std vhd2008
set_option -ireg_in_iob 1
set_option -oreg_in_iob 1
set_option -ioreg_in_iob 1

set_option -place_option 2

run all
