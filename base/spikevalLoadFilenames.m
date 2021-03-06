function out = spikevalLoadFilenames(options)

switch options.dataset
    case 'pipette_track_exemplar'
        filename_cell       = cell(1,1);
        filename_cell{1}    = '/fig2_neuron6';%'/1103_1/1103';%/151103/BAHP23_day1_seventh_whole';
    case 'pipette_track_all'
        filename_cell       = cell(16,1);
        filename_cell{1}    = '/fig2_neuron3_fig1_pipette1';
        filename_cell{2}    = '/fig1_pipette2';
        filename_cell{3}    = '/fig1_pipette3';
        filename_cell{4}    = '/fig1_pipette4';
        filename_cell{5}    = '/fig1_pipette5';
        filename_cell{6}    = '/fig1_pipette6';
        filename_cell{7}    = '/fig1_pipette7';
        filename_cell{8}    = '/fig1_pipette8';
        filename_cell{9}    = '/fig1_pipette9';
        filename_cell{10}    = '/fig1_pipette10';
        filename_cell{11}    = '/fig2_neuron11_fig1_pipette11';
        filename_cell{12}    = '/fig1_pipette12';
        filename_cell{13}    = '/fig1_pipette13';
        filename_cell{14}    = '/fig2_neuron7_fig1_pipette14';
        filename_cell{15}    = '/fig1_pipette15';
        filename_cell{16}    = '/fig1_pipette16';
    case 'paper_recordings'
        filename_cell       = cell(12,1);
        filename_cell{1}    = '/fig2_neuron1';
        filename_cell{2}    = '/fig2_neuron2';
        filename_cell{3}    = '/fig2_neuron3_fig_pipette1';
        filename_cell{4}    = '/fig2_neuron4';
        filename_cell{5}    = '/fig2_neuron5';
        filename_cell{6}    = '/fig2_neuron6';
        filename_cell{7}    = '/fig2_neuron7_fig1_pipette14';
        filename_cell{8}    = '/fig2_neuron8';
        filename_cell{9}    = '/fig2_neuron9';
        filename_cell{10}    = '/fig2_neuron10';
        filename_cell{11}    = '/fig2_neuron11_fig1_pipette11';
        filename_cell{12}    = '/fig2_neuron12';
        
        %{
        filename_cell{1}    = '/150915/BAHP19_day1_eighth_cell_attached';
        filename_cell{2}    = '/150915/BAHP19_day1_tenth_cell_attached';
        filename_cell{3}    = '/150915/BAHP19_day1_seventeenth_cell_attached';
        filename_cell{4}    = '/150915/BAHP19_day1_eighteenth_whole_cell';
        filename_cell{5}    = '/151103/BAHP23_day1_seventh_whole';
        filename_cell{6}    = '/160509/20160509_cellattach_01';
        filename_cell{7}    = '/160419/20160419_whole_cell_07';
        filename_cell{8}    = '/160513/20160513_1_whole_01';
        filename_cell{9}    = '/160513/20160513_2_whole_03';
        filename_cell{10}   = '/160531/20160531_2_WholeCell_02';
        filename_cell{11}   = '/160624/20160624_2_2_Whole_02';
        filename_cell{12}   = '/160624/20160624_5_5_Whole_02';
        %}
    case 'all_recordings'
        
        
    case 'roc_exemplar'
        filename_cell       = cell(1,1);
        filename_cell{1}    = '/fig2_neuron1'; %'/419/419_7';
    case 'auc_exemplar'
        filename_cell       = cell(1,1);
        filename_cell{1}    = '/fig2_neuron4';%'/513/513_2';%'/160513/20160513_2_whole_03';
    otherwise
        'Please enter a valid dataset name'
end

num_recordings = length(filename_cell);
out = cell(num_recordings,1);
for ii=1:length(filename_cell)
    out{ii} = [options.data_dir filename_cell{ii} filename_cell{ii} '.h5'];
end