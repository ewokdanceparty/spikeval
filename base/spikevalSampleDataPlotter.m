%close all
%clc

%{

This is an example script for loading the ground truth data from 
BD Allen, et al., 2018. A plot will be generated with the mean patch-
spike triggered waveform on each pad of the multi-electrode array. 
Depending on the dataset size and available RAM on your computer, you may 
or may not want to load the entire dataset (typically 8 minutes of data) 
into memory (see line 75 vs line 78). 

Data are stored in the HDF5 (aka h5) format. There is one main, lightweight
h5 file, test.h5, which should be placed in whatever home direcory you 
would like (specify home_dir in line 47):
 
home_dir/test.h5

That file is linked to the raw
and spike-filtered data, which should be placed in a directory named
'Recordings' in the home directory (home_dir/Recordings):

home_dir/Recordings/test_raw.h5
home_dir/Recordings/test_filtered.h5

There is also an h5 file which contains the timing of each patch spike, 
as well as the spike number within a burst (where a 20ms criterion was 
used to determine whether a spike was within a burst). This should be 
placed in a directory named 'Analyses'.

home_dir/Analyses/test_spikes.h5

Use h5disp('test.h5') to view the structure of the top-level file, and 
    h5dispfull('test.h5') to view the structure of all of the linked h5 
    files. Because the files are linked, data and attributes within them 
    can be accessed from test.h5 as if they were contained directly in 
    test.h5.

This script was written by Brian D. Allen in Ed Boyden's lab at MIT, who
also collected the data.

Updated 4/13/2017: patch data is now expected to be 1D. The test data set
had it as 2D with a singleton dimension, but all other datasets have it as
1D.

%}

%% DATA FILE

% change this to your home directory
home_dir = 'D:\Dropbox\PatchAndMEA_BoydenLab\fig2_neuron1\';
cd(home_dir)
filename                        = 'fig2_neuron1.h5';
%% CONSTANTS
options.data_length             = 60;
% options.data_length             = Inf;
% length of data to pull in, in seconds. Set to Inf if you wish to pull
% in all the data at once (typically ~8 minutes worth)

options.isi_criterion           = .02; % 20ms, from Staba, Richard J., et al. "Single neuron..
%burst firing in the human hippocampus during sleep." Hippocampus 12.6 (2002): 724-734.
options.spike_wfm_len           = .002; %plot 2ms on each side of spike peak
options.save_figs               = false;
if options.save_figs
    options.save_dir            = [home_dir '/WaveformAnalysis/test'];
end
%% DATA INPUT

data.att.patch_sample_rate      = h5readatt(filename, '/', 'abfsamplerate');
data.att.mea_sample_rate        = h5readatt(filename, '/', 'MEAsamplerate');
data.att.probe_layout           = h5readatt(filename, '/','probelayout');
data.att.bad_channels           = h5readatt(filename, '/','badchannels');
data.att.n_chans                = data.att.probe_layout(1) * data.att.probe_layout(2);
data.att.max_chan               = h5readatt(filename, '/spikes/','max_channel');
data.spikes.burst_index         = h5read(filename, '/spikes/burstindex');

% The following loads all of the multielectrode data into memory.
% Depending on how much RAM you have, you may want to read in smaller 
% chunks at a time. The following call reads in the first 30s of data,
% for example.
if isinf(options.data_length)
    data.mea                    = h5read(filename, '/filtered/filteredMEA', [1 1], [Inf  Inf]);
    % Load patch clamp data into data.patch
    data.patch                      = h5read(filename, '/raw/rawPipette');
    
else
    data.mea                    = h5read(filename, '/filtered/filteredMEA', [1 1], [round(options.data_length * data.att.mea_sample_rate)  Inf]);
    % Load patch clamp data into data.patch
    data.patch                  = h5read(filename, '/raw/rawPipette', 1, round(options.data_length * data.att.mea_sample_rate));
end


% Load data from the multi-electrode array into data.mea
%data.mea                        = h5read(filename, '/filtered/filteredMEA');

% spike times were derived from the derivative of the patch spikes
data.spikes.spike_times         = h5read(filename,'/spikes/derivspiketimes');
spikes_to_include               = length(find(data.spikes.spike_times <= options.data_length));
data.spikes.spike_times         = data.spikes.spike_times(1:spikes_to_include, 1);


%% Test plotting the data
%{
figure
plot(data.mea(:,data.att.max_chan))

figure
plot(data.patch)
%}

%%

data.spikes.n                   = length(data.spikes.spike_times(:,1))
data.spikes.isi                 = diff(data.spikes.spike_times(:,1));
data.spikes.burst_index         = data.spikes.burst_index(1:data.spikes.n);
%% BURST INDEX LOGIC
% This is now read directly in from the h5 file, making the calculations
% below no longer necessary. The code is retained here for illustrative
% purposes.

