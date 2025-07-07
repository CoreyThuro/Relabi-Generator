# Relabi Wave Generator for Sonic Pi
# Based on the essay "Relabi: Patterns of Self-Erasing Pulse" by John Berndt
#

# Experiment with the parameters below to find different "feels."

use_debug false
use_bpm 120 # This doesn't set the tempo, but affects time-based FX

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# TUNABLE PARAMETERS
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# LFO Base Frequencies: Controls underlying speed of each oscillator.
set :base_freq_1, 2
set :base_freq_2, 3
set :base_freq_3, 5

# LFO Modulation Depths: Controls how much each LFO affects the others in freq update step.
set :mod_depth_1, 1.1
set :mod_depth_2, 0.9
set :mod_depth_3, 1.3

# Trigger Thresholds: The value the wave must cross to trigger a sound.
set :lfo1_threshold, 0.6
set :lfo2_threshold, 0.7
set :lfo3_threshold, 0.8
set :main_threshold, 1.5 # The main wave is a sum of the 3 LFOs

# Engine Resolution: The sleep time for the calculation loop.
set :resolution_sleep, 0.08

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
## STATE INITIALIZATION
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# Initialize state for each LFO (phase and previous value for threshold detection)
set :lfo1, {phase: 0, prev: 0}
set :lfo2, {phase: 0, prev: 0}
set :lfo3, {phase: 0, prev: 0}
set :main_prev, 0


#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
## RELABI ENGINE (Calculates waves)
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

live_loop :relabi_engine do
  # Retrieve current LFO states and parameters
  lfo1 = get :lfo1
  lfo2 = get :lfo2
  lfo3 = get :lfo3
  
  # Calculate the current value of each LFO
  val1 = Math.sin(lfo1[:phase])
  val2 = Math.sin(lfo2[:phase])
  val3 = Math.sin(lfo3[:phase])
  
  # --- Feedback Mechanism ---
  freq1 = (get :base_freq_1) + (val2 * (get :mod_depth_2))
  freq2 = (get :base_freq_2) + (val3 * (get :mod_depth_3))
  freq3 = (get :base_freq_3) + (val1 * (get :mod_depth_1))
  
  # Calculate new phase for each LFO
  new_phase1 = lfo1[:phase] + (freq1 * (get :resolution_sleep))
  new_phase2 = lfo2[:phase] + (freq2 * (get :resolution_sleep))
  new_phase3 = lfo3[:phase] + (freq3 * (get :resolution_sleep))
  
  # --- Triggering ---
  if lfo1[:prev] < (get :lfo1_threshold) && val1 >= (get :lfo1_threshold)
    cue :lfo1_trigger
  end
  if lfo2[:prev] < (get :lfo2_threshold) && val2 >= (get :lfo2_threshold)
    cue :lfo2_trigger
  end
  if lfo3[:prev] < (get :lfo3_threshold) && val3 >= (get :lfo3_threshold)
    cue :lfo3_trigger
  end
  
  main_wave_val = val1 + val2 + val3
  if (get :main_prev) < (get :main_threshold) && main_wave_val >= (get :main_threshold)
    cue :main_trigger
  end
  
  # --- Store State For Next Cycle ---
  # Create new maps with updated values and save them with `set`
  set :lfo1, {phase: new_phase1, prev: val1}
  set :lfo2, {phase: new_phase2, prev: val2}
  set :lfo3, {phase: new_phase3, prev: val3}
  set :main_prev, main_wave_val
  
  sleep get(:resolution_sleep)
end


#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
## INSTRUMENT LOOPS (Listens for cues and triggers sounds)
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

live_loop :part_main do
  sync :main_trigger
  sample :bd_haus, amp: 1.5, cutoff: 110
end

live_loop :part_1 do
  sync :lfo1_trigger
  sample :elec_blip2, rate: rrand(0.75, 1.25), amp: 0.8
end

live_loop :part_2 do
  sync :lfo2_trigger
  sample :drum_cymbal_closed, amp: rrand(0.5, 0.7), pan: rrand(-0.5, 0.5)
end

live_loop :part_3 do
  sync :lfo3_trigger
  use_synth :tb303
  play :e2, release: 0.15, cutoff: rrand(70, 100), amp: 0.7
end
