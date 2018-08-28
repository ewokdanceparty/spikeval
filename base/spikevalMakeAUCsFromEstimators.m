function [] = spikevalMakeAUCsFromEstimators(options)

%{ 
An algorithm for assessing potential spike sorting performance as a 
function of electrode density and quantity. Extracellular signals are 
considered as convolutions of the intracellular voltage, and deconvolution
is used to derive the neuron's true spiking state (intracellular voltage) 
from the electrode voltages.
%}


    filename_cell                               = spikevalLoadFilenames(options);

    %options.total_t                             = 456;
    %options.num_neurons                         = 12;
    options.num_neurons = length(filename_cell);
    options.num_convolution_filter_pts          = 512;
    options.zero_out_when_patch_doesnt_spike    = 1;
    options.isi_criterion                       = 0.02; % 20ms
    
    options.recording_with_only_58_electrodes   = '_';
    if length(filename_cell) > 1
        options.recording_with_only_58_electrodes   = filename_cell{5}; % set this to filename_cell{5} if analyzing the 12 neurons in the paper
    end
    %options.working_dir                         = '/media/user/NeuroData1/Dropbox (MIT)/spikeval';
    %options.todays_fig_dir                      = '180807';

    options.recording2_with_only_58_electrodes  = '_';
    options.debug_mode                          = 0;

    options.reverse_mea = 0;

    cd(options.working_dir)
    % Create directories for the project, if they don't already exist
    spikevalGenerateDirLayout(options);
    
    options.use_derivative_vec = 1;
    if length(filename_cell) > 1
        options.use_derivative_vec  = [0 1 1 1 1 0 1 1 1 1 1 1 ];
    end

    % The following only has to be run once. It may take a long time (~15 minutes)
    % to run

    options.get64BestElectrodes = 1;

    if options.get64BestElectrodes
        spikevalGet64BestElectrodes(filename_cell, options)
    end

    load([options.working_dir '/config/electrode_order.mat']) % this loads electrode_order_cell into memory

    options.parfor      = 1; % you can use a parallel for loop to process the electrodes of a recording if your machine has 128GB of RAM

    %% Create a patch voltage estimator and generate ROC curves

    options.num_neurons     = 1;

    number_of_ROC_analyses  = 4;
    ROC_cell                = cell(options.num_neurons, number_of_ROC_analyses);

    for neuron = 1:options.num_neurons

        ['Processing neuron ' num2str(neuron)]
        options.use_derivative          = options.use_derivative_vec(neuron);
        filename                        = filename_cell{neuron};
        options.electrode_order         = electrode_order_cell{neuron};
       % options.virtual_reference       = virtual_reference_cell{neuron};

        patch_voltage_estimator_struct  = spikevalMakePatchVoltageEstimatorStruct(filename, options);

        options.experiment_type         = 1; % create a ROC curve on the raw electrode voltage
        ROC_cell{neuron, options.experiment_type}             = spikevalSetUpROCAnalysis(filename, patch_voltage_estimator_struct, options);

        options.experiment_type         = 2; % create a ROC curve on an estimator derived from all electrodes
        ROC_cell{neuron, options.experiment_type}             = spikevalSetUpROCAnalysis(filename, patch_voltage_estimator_struct, options);

        options.experiment_type         = 3; % create a ROC curve on an estimator derived from various numbers of electrodes: 64, 32, 16, 8, 4, 2, 1
        ROC_cell{neuron, options.experiment_type}             = spikevalSetUpROCAnalysis(filename, patch_voltage_estimator_struct, options);

        options.experiment_type         = 4; % create a ROC curve on an estimator derived from various numbers of electrodes: 1, 2, 4, 8, 16, 32, 64
        ROC_cell{neuron, options.experiment_type}             = spikevalSetUpROCAnalysis(filename, patch_voltage_estimator_struct, options);

    end

    %% Calculate area under ROC curves and get p-values
    AUC_cell = cell(number_of_ROC_analyses,1);
    for ii=1:number_of_ROC_analyses
        options.experiment_type         = ii;
        AUC_cell{ii} = spikevalCalculatePValuesForAUCs(ROC_cell, options);

        current_AUC = AUC_cell{ii}.areas;
        marker_vec = ['+*.xsd^v><ph'];
        area_fig = figure
        for jj=1:length(current_AUC(1,:))
            
            plot(current_AUC(:,jj), 'Color', [.5 .5 .5])
            hold on        
        end
        plot(mean(current_AUC, 2), 'k', 'Marker', '.')
        switch ii
                
            case 1
                title('AUC on closest electrode: excluding or not excluding bursts')
            case 2
                title('AUC from estimator based on all electrodes: excluding or not excluding bursts')
            case 3
                title('AUC from estimator at increasing density')
            case 4
                title('AUC from estimator at decreasing density')
            otherwise
                
        end
%        title(['Experiment type = ' num2str(ii)])
        ylim(0:1)
        savefig(area_fig, [options.working_dir '/figures/' options.todays_fig_dir '/AUC exp ' num2str(ii)])

    end
    save([options.working_dir '/results/' options.todays_fig_dir '/AUC'], 'AUC_cell')