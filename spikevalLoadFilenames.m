function out = spikevalLoadFilenames(options)

switch options.dataset
    case 'pipette_track_exemplar'
        filename_cell       = cell(1,1);
        filename_cell{1}    = '/151103/BAHP23_day1_seventh_whole';
    case 'pipette_track_all'
        
    case 'paper_recordings'
        
    case 'all_recordings'
        
    otherwise
        'Please enter a valid dataset name'
end

num_recordings = length(filename_cell);
out = cell(num_recordings,1);
for ii=1:length(filename_cell)
    out{ii} = [options.data_dir filename_cell{ii} '.h5'];
end