function ROCCurves = spikevalSetUpROCAnalysis(filename, patch_voltage_estimator_struct, options)


% change patch_voltage_estimator_struct to something short, like
% est_struct?

ROCCurves = [];
options.analyze_bursts = 1;

b           = patch_voltage_estimator_struct.sample_rate;
c           = patch_voltage_estimator_struct.spike_times;
d           = patch_voltage_estimator_struct.non_burst_times;

if strcmp(filename, options.recording_with_only_58_electrodes) || strcmp(filename, options.recording2_with_only_58_electrodes)
    ordered_electrodes = 1:58;
else
    ordered_electrodes = 1:64;
end

switch options.experiment_type
    case 1 % generate on raw voltage of best electrode, compare bursting and not bursting
        
        a           = patch_voltage_estimator_struct.best_electrode;
        
        ROCCurves   = sortaMakeROCCurves(a, b, c, d, options);
        
        ROC_fig     = figure
        plot(ROCCurves.all_spikes.FP, ROCCurves.all_spikes.TP, 'k')
        hold on
        plot(ROCCurves.no_burst_spikes.FP, ROCCurves.no_burst_spikes.TP, 'k', 'LineStyle', ':')
        
        title_cell      = cell(2);
        title_cell{1}   = ['num ground truth spikes ' num2str(length(c))];
        title_cell{2}   = ['num non-burst ground truth spikes ' num2str(length(d))];
        
        title(title_cell);
        
        sortaSaveFigures(filename, {ROC_fig}, {'Fig3E'}, options);
        %%
    case 2 % generate on patch voltage estimator based on 64 best electrodes, compare bursting and not bursting
        
        
        
        'Running a linear regression on the patch voltage estimators'
        regression_result = sortaRunLinearRegression(patch_voltage_estimator_struct, ordered_electrodes);
        
        if options.use_matched_filter
            
            experiment.mea_sample_rate = patch_voltage_estimator_struct.sample_rate;
            experiment.mea = regression_result;
            experiment.spike_times = patch_voltage_estimator_struct.spike_times;

            signal  = sortaZeroOutElectrodesWhenPatchedNeuronIsntSpiking(experiment);
            noise  = sortaZeroOutElectrodesWhenPatchedNeuronIsSpiking(experiment);
            %patch = patch_voltage_estimator_struct.patch;
            
            offset = 1.2;
            
            figure
            plot(sortaNormalizeIt(signal))
            hold on
%             plot(sortaNormalizeIt(signal) + offset)
%             hold on
            
            
            max_signal = max(signal);
            min_signal = min(signal);
            
            norm_noise = noise - min_signal;
            norm_noise = norm_noise ./ max_signal;
            
            plot(norm_noise + offset)
            
            
            %plot(sortaNormalizeIt(regression_result) + 3*offset)
            
%             hold on
%             plot(sortaNormalizeIt(matched_filter) + 2*offset)
            
            
            
            rng default
            Fs = experiment.mea_sample_rate;

            fourier_signal  = fft(signal);
            fourier_noise   = fft(noise);
            
            N               = length(fourier_signal);
            power_noise     = (1/(Fs*N)) * abs(fourier_noise).^2;
            
            fourier_result  = fourier_signal ./ power_noise;
            matched_filter  = ifft(fourier_result);
            
            figure
            plot(matched_filter)
            
            result = conv(regression_result, matched_filter, 'same');
            
            figure
            plot(result)
            %ROCCurves       = sortaMakeROCCurves(result, b, c, d, options);
            
            
