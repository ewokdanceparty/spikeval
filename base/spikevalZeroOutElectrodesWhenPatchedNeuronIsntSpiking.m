function mea_only_patch_spikes = spikevalZeroOutElectrodesWhenPatchedNeuronIsntSpiking(experiment)
%{
All electrode voltages are initially set to zero. If the patched neuron
spikes, the electrode data within a short period of time around that spike
is added back in to the data.
%}

'Zeroing out timepoints when patched neuron did not spike'

mea_only_patch_spikes       = zeros(length(experiment.mea(:,1)), length(experiment.mea(1,:)));

for i=1:length(experiment.spike_times)
    
    t = experiment.spike_times(i);
    t_start = t - .004;
    t_end   = t + .004;
    sample_start = round(t_start*experiment.mea_sample_rate);
    sample_end   = round(t_end*experiment.mea_sample_rate);
    if sample_start > 0
        if sample_end <= length(experiment.mea(:,1))
           mea_only_patch_spikes(sample_start:sample_end, :) = experiment.mea(sample_start:sample_end, :);
        end
        
    end
end