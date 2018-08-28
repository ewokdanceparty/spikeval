function [] = spikevalGet64BestElectrodes(filename_cell, options)

%{
Retrieves a list of electrode indices, for each recording, ordered by the
mean height of the patch-triggered spikes ("amplitude-ordered electrodes").
This is saved in a cell array and written to a .mat file for future use (electrode_order).
 
Also retrieves and saves a virtual reference transformation for each recording, for
future use (virtual_reference).

The mean of the [2^n]th patch triggered spikes, where n={0-6}, is
plotted and saved for each recording, for figure 4a.
%}

options.fig_name                            = 'waveform_on_extracellular_electodes';
options.wfm_start                           = -.001; % in seconds
options.wfm_end                             =  .003;
options.electrodes_to_plot                  = [1 2 4 8 16 32 64];

electrode_order_cell                        = cell(options.num_neurons,1);
%virtual_reference_cell                      = cell(options.num_neurons,1);
spike_timing_cell                           = cell(options.num_neurons,1); % this will be presorted

for ii=1:options.num_neurons
    ['analyzing neuron number ' num2str(ii)]
    filename                                = filename_cell{ii};
    
    options.use_derivative                  = options.use_derivative_vec(ii);
    
    temp                                    = spikevalPlotMeanSpikesOnSeveralElectrodes(filename, options);
    %{
    experiment = sortaLoadData(filename, options);
    
    wfm_mat = colocGetMeanWfms(experiment, options, experiment.spike_times);
    max_wfm_vec = max(abs(wfm_mat'))';
    
    % Now rank order channels
    [B I] = sort(max_wfm_vec, 'descend');
    
    electrode_order = I;
    %}
    electrode_order_cell{ii,1}              = temp.electrode_order;
    spike_timing_cell{ii,1}                 = temp.spike_timing; % sorted already
    %virtual_reference_cell{ii,1}            = temp.virtual_reference_transformation;
end

save([options.working_dir '/config/electrode_order'], 'electrode_order_cell')
save([options.working_dir '/config/spike_timing'], 'spike_timing_cell')
%save([options.working_dir '/config/virtual_reference'], 'virtual_reference_cell')
