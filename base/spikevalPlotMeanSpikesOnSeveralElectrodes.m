function out    = spikevalPlotMeanSpikesOnSeveralElectrodes(filename, options)
%{
Inner function for spikevalGet64BestElectrodes

Retrieves a list of electrode indices, for a particular recording, ordered 
by the mean height of the patch-triggered spikes ("amplitude-ordered 
electrodes"). This is returned, along with a virtual reference
transformation for the electrode data, which will be used in downstream
analyses.

output: out.electrode_order
        out.virtual_reference_transformation

The mean of the [2^n]th patch triggered spikes, where n={0-6}, is 
plotted and saved for the recording, for figure 4a.
%}

%% Load in the MEA data
experiment.mea_sample_rate  = h5readatt(filename, '/', 'MEAsamplerate');
experiment.probe_layout     = h5readatt(filename, '/', 'probelayout');
experiment.total_channels   = experiment.probe_layout(1) * experiment.probe_layout(2);
experiment.bad_channels     = h5readatt(filename, '/', 'badchannels');
experiment.good_channels    = setdiff(1:experiment.total_channels, experiment.bad_channels);

mea_temp                    = h5read(filename, '/filtered/filteredMEA', [1 1], [options.total_t * experiment.mea_sample_rate Inf]);
experiment.mea              = mea_temp(:, experiment.good_channels);
clear mea_temp
%{
if strcmp(filename, options.recording_with_wrong_multiplier)
    experiment.mea = experiment.mea .* .195;
end
%}
%% Do virtual referencing on the electrode data with a mean subtraction, and save this
%out.virtual_reference_transformation    = sortaGetVirtualReferenceTransform(experiment.mea');

%% Retrieve spike times of spikes that were either not in a burst, or the first spike in a burst
%%%%%%%%%%%%%%%%%%%%%%DEBUG
options.burst_spike_target          = 0;
options.last_recording_sample_time  = length(experiment.mea(:,1)) / experiment.mea_sample_rate;

%% DEBUGGING

options.burst_spike_target          = 0;
experiment.non_burst_spike_times    = spikevalGetSpikeTimesByBurstCriterion(filename, options);
options.burst_spike_target          = 1;
experiment.burst_spike_times        = spikevalGetSpikeTimesByBurstCriterion(filename, options);

%% Retrieve mean waveforms from these spikes
wfm_mat = spikevalGetMeanSpikes(experiment, options, sort([experiment.non_burst_spike_times ; experiment.burst_spike_times], 'ascend')); %including all spikes
[max_wfm_vec, max_wfm_vec_idx] = max(abs(wfm_mat')); % getting trough of each mean waveform
max_wfm_vec         = max_wfm_vec';
max_wfm_vec_idx     = max_wfm_vec_idx';

%% Now rank order channels by mean spike amplitude
% ordering the electrodes, including burst spikes 
[B out.electrode_order] = sort(max_wfm_vec, 'descend');

out.spike_timing        = round(max_wfm_vec_idx(out.electrode_order) - abs(options.wfm_start) * experiment.mea_sample_rate) / experiment.mea_sample_rate;

% figure
% plot(spike_timing_idx)

%wfm_mat = wfm_mat(out.electrode_order,:);

%% Get timing of maximum waveform deflection for each


%% Now, recalculate wfm_mat with only non-burst spikes, for plotting
wfm_mat = spikevalGetMeanSpikes(experiment, options,experiment.non_burst_spike_times);
%% Order wfm_mat
wfm_mat = wfm_mat(out.electrode_order,:); % use the ordering though from before
%% 

%% Make the figure of mean spike waveforms

colorz = zeros(7,3);

colorz(1,:) = [.5 .5 .5]; %grey
colorz(2,:) = [1 0 0]; %red
colorz(3,:) = [0 1 0]; %green
colorz(4,:) = [1 0 1]; %magenta
colorz(5,:) = [1 1 0]; %yellow
colorz(6,:) = [0 0 1]; %blue
colorz(7,:) = [1 .5 0];%orange

mean_wfm_fig = figure
for i=1:length(options.electrodes_to_plot)
    if i== 7
        %if ~options.debug_on_best_recording
            %if strcmp(filename, options.recording_with_only_58_electrodes) || strcmp(filename, options.recording2_with_only_58_electrodes)
            if size(experiment.mea,2)<64
                mean_wfm_mat    = wfm_mat(58,:);
            else
                mean_wfm_mat    = wfm_mat(options.electrodes_to_plot(i),:);
            end
        %end
    else
        mean_wfm_mat    = wfm_mat(options.electrodes_to_plot(i),:);
    end
    x               = (1:length(mean_wfm_mat))./experiment.mea_sample_rate .* 1000 - 1;
    plot(x, mean_wfm_mat, 'Color', colorz(i,:))
    hold on
end
%% Annotate the figure
n = length(experiment.non_burst_spike_times);
n_burst = length(experiment.burst_spike_times);
set(gca, 'XTick', [-1 0 1 2 3])
set(gca, 'box', 'off')
set(gca, 'color', 'none')
title_cell = cell(3,1);
title_cell{1} = ['Mean waveform from ' num2str(n) ' spikes'];
title_cell{2} = ['Num burst spikes: ' num2str(n_burst)];
title_cell{3} = filename((end-30):end);

title(title_cell, 'Interpreter', 'none')

%% Save the figure
fig_cell        = [];
fig_name_cell   = [];

fig_cell        = [fig_cell {mean_wfm_fig}];
fig_name_cell   = [fig_name_cell {options.fig_name}];
spikevalSaveFigures(filename, fig_cell, fig_name_cell, options)