function out = spikevalMakePatchVoltageEstimatorStruct(filename, options)
%{
We create a structure, out, containing all of the information necessary to
generate receiver operating characteristic (ROC) curves on the voltage of
the closest electrode to the patched neuron, an estimates of the patched
neuron's voltage derived from voltages of a given number of electrodes.
%}

%{
We load in the electrode and patch data, both bandpass filtered from
100-6000Hz. Electrode data is mean-subtracted. Bad electrodes are removed. 

%}
experiment      = sortaLoadData(filename, options);
%{
Collect the 64 best amplitude-ordered electrodes
%}
if strcmp(filename, options.recording_with_only_58_electrodes) || strcmp(filename, options.recording2_with_only_58_electrodes)
    experiment.mea  = experiment.mea(:, options.electrode_order(1:58)); 
else
    experiment.mea  = experiment.mea(:, options.electrode_order(1:64)); 
end

if options.reverse_mea
    experiment.mea = flipud(experiment.mea);
end

experiment.best_electrode           = -1.*experiment.mea(:,1);

burst_spike_number_for_each_spike   = sortaGetSpikeNumberInBurstIndex(experiment, options.isi_criterion);
burst_criterion                     = 1;
burst_times                         = experiment.spike_times(find(burst_spike_number_for_each_spike > burst_criterion));
non_burst_times                     = setdiff(experiment.spike_times, burst_times);
out.non_burst_times                 = sort(non_burst_times);

if ~isfield(options,'estimator_on_patch_deriv')
    options.estimator_on_patch_deriv = 0;
end 
if options.estimator_on_patch_deriv
    fourier_coefficients_of_patch_voltage_transformed_in_bins       = sortaGetFourierTransformedPatchVoltage(diff(experiment.patch), options);
else
    fourier_coefficients_of_patch_voltage_transformed_in_bins       = sortaGetFourierTransformedPatchVoltage(experiment.patch, options); 
end

if isfield(options, 'zero_out_when_patch_doesnt_spike')
    if options.zero_out_when_patch_doesnt_spike
        electrode_voltages_zeroed_out_when_patched_neuron_isnt_spiking  = sortaZeroOutElectrodesWhenPatchedNeuronIsntSpiking(experiment);
    else
        electrode_voltages_zeroed_out_when_patched_neuron_isnt_spiking = experiment.mea;
    end
else
    electrode_voltages_zeroed_out_when_patched_neuron_isnt_spiking  = sortaZeroOutElectrodesWhenPatchedNeuronIsntSpiking(experiment);
end

convolutive_filters_mat                                         = zeros(options.num_convolution_filter_pts, length(experiment.mea(1,:)));
patch_voltage_estimators_from_single_electrodes_mat             = zeros(experiment.total_samples, length(experiment.mea(1,:)));

if options.parfor
    parfor ii=1:length(experiment.mea(1,:))
        ['Processing electrode ' num2str(ii)]
        convolutive_filters_mat(:,ii)                               = sortaMakeConvolutiveFilter(electrode_voltages_zeroed_out_when_patched_neuron_isnt_spiking(:,ii), fourier_coefficients_of_patch_voltage_transformed_in_bins, options);
        patch_voltage_estimators_from_single_electrodes_mat(:,ii)   = sortaMakePatchVoltageEstimatorFromOneElectrode(convolutive_filters_mat(:,ii), experiment.mea(:,ii), options);

    end
else
    for ii=1:length(experiment.mea(1,:))
        ['Processing electrode ' num2str(ii)]
        convolutive_filters_mat(:,ii)                               = sortaMakeConvolutiveFilter(electrode_voltages_zeroed_out_when_patched_neuron_isnt_spiking(:,ii), fourier_coefficients_of_patch_voltage_transformed_in_bins, options);
        patch_voltage_estimators_from_single_electrodes_mat(:,ii)   = sortaMakePatchVoltageEstimatorFromOneElectrode(convolutive_filters_mat(:,ii), experiment.mea(:,ii), options);
    end
end

centered_convolutive_filters_mat = sortaCenterTheConvolutiveFilters(convolutive_filters_mat, options);
if options.debug_mode
    sortaPlotConvolutiveFilters(centered_convolutive_filters_mat)
end

clearvars electrode_voltages_zeroed_out_when_patched_neuron_isnt_spiking

out.best_electrode                                          = experiment.best_electrode;
out.spike_times                                             = experiment.spike_times;
out.patch                                                   = experiment.patch;
out.patch_voltage_estimators_from_single_electrodes_mat     = patch_voltage_estimators_from_single_electrodes_mat;
out.centered_convolutive_filters_mat                        = centered_convolutive_filters_mat;
out.sample_rate                                             = experiment.mea_sample_rate;

if isfield(options, 'return_all_ordered_electrodes')
    if options.return_all_ordered_electrodes
        out.ordered_electrodes = experiment.mea;
    end
end


































