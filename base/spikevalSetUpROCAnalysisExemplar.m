function ROCCurves = spikevalSetUpROCAnalysisExemplar(options)


filename_cell       = spikevalLoadFilenames(options);
filename = filename_cell{1};

options.analyze_bursts  = 1;
options.isi_criterion   = 0.02;
options.total_t         = 60;

experiment.filename             = filename;
experiment.mea_sample_rate      = h5readatt(experiment.filename, '/', 'MEAsamplerate');
%experiment.patch_sample_rate    = h5readatt(experiment.filename, '/', 'abfsamplerate'); 
experiment.total_samples        = round(experiment.mea_sample_rate * options.total_t);
%experiment.total_patch_samples  = round(experiment.patch_sample_rate * options.total_t);
sample_start                    = 1;

experiment.spike_times      = h5read(experiment.filename, '/spikes/derivspiketimes');
experiment.spike_times      = experiment.spike_times(experiment.spike_times < options.total_t);

try
    experiment.best_wire_num    = h5readatt(experiment.filename, '/spikes/', 'max_channel');
catch
    experiment.best_wire_num    = h5readatt(experiment.filename, '/spikes/median_1', 'max_channel');
end

experiment.best_electrode = -1.* h5read(filename, '/filtered/filteredMEA', [sample_start experiment.best_wire_num], [experiment.total_samples 1]);

burst_spike_number_for_each_spike   = spikevalGetSpikeNumberInBurstIndex(experiment, options.isi_criterion);
burst_criterion                     = 1;
burst_times                         = experiment.spike_times(find(burst_spike_number_for_each_spike > burst_criterion));
non_burst_times                     = setdiff(experiment.spike_times, burst_times);
experiment.non_burst_times          = sort(non_burst_times);
%experiment.non_burst_times          = experiment.non_burst_times < options.total_t;

a           = experiment.best_electrode;
b           = experiment.mea_sample_rate;
c           = experiment.spike_times;
d           = experiment.non_burst_times;

ROCCurves   = spikevalMakeROCCurves(a, b, c, d, options);

ROC_fig     = figure
plot(ROCCurves.all_spikes.FP, ROCCurves.all_spikes.TP, 'k')
hold on
plot(ROCCurves.no_burst_spikes.FP, ROCCurves.no_burst_spikes.TP, 'k', 'LineStyle', ':')

title_cell      = cell(2);
title_cell{1}   = ['num ground truth spikes ' num2str(length(c))];
title_cell{2}   = ['num non-burst ground truth spikes ' num2str(length(d))];

title(title_cell);
ylim([0 1]);

spikevalSaveFigures(filename, {ROC_fig}, {'Fig3E'}, options);

%%
