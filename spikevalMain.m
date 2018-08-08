%{
Companion code for Automated in vivo patch clamp evaluation of 
extracellular multielectrode array spike recording capability

Paper authors:
Brian D. Allen, Caroline Moore-Kochlacs, Jacob G. Bernstein, 
Justin P. Kinney, Jorg Scholvin, Luís F. Seoane, Chris Chronopoulos, 
Charlie Lamantia, Suhasa B. Kodandaramaiah, 
Max Tegmark*, Edward S. Boyden*

Authors of this code:
Brian D. Allen, Caroline Moore-Kochlacs, Jacob G. Bernstein
%}
options.data_dir    = '/media/user/NeuroData1/Dropbox (MIT)/Colocalized Recordings';
%{
Pipette localization: the pipette tip sends a beacon signal that
is detected across the electrode array. The amplitude of this signal 
across electrodes, combined with the known geometry of the electrodes, 
allows for an estimate of distance of the pipette tip to the electrode 
array. A 1/r model of voltage dropoff was shown to be appropriate for this.

The pipette localization code is adapted from Jacob Bernstein's original
code.
%}
%%
% Load data
options.dataset     = 'pipette_track_exemplar';
% options.dataset = 'pipette_track_all';
% options.dataset = 'paper_recordings';
% options.dataset = 'all_recordings';

options.override_pulse_times = false;
% spikevalLocalizePipette(options);

%%
%{
An algorithm for assessing potential spike sorting performance as a 
function of electrode density and quantity. Extracellular signals are 
considered as convolutions of the intracellular voltage, and deconvolution
is used to derive the neuron's true spiking state (intracellular voltage) 
from the electrode voltages.
%}

options.dataset                             = 'paper_recordings';
filename_cell                               = spikevalLoadFilenames(options);

options.total_t                             = 45;%456;
options.num_neurons                         = 12;
options.num_convolution_filter_pts          = 512;
options.zero_out_when_patch_doesnt_spike    = 1;
options.isi_criterion                       = 0.02; % 20ms
options.recording_with_only_58_electrodes   = filename_cell{5}; % set this to filename_cell{5} if analyzing the 12 neurons in the paper
options.working_dir                         = '/media/user/NeuroData1/Dropbox (MIT)/spikeval';
options.todays_fig_dir                      = '180807';

options.recording2_with_only_58_electrodes  = 'asdsdaazgasgf';
options.debug_mode                          = 0;

options.reverse_mea = 0;

cd(options.working_dir)
% Create directories for the project, if they don't already exist
spikevalGenerateDirLayout(options);

options.use_derivative_vec  = [0 1 1 1 1 0 1 1 1 1 1 1 ];

% The following only has to be run once. It takes a long time (~15 minutes)
% to run

options.get64BestElectrodes = 0;

if options.get64BestElectrodes
    spikevalGet64BestElectrodes(filename_cell, options)
end

load([options.working_dir '/config/electrode_order.mat']) % this loads electrode_order_cell into memory

options.parfor      = 1; % you can use a parallel for loop to process the electrodes of a recording if your machine has 128GB of RAM

%% Create a patch voltage estimator and generate ROC curves

options.num_neurons     = 1;

number_of_ROC_analyses  = 4;
ROC_cell                = cell(options.num_neurons, number_of_ROC_analyses);

for neuron = 1:options.num_neurons
    
    ['Processing neuron ' num2str(neuron)]
    options.use_derivative          = options.use_derivative_vec(neuron);
    filename                        = filename_cell{neuron};
    options.electrode_order         = electrode_order_cell{neuron};
   % options.virtual_reference       = virtual_reference_cell{neuron};
    
    patch_voltage_estimator_struct  = spikevalMakePatchVoltageEstimatorStruct(filename, options);
    
    options.experiment_type         = 1; % create a ROC curve on the raw electrode voltage
    ROC_cell{neuron, options.experiment_type}             = spikevalSetUpROCAnalysis(filename, patch_voltage_estimator_struct, options);
    
    options.experiment_type         = 2; % create a ROC curve on the raw electrode voltage
    ROC_cell{neuron, options.experiment_type}             = spikevalSetUpROCAnalysis(filename, patch_voltage_estimator_struct, options);
    
    options.experiment_type         = 3; % create a ROC curve on the raw electrode voltage
    ROC_cell{neuron, options.experiment_type}             = spikevalSetUpROCAnalysis(filename, patch_voltage_estimator_struct, options);
    
    options.experiment_type         = 4; % create a ROC curve on the raw electrode voltage
    ROC_cell{neuron, options.experiment_type}             = spikevalSetUpROCAnalysis(filename, patch_voltage_estimator_struct, options);
    
end






















