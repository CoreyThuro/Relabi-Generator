# Relabi-Generator
SonicPi implementation of John Berndt's Relabi Wave. 

Essay here: https://johnberndt.org/relabi/Relabi_essay.htm

Algorithm used here:

1. Set base frequencies for 3 oscillators
2. Set modulation depth for each oscillator (magnitude with which each oscillator affects the other in step 4.c freq update)
3. Set trigger thresholds ((amplitude?) value the wave must cross to trigger a sample or synth.
4. loop do


    Initialize state for each LFO as LFO_n {phase: 0, prev: 0}

   
    Calculate current phase value for each lfo

   
    Set freq_n = base_freq_n + phase_value*mod_depth_n+1

   
    Calculate new phase = lfo_n[:phase] * freq_n*resolution_sleep

   
    If:

      val_n[:prev] < lfo_n_threshold && val_n > lfo_n_threshold

   
    Then:
   
      trigger lfo_n

   
   end

