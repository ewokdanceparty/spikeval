function ROCCurves = spikevalSetUpROCAnalysis(filename, estimator_struct, options)

ROCCurves = [];
options.analyze_bursts = 1;

b           = estimator_struct.sample_rate;
c           = estimator_struct.spike_times;
d           = estimator_struct.non_burst_times;

if strcmp(filename, options.recording_with_only_58_electrodes) || strcmp(filename, options.recording2_with_only_58_electrodes)
    ordered_electrodes = 1:58;
else
    ordered_electrodes = 1:64;
end

switch options.experiment_type
    case 1 % generate on raw voltage of best electrode, compare bursting and not bursting
        
        a           = estimator_struct.best_electrode;
        
        ROCCurves   = spikevalMakeROCCurves(a, b, c, d, options);
        %{
        ROC_fig     = figure
        plot(ROCCurves.all_spikes.FP, ROCCurves.all_spikes.TP, 'k')
        hold on
        plot(ROCCurves.no_burst_spikes.FP, ROCCurves.no_burst_spikes.TP, 'k', 'LineStyle', ':')
        
        title_cell      = cell(2);
        title_cell{1}   = ['num ground truth spikes ' num2str(length(c))];
        title_cell{2}   = ['num non-burst ground truth spikes ' num2str(length(d))];
        
        title(title_cell);
        
        spikevalSaveFigures(filename, {ROC_fig}, {'Fig3E'}, options);
        %}
        %%
    case 2 % generate on patch voltage estimator based on 64 best electrodes, compare bursting and not bursting
        
        
        
        'Running a linear regression on the patch voltage estimators'
        regression_result = spikevalRunLinearRegression(estimator_struct, ordered_electrodes);
        
            if options.use_derivative
                ROCCurves       = spikevalMakeROCCurves(diff(regression_result), b, c, d, options);
            else
                ROCCurves       = spikevalMakeROCCurves(regression_result, b, c, d, options);
            end

        %%
    case 3 % density experiment: generate patch voltage estimator with all electrodes or every other electrode
        
        options.analyze_bursts = 0;
        
        for ii=1:7
            'Running a linear regression on the patch voltage estimators'
            electrodes_to_use = ordered_electrodes(1:(2^(ii-1)):end);
            regression_result = spikevalRunLinearRegression(estimator_struct, electrodes_to_use);
            if options.use_derivative
                ROCCurves       = [ROCCurves ; spikevalMakeROCCurves(diff(regression_result), b, c, d, options)];
            else
                ROCCurves       = [ROCCurves ; spikevalMakeROCCurves(regression_result, b, c, d, options)];
            end
        end

    case 4 % add channels experiment
        % create a ROC curve from the patch estimate derived from the best
        % electrode
        a = estimator_struct.patch_voltage_estimators_from_single_electrodes_mat(:,1);
        options.analyze_bursts = 0;
        if options.use_derivative
            ROCCurves       = spikevalMakeROCCurves(diff(a), b, c, d, options);
        else
            ROCCurves       = spikevalMakeROCCurves(a, b, c, d, options);
        end
        
        % create a ROC curve from the patch estimate derived from the best
        % n electrodes, where n={1,2,4,8,16,32}
        for ii=1:5
            'Running a linear regression on the patch voltage estimators'
            regression_result = spikevalRunLinearRegression(estimator_struct, 1:(2^ii));
            if options.use_derivative
                ROCCurves       = [ROCCurves ; spikevalMakeROCCurves(diff(regression_result), b, c, d, options)];
            else
                ROCCurves       = [ROCCurves ; spikevalMakeROCCurves(regression_result, b, c, d, options)];
            end
        end
        
        % create a ROC curve from the patch estimate derived from the best
        % 64 electrodes, except for the one recording where there were
        % only 58 good electrodes
        
        'Running a linear regression on the patch voltage estimators'
        ii=6;
        if strcmp(filename, options.recording_with_only_58_electrodes) || strcmp(filename, options.recording2_with_only_58_electrodes)
            regression_result = spikevalRunLinearRegression(estimator_struct, 1:58);
        else
            regression_result = spikevalRunLinearRegression(estimator_struct, 1:(2^ii));
        end
        if options.use_derivative
            ROCCurves       = [ROCCurves ; spikevalMakeROCCurves(diff(regression_result), b, c, d, options)];
        else
            ROCCurves       = [ROCCurves ; spikevalMakeROCCurves(regression_result, b, c, d, options)];
        end
        
        
    otherwise
        
end