function out = spikevalGetSpikeTimesByBurstCriterion(filename, options)

if options.use_derivative
    temp_spike_times      = h5read(filename,'/spikes/derivspiketimes');
else
    temp_spike_times      = h5read(filename,'/spikes/spiketimes');
end
experiment.spike_times      = temp_spike_times(temp_spike_times < options.total_t);

%% Retrieve times of non-burst spikes
burst_index                 = spikevalGetSpikeNumberInBurstIndex(experiment, options.isi_criterion);

out = [];
% if length(options.burst_spike_target) > 1
%     for i=1:length(options.burst_spike_target)
%        out             = [out ; experiment.spike_times(find(burst_index == options.burst_spike_target(i)))]; 
%     end
%     out = sort(out);
% else %%%%%%%%%%%%%%%%%DEBUGGING
%     %out             = experiment.spike_times(find(burst_index == options.burst_spike_target));
%     out             = experiment.spike_times(find(burst_index > options.burst_spike_target));
% end

if options.burst_spike_target % return burst spikes
    out             = experiment.spike_times(find(burst_index > 1));
else % return non-burst spikes
    out             = experiment.spike_times(find(burst_index <= 1));
end


%% Edge conditions

% get rid of wfms that overlap with the beginning of the recording
if ~isempty(out)
    go = 1;
    while go == 1
        if (out(1) + options.wfm_start) < 0
            out = out(2:end);
        else
            go = 0;
        end
    end
end

% get rid of wfms that overlap with the end of the recording
% 
% go = 1;
% while go == 1
%     if (out(end) + options.wfm_end) > options.last_recording_sample_time
%         out = out(1:(end-1));
%     else
%         go = 0;
%     end
% end