%             N = length(a);
%             xdft = fft(a);
%             xdft = xdft(1:N/2+1);
%             psdx = (1/(Fs*N)) * abs(xdft).^2;
%             psdx(2:end-1) = 2*psdx(2:end-1);
%             freq = 0:Fs/length(a):Fs/2;
% 
%             bdft = fft(b);
%             bdft = bdft(1:N/2+1);
%             psdx_b = (1/(Fs*N)) * abs(bdft).^2;
%             psdx_b(2:end-1) = 2*psdx_b(2:end-1);
%             freq_b = 0:Fs/length(a):Fs/2;
%             figure
%             plot(freq,10*log10(psdx))
%             grid on
%             title('Periodogram Using FFT')
%             xlabel('Frequency (Hz)')
%             ylabel('Power/Frequency (dB/Hz)')
            
            
        else
            if options.use_derivative
                ROCCurves       = sortaMakeROCCurves(diff(regression_result), b, c, d, options);
            else
                ROCCurves       = sortaMakeROCCurves(regression_result, b, c, d, options);
            end
        end
        
        'blah'
        
        
        %         ROC_fig         = figure
        %         plot(ROCCurves.all_spikes.FP, ROCCurves.all_spikes.TP)
        %         hold on
        %         plot(ROCCurves.no_burst_spikes.FP, ROCCurves.no_burst_spikes.TP)
        %
        %         title_cell      = cell(2);
        %         title_cell{1}   = ['num ground truth spikes ' num2str(length(c))];
        %         title_cell{2}   = ['num non-burst ground truth spikes ' num2str(length(d))];
        %
        %         title(title_cell);
        %
        %         sortaSaveFigures(filename, {ROC_fig}, {'Fig4C'}, options);
        %%
    case 3 % density experiment: generate patch voltage estimator with all electrodes or every other electrode
        
        options.analyze_bursts = 0;
        
        for ii=1:7
            'Running a linear regression on the patch voltage estimators'
            electrodes_to_use = ordered_electrodes(1:(2^(ii-1)):end);
            regression_result = sortaRunLinearRegression(patch_voltage_estimator_struct, electrodes_to_use);
            if options.use_derivative
                ROCCurves       = [ROCCurves ; sortaMakeROCCurves(diff(regression_result), b, c, d, options)];
            else
                ROCCurves       = [ROCCurves ; sortaMakeROCCurves(regression_result, b, c, d, options)];
            end
        end
        
        %         ROC_fig         = figure
        %         plot(ROCCurves(1).all_spikes.FP, ROCCurves(1).all_spikes.TP)
        %         hold on
        %         plot(ROCCurves(2).all_spikes.FP, ROCCurves(2).all_spikes.TP)
        %
        %         title_cell      = cell(2);
        %         title_cell{1}   = ['num ground truth spikes ' num2str(length(c))];
        %         %title_cell{2}   = ['num non-burst ground truth spikes ' num2str(length(d))];
        %
        %         title(title_cell);
        
        %        sortaSaveFigures(filename, {ROC_fig}, {'Fig4D'}, options);
    case 4 % add channels experiment
        % create a ROC curve from the patch estimate derived from the best
        % electrode
        a = patch_voltage_estimator_struct.patch_voltage_estimators_from_single_electrodes_mat(:,1);
        options.analyze_bursts = 0;
        if options.use_derivative
            ROCCurves       = sortaMakeROCCurves(diff(a), b, c, d, options);
        else
            ROCCurves       = sortaMakeROCCurves(a, b, c, d, options);
        end
        
        % create a ROC curve from the patch estimate derived from the best
        % n electrodes, where n={1,2,4,8,16,32}
        for ii=1:5
            'Running a linear regression on the patch voltage estimators'
            regression_result = sortaRunLinearRegression(patch_voltage_estimator_struct, 1:(2^ii));
            if options.use_derivative
                ROCCurves       = [ROCCurves ; sortaMakeROCCurves(diff(regression_result), b, c, d, options)];
            else
                ROCCurves       = [ROCCurves ; sortaMakeROCCurves(regression_result, b, c, d, options)];
            end
        end
        
        % create a ROC curve from the patch estimate derived from the best
        % 64 electrodes, except for the one recording where there were
        % only 58 good electrodes
        
        'Running a linear regression on the patch voltage estimators'
        ii=6;
        if strcmp(filename, options.recording_with_only_58_electrodes) || strcmp(filename, options.recording2_with_only_58_electrodes)
            regression_result = sortaRunLinearRegression(patch_voltage_estimator_struct, 1:58);
        else
            regression_result = sortaRunLinearRegression(patch_voltage_estimator_struct, 1:(2^ii));
        end
        if options.use_derivative
            ROCCurves       = [ROCCurves ; sortaMakeROCCurves(diff(regression_result), b, c, d, options)];
        else
            ROCCurves       = [ROCCurves ; sortaMakeROCCurves(regression_result, b, c, d, options)];
        end
        
        
    otherwise
        
end