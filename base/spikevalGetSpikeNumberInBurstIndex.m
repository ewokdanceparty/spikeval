function burst_index = spikevalGetSpikeNumberInBurstIndex(experiment, isi_criterion)

%{
Label each spike with its position within a burst
burst_index = -1 means a non-burst spike
burst_index = {1,2,3,4,...n} means the ith spike in a burst
%}

n_spikes                    = length(experiment.spike_times (:,1));
isi                         = diff(experiment.spike_times);

%{
Label each spike with its position within a burst
burst_index = -1 means a non-burst spike
burst_index = {1,2,3,4, n} means the ith spike in a burst
%}
burst_index                 = zeros(n_spikes,1);

%% Edge case: the beginning of the recording
if experiment.spike_times(1) > isi_criterion % we know this is not a later spike in a burst, but it still could be the 1st spike in a burst
    % check if this is the 1st spike in a burst
    if isi(1) <= isi_criterion     % check if the time to the next spike is less than the isi criterion
        burst_index(1,1) = 1;  % this is the 1st spike in a burst
    else
        burst_index(1,1) = -1; % this spike is not in a burst
    end
else
    if experiment.spike_times(2) <= isi_criterion
        burst_index(1,1)     = 1; %this may be an nth spike in a burst, but there's no way to know that, so we'll call it the 1st
    else
        burst_index(1,1)     = -1;
    end
end

%% Bulk of the recording
for i=2:(n_spikes-1)
    
    if isi(i-1) <= isi_criterion % check if the time from the previous spike was less than the isi criterion
        burst_index(i,1) = 1 + burst_index(i-1,1);
    else
        if isi(i) <= isi_criterion % check if the time to the next spike is less than the isi criterion
            burst_index(i,1) = 1;  % this is the 1st spike in a burst
        else
            burst_index(i,1) = -1; % this spike is not in a burst
        end
    end
end

%% Edge case: the end of the recording
i = n_spikes;
if isi(i-1) <= isi_criterion % check if the time from the previous spike was less than the isi criterion
    burst_index(i,1) = 1 + burst_index(i-1,1);
else
    burst_index(i,1) = -1; % there is no way of knowing whether this is the 1st spike in a burst or a non-burst spike, so we classify it as the latter
end








