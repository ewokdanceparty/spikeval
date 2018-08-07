function wfm_mat = spikevalGetMeanSpikes(experiment, options, spike_times)

%{
Returns a matrix of mean multielectrode spike waveforms, with n_chans x
spike waveform length
%}

wfm_len             = options.wfm_end - options.wfm_start; % plot 4ms around each spike
wfm_len_in_samples  = round(wfm_len * experiment.mea_sample_rate);
n_chans             = length(experiment.mea(1,:)); %number of electrodes
n_spikes            = length(spike_times);
data_len            = length(experiment.mea(:,1));

wfm_mat = zeros(n_chans, wfm_len_in_samples);
for m=1:n_chans %electrodes
    for n=1:n_spikes
        wfm_peak_sample     = round(spike_times(n)*experiment.mea_sample_rate);
        wfm_start_sample    = wfm_peak_sample + round(options.wfm_start*experiment.mea_sample_rate);
        wfm_end_sample      = wfm_peak_sample + round(options.wfm_end*experiment.mea_sample_rate) - 1;
        
        if wfm_start_sample < 1 % don't include spikes that overlap with the beginning of the recording
            n_spikes = n_spikes - 1;
        elseif wfm_end_sample > data_len % don't include spikes that overlap with the end of the recording
            n_spikes = n_spikes - 1;
        else
            wfm_mat(m,:)        = wfm_mat(m,:) + experiment.mea(wfm_start_sample:wfm_end_sample, m)';
        end
    end
end

wfm_mat = wfm_mat ./ n_spikes;
