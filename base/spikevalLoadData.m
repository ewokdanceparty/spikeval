function experiment = spikevalLoadData(filename, options)
%{
Pulls the patch clamp data and multielectrode array data (mea). The data is
stored and outputted in the experiment structure. The multielectrode data is virtual referenced.
%}
experiment.filename             = filename;
experiment.mea_sample_rate      = h5readatt(experiment.filename, '/', 'MEAsamplerate');
%experiment.patch_sample_rate    = h5readatt(experiment.filename, '/', 'abfsamplerate'); 
experiment.total_samples        = round(experiment.mea_sample_rate * options.total_t);
%experiment.total_patch_samples  = round(experiment.patch_sample_rate * options.total_t);
sample_start                    = 1;

try
    experiment.patch            = h5read(experiment.filename, '/filtered/filteredPipette', sample_start , experiment.total_samples);
catch
    experiment.patch            = h5read(experiment.filename, '/filtered/filteredPipette', [sample_start 1], [experiment.total_samples 1]);
end
%
%{
Although we calculated and saved the virtual reference earlier, in order to
avoid having to pull in all of the electrodes, we are still pulling in all
of the electrodes. This is because I suspect that h5read might be really
inefficient if we pull only the desired 64 electrodes in in a loop. This
should be examined at some point.
%}

experiment.mea              = h5read(experiment.filename, '/filtered/filteredMEA', [sample_start 1], [experiment.total_samples Inf]);

experiment.spike_times      = h5read(experiment.filename, '/spikes/derivspiketimes');
experiment.spike_times      = experiment.spike_times(experiment.spike_times < options.total_t);
% experiment.spike_times      = experiment.spike_times(experiment.spike_times >= options.start_t);
% experiment.spike_times      = experiment.spike_times - options.start_t;

try
    experiment.best_wire_num    = h5readatt(experiment.filename, '/spikes/', 'max_channel');
catch
    experiment.best_wire_num    = h5readatt(experiment.filename, '/spikes/median_1', 'max_channel');
end
%
experiment.bad_channels     = h5readatt(experiment.filename, '/', 'badchannels');
experiment.good_channels    = setdiff(1:length(experiment.mea(1,:)), experiment.bad_channels);
%experiment.best_wire        = experiment.mea(:, experiment.best_wire_num);

% remove bad channels 
mea_no_bad_channnels_idx 	= setdiff(1:length(experiment.mea(1,:)), experiment.bad_channels);
mea_no_bad_channnels     	= experiment.mea(:, mea_no_bad_channnels_idx);
experiment.mea              = mea_no_bad_channnels;
experiment.num_chans        = length(experiment.mea(1,:));

% do virtual referencing
if ~(isfield(options,'novirtref') && options.novirtref == 1)
    virtual_reference           = spikevalGetVirtualReferenceTransform(experiment.mea');
    experiment.mea              = virtual_reference*experiment.mea';
    experiment.mea              = experiment.mea';
end










