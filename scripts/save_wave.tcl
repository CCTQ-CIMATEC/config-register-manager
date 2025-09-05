# Determine waveform config path
if { [info exists ::env(tb_file)] } {
    set wave_config "$::env(tb_file).wcfg"
} else {
    set wave_config "waveforms.wcfg"
}

# Load existing config or create new one
if {[file exists $wave_config]} {
    open_wave_config $wave_config
} else {
    add_wave -recursive *
    save_wave_config $wave_config
}

# Run simulation
run all

# Save config if GUI was used
if { [info exists ::env(RUN_GUI)] && $::env(RUN_GUI) == 1 } {
    save_wave_config $wave_config
}

# Exit if not in GUI mode
if { ![info exists ::env(RUN_GUI)] || $::env(RUN_GUI) == 0 } {
    quit
}