%{
Companion code for Automated in vivo patch clamp evaluation of 
extracellular multielectrode array spike recording capability

Paper authors:
Brian D. Allen, Caroline Moore-Kochlacs, Jacob G. Bernstein, 
Justin P. Kinney, Jorg Scholvin, Luís F. Seoane, Chris Chronopoulos, 
Charlie Lamantia, Suhasa B. Kodandaramaiah, 
Max Tegmark*, Edward S. Boyden*

Authors of this code:
Brian D. Allen, Caroline Moore-Kochlacs, Jacob G. Bernstein
%}

%{
Code philosophy: we generally try to make the code as easy to read as 
possible for the average neuroscientist. So we're not going to use 
object oriented programming here.
%}

%{
Pipette localization: the pipette tip sends a beacon signal that
is detected across the electrode array. The amplitude of this signal 
across electrodes, combined with the known geometry of the electrodes, 
allows for an estimate of distance of the pipette tip to the electrode 
array. A 1/r model of voltage dropoff was shown to be appropriate for this.
%}

% Load data
options.data_dir    = '/media/user/NeuroData1/Dropbox (MIT)/Colocalized Recordings';
options.dataset     = 'pipette_track_exemplar';
% options.dataset = 'pipette_track_all';
% options.dataset = 'paper_recordings';
% options.dataset = 'all_recordings';
filename_cell       = spikevalLoadFilenames(options);


%{
An algorithm for assessing potential spike sorting performance as a 
function of electrode density and quantity. Extracellular signals are 
considered as convolutions on the intracellular voltage, and deconvolution
is used to derive the neuron's true spiking state (intracellular voltage) 
from the electrode voltages.
%}