% label each spike as not being in a burst (data.spike.burst_index = -1),
% or being the 1st, 2nd, etc., spike within a burst (data.spike.burst_index
% = 1, 2, etc.

%{
data.spikes.burst_index         = zeros(data.spikes.n,1);

% deal with the edge condition for the 1st spike in a recording
if data.spikes.spike_times(1) > options.isi_criterion
    if data.spikes.isi(1) > options.isi_criterion
        data.spikes.burst_index(1,1)    = -1;
    else
        data.spikes.burst_index(1,1)    =  1;
    end    
else
    data.spikes.burst_index(1,1)    = 1; % the very first spike is labeled 
    % as being the first spike in a burst, if it occurs so early in the     
    % recording that it's unknown whether it's part of a burst.
end

for i=2:(data.spikes.n-1)
    
    if data.spikes.isi(i-1) <= options.isi_criterion
        data.spikes.burst_index(i,1) = 1 + data.spikes.burst_index(i-1,1);
    else
        if data.spikes.isi(i) <= options.isi_criterion
            data.spikes.burst_index(i,1) = 1;
        else
            data.spikes.burst_index(i,1) = -1;
        end
    end
end

i = data.spikes.n;
if data.spikes.isi(i-1) <= options.isi_criterion
    data.spikes.burst_index(i,1) = 1 + data.spikes.burst_index(i-1,1);
else
    data.spikes.burst_index(i,1) = 1;
end
%}
%% Get the indices of non-burst spikes

non_burst_spike_idx             = find(data.spikes.burst_index(2:end) == -1) + 1;
wfm_half_width                  = round(options.spike_wfm_len * data.att.mea_sample_rate);

%% Determine mean patch-triggered spike waveform for each MEA channel

non_burst_spike_idx_len = length(non_burst_spike_idx);
sum_plot = zeros(wfm_half_width * 2, data.att.n_chans);

n_spikes_to_average = 0; 
% If a spike's waveform overlaps with the beginning or end of the
% recording, don't use it
for i=1:non_burst_spike_idx_len
    %i = 6;
    t                           = data.spikes.spike_times(non_burst_spike_idx(i));
    sample                      = round(t * data.att.mea_sample_rate);
    sample_start                = sample - wfm_half_width + 1;
    sample_end                  = sample + wfm_half_width;
    
    if sample_start > 0
        if sample_end <= length(data.mea(:,1))
            to_plot = data.mea(sample_start:sample_end,:);
            sum_plot = sum_plot + to_plot;
            n_spikes_to_average = n_spikes_to_average + 1;
        end
    end
    

end

mean_plot = sum_plot ./ n_spikes_to_average;

%% Now find channel with min trough and min value, and plot waveforms.
% Optionally, you can save the plot

min_chan = 0;
min_mean = 0;

for i=1:data.att.n_chans
    if sum(data.att.bad_channels == i) == 0
        
        min_current_plot =  min(mean_plot(:,i));
        if min_current_plot < min_mean
            min_mean = min_current_plot;
            min_chan = i;
            
        end
    end
end
%
n_row = data.att.probe_layout(1);
n_col = data.att.probe_layout(2);
coord = zeros(data.att.n_chans,2);

if min_chan == 0
   'NO SPIKES IN THIS TIME RANGE. TRY EXPANDING RANGE' 
end

for i_row = 1:n_row
    coord((i_row-1)*n_col+1:i_row*n_col,1) = 1:n_col;
    coord((i_row-1)*n_col+1:i_row*n_col,2) = i_row;
end
%
options.y_scale = double(round(-1 * min_mean));
h = figure
for i=1:data.att.n_chans
    if sum(data.att.bad_channels == i) == 0
        x_offset = (coord(i,1)-1)*1.2*2*wfm_half_width;
        y_offset = (coord(i,2)-1)*options.y_scale;
        
        x_plot   = (1:(wfm_half_width*2))' + x_offset;
        y_plot   = mean_plot(:,i) + y_offset;
        
        plot(x_plot, y_plot, 'k')
        hold on
    end
end

x_offset = (coord(min_chan,1)-1)*1.2*2*wfm_half_width;
y_offset = (coord(min_chan,2)-1)*options.y_scale;
plot(x_offset, y_offset, '*r')

axis tight
ax = axis;

pts_in_1ms = wfm_half_width / (options.spike_wfm_len * 1000);

plot([(ax(2)-pts_in_1ms) ax(2) ax(2)]+1,[(ax(3)+-1*options.y_scale) (ax(3)+-1*options.y_scale) ax(3)] + options.y_scale/2,'k')
t_label_start_x = (ax(2)-pts_in_1ms);%round(ax(2) - pts_in_1ms / 2);
t_label_start_y = ax(3) - options.y_scale*2;
text(t_label_start_x, t_label_start_y, '1ms')

v_label_start_x = ax(2) + wfm_half_width/3;
v_label_start_y = ax(3) - options.y_scale/2;
text(v_label_start_x, v_label_start_y, [num2str(round(options.y_scale)) '\muV'], 'Rotation', 90)

title([{'Non-burst spikes'}; {'Mean minimum trough from'} ; {[num2str(n_spikes_to_average) ' patch-triggered spikes:']} ; {[num2str(round(min_mean)) '\muV']}]);

axis off

if options.save_figs
    temp = strsplit(filename, '/');
    file = temp{end};
    file_dir = [options.save_dir '/' 'test'];
    if ~isdir(file_dir)
            mkdir(file_dir);
    end
    saveas(h, [file_dir '/' file(1:end-3)], 'pdf');
end



