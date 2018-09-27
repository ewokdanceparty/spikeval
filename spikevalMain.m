%{
Companion code for Automated in vivo patch clamp evaluation of 
extracellular multielectrode array spike recording capability

Paper authors:
Brian D. Allen, Caroline Moore-Kochlacs, Jacob G. Bernstein, 
Justin P. Kinney, Jorg Scholvin, Luis F. Seoane, Chris Chronopoulos, 
Charlie Lamantia, Suhasa B. Kodandaramaiah, 
Max Tegmark*, Edward S. Boyden*

Authors of this code:
Brian D. Allen, Caroline Moore-Kochlacs, Jacob G. Bernstein
%}
% Set the root directory for the data
options.data_dir        = '/media/user/NeuroData1/Dropbox (MIT)/Colocalized Recordings';

options.data_dir        = '/media/user/NeuroData6/PatchAndMEA_BoydenLab';

% Base directory for the code
options.working_dir     = '/media/user/NeuroData1/Dropbox (MIT)/spikeval';
% What you would like to name the figure subfolder
options.todays_fig_dir  = '180927';
% Run pipette tracking on the exemplar recording from figure 1b-f
options.run_pipette_tracking_exemplar           = 0;
% Run pipette tracking on all recordings, which are summarized in figure 1h
% (may take several minutes)
options.run_pipette_tracking_all_recordings     = 1;
% Generate an example ROC curve (like figure 3c, but with 1 minute instead of ~8 minutes of data)
options.run_roc_example                         = 0;
% Generate an example voltage estimator (like figure 5, but with 10s instead of ~8 minutes of data)
% This should be run on a computer with at least 16GB RAM
options.run_voltage_estimator_example           = 0;
% Generate voltage estimators for all recordings and produce AUCs. This was
% tested on a computer with 128GB RAM and took several hours to run.
options.run_voltage_estimator_all_recordings    = 0;

spikevalRunAnalyses(options);





















