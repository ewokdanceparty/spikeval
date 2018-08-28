function out = spikevalMakeROCCurves(test_signal, sample_rate, ground_truth_spike_times, ground_truth_non_burst_spike_times, options)
out = []

%{
This generates ROC curves on a test signal, when including or excluding burst
spikes.

The output structure, out, contains the following fields:

out.all_spikes
out.no_burst_spikes

each of these contains the following fields:

TP (true positives)
FP (false positives)
area (area under the ROC curve)

This function assumes data(spikes) are positive deflections
%}

options.time_window                         = .001; %look +/- 1ms for spikes matching patch spikes % changed to 100us on 2/28/18
options.number_of_thresholds_for_ROC        = 100;
if ~isfield(options, 'roc_threshold_mult')
    options.roc_threshold_mult = 2;
end

test_signal_spike_indices                   = spikevalFindSpikesByThreshold(test_signal, 'ThresholdMult', options.roc_threshold_mult);
test_signal_spike_times                     = test_signal_spike_indices ./ sample_rate;
test_signal_spike_amplitudes                = test_signal(test_signal_spike_indices);
test_signal_max_spike_amplitudes            = max(test_signal_spike_amplitudes);

ROC_step                                    = test_signal_max_spike_amplitudes / options.number_of_thresholds_for_ROC;
ROC_curve                                   = spikevalMakeROCCurvesHelper(test_signal_spike_amplitudes, test_signal_spike_times, ground_truth_spike_times, ROC_step, options);
% figure
% plot(ROC_curve.FP, ROC_curve.TP, 'Marker', 'o')
% xlim(0:1.2)
% ylim(0:1)
ROC_curve_capped_at_FP_equals_1             = spikevalCapROCAndGetAreaUnderCurve(ROC_curve.TP, ROC_curve.FP);
% figure
% plot(ROC_curve_capped_at_FP_equals_1.FP, ROC_curve_capped_at_FP_equals_1.TP, 'Marker', 'o')
% xlim(0:1.2)
% ylim(0:1)
out.all_spikes                              = ROC_curve_capped_at_FP_equals_1;
out.raw_for_fscore                          = ROC_curve;

if options.analyze_bursts == 1
    ROC_curve_no_bursts                         = spikevalMakeROCCurvesHelper(test_signal_spike_amplitudes, test_signal_spike_times, ground_truth_non_burst_spike_times, ROC_step, options);
    ROC_curve_no_bursts.FP                      = ROC_curve.FP; % Double check that this is kosher

    ROC_curve_no_bursts_capped_at_FP_equals_1   = spikevalCapROCAndGetAreaUnderCurve(ROC_curve_no_bursts.TP, ROC_curve_no_bursts.FP);


    out.no_burst_spikes                         = ROC_curve_no_bursts_capped_at_FP_equals_1;
end

