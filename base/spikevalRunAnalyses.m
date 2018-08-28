function [] = spikevalRunAnalyses(options)

%%
%{
Pipette localization: the pipette tip sends a beacon signal that
is detected across the electrode array. The amplitude of this signal 
across electrodes, combined with the known geometry of the electrodes, 
allows for an estimate of distance of the pipette tip to the electrode 
array. A 1/r model of voltage dropoff was shown to be appropriate for this.

The pipette localization code is adapted from Jacob Bernstein's original
code.
%}
%% Run this section to do pipette tracking on the exemplar recording in figure 1b-f
if options.run_pipette_tracking_exemplar
    % Load data
    options.dataset     = 'pipette_track_exemplar';
    % Pipette tracking needs to know when the voltage pulses ("beacon signal)
    % were active. Change below to "true" to set this manually. Otherwise, it
    % should be hardcoded to give the values in the paper
    options.override_pulse_times = false;
    spikevalLocalizePipette(options);
end
%% Run this section to do pipette tracking on all recordings, which are summarized in figure 1h
if options.run_pipette_tracking_all_recordings
    % Load data
    options.dataset = 'pipette_track_all';
    spikevalLocalizePipette(options);
end
%% Run this section to generate an example ROC curve (like figure 3c, but with 1 minute instead of ~8 minutes of data)
if options.run_roc_example
    
    
    
    
end

%% Run this section to generate an example voltage estimator (like figure 5, but with 1 minute instead of ~8 minutes of data)
if options.run_voltage_estimator_example
    
    
    
end
%% Run this section to generate voltage estimators for all recordings and produce AUCs

if options.run_voltage_estimator_all_recordings
    
    spikevalMakeAUCsFromEstimators(options);
end
