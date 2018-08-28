function out = spikevalMakeROCCurvesHelper(test_signal_spike_amplitudes, test_signal_spike_times, ground_truth_spike_times, ROC_step, options)

TP          = zeros(options.number_of_thresholds_for_ROC,1);
FP          = zeros(options.number_of_thresholds_for_ROC,1);

TP_raw      = zeros(options.number_of_thresholds_for_ROC,1);
FP_raw      = zeros(options.number_of_thresholds_for_ROC,1);
GT          = length(ground_truth_spike_times);

F_scores    = zeros(options.number_of_thresholds_for_ROC,1);

for ii=1:options.number_of_thresholds_for_ROC
    
    if mod(100, ii) == 0
        ['ROC step ' num2str(ii)]
    end
    
    current_threshold               = ii*ROC_step;
    spikes_over_threshold_indices   = find(test_signal_spike_amplitudes > current_threshold);
    times_of_spikes_over_threshold  = test_signal_spike_times(spikes_over_threshold_indices);
    
    %{
    Now loop over the ground truth spikes, looking for matching spikes in
    the test signal. If one is found within options.time_window, count that
    as a true positive
    %}
    
    for jj=1:length(ground_truth_spike_times)
        
        spikes_before_range_max     = find(times_of_spikes_over_threshold < (ground_truth_spike_times(jj) + options.time_window));

        spikes_after_range_min      = find(times_of_spikes_over_threshold >= (ground_truth_spike_times(jj) - options.time_window));
        spikes_in_range             = intersect(spikes_before_range_max, spikes_after_range_min);
        

        
        if length(spikes_in_range) > 0
            TP(ii) = TP(ii) + 1;
        end
    end
    
    FP(ii) = length(spikes_over_threshold_indices) - TP(ii);
    
    % Now normalize to the total number of ground truth spikes
    
    TP_raw(ii) = TP(ii);
    FP_raw(ii) = FP(ii);
    
    TP(ii) = TP(ii) / length(ground_truth_spike_times);
    FP(ii) = FP(ii) / length(ground_truth_spike_times);
    
    F1 = 2*TP_raw(ii) / (2*TP_raw(ii) + FP_raw(ii) + (GT - TP_raw(ii)));
    F_scores(ii,1) = F1;
    
end

out.TP = TP;
out.FP = FP;

out.TP_raw = TP_raw;
out.FP_raw = FP_raw;
out.GT = GT;
out.f1_score = F_scores;