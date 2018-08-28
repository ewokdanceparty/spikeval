function out = spikevalCalculatePValuesForAUCs(ROC_cell, options)

if (options.experiment_type == 1) || (options.experiment_type == 2)
    areas_under_ROC_curves  = zeros(2, options.num_neurons);
    for neuron=1:options.num_neurons
        areas_under_ROC_curves(1, neuron) = ROC_cell{neuron, options.experiment_type}.no_burst_spikes.area;
        areas_under_ROC_curves(2, neuron) = ROC_cell{neuron, options.experiment_type}.all_spikes.area;
    end
    ['Areas under ROC curves for analysis ' num2str(options.experiment_type)]
    out.areas       = areas_under_ROC_curves;
    [h,p,ci,stats]  = ttest(areas_under_ROC_curves(1,:), areas_under_ROC_curves(2,:));
    
elseif options.experiment_type == 3
    num_curves = 7;
    areas_under_ROC_curves  = zeros(num_curves, options.num_neurons);
    for neuron=1:options.num_neurons
        for density=1:num_curves
            areas_under_ROC_curves(density, neuron) = ROC_cell{neuron, options.experiment_type}(density).all_spikes.area;
            %areas_under_ROC_curves(2, neuron) = ROC_cell{neuron, options.experiment_type}(2).all_spikes.area;
        end
    end
    ['Areas under ROC curves for analysis ' num2str(options.experiment_type)]
    out.areas       = areas_under_ROC_curves;
    [h,p,ci,stats]  = ttest(areas_under_ROC_curves(1,:), areas_under_ROC_curves(2,:));
    
elseif options.experiment_type == 4
    areas_under_ROC_curves  = zeros(7, options.num_neurons);
    for neuron=1:options.num_neurons
        for recording_volume=1:7
            areas_under_ROC_curves(recording_volume, neuron) = ROC_cell{neuron, options.experiment_type}(recording_volume).all_spikes.area;
            %areas_under_ROC_curves(2, neuron) = ROC_cell{neuron, options.experiment_type}(2).all_spikes.area;
        end
    end
    ['Areas under ROC curves for analysis ' num2str(options.experiment_type)]
    out.areas       = areas_under_ROC_curves;
    [h,p,ci,stats]  = ttest(areas_under_ROC_curves(3,:), areas_under_ROC_curves(7,:));
    
else
    
end

areas_under_ROC_curves
out.p_value     = p;
p