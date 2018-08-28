function [] = spikevalLocalizePipette(options)


filename_cell       = spikevalLoadFilenames(options);

%options.results_dir = [options.working_dir '/figures/' options.todays_fig_dir '/pipette_tracking']; 

fit_function = @spikevalFitVoltagePulse;
pulse_threshold = 500; % Threshold for finding pulse starts in derivative of intracellular signal, not a sensitive parameter
pulse_sample_length = 1; %Amount of time to grab for fourier transform of pulses.

approx_theta = 63;
approx_delta = 2;
approx_phi = 0; %NOTE - this cannot be set to zero if using fminsearch, or search algorithm will think it doesn't matter!

filename = filename_cell{1};

%%
fprintf(1,'Loading data from %s\n',filename)
tic
mea = h5read(filename,'/precell/precellMEA');
pipette = h5read(filename,'/precell/precellPipette');
toc
mea = mea-repmat(mean(mea,1),size(mea,1),1); % simple mean subtraction
%%
try
    mea_sample_rate = h5readatt(filename,'/precell','MEAsamplerate');
catch
    mea_sample_rate = h5readatt(filename,'/','MEAsamplerate');
    h5writeatt(filename,'/precell','MEAsamplerate',mea_sample_rate);
end
try
    pipette_sample_rate = h5readatt(filename,'/precell','abfsamplerate');
catch
    pipette_sample_rate = h5readatt(filename,'/','abfsamplerate');
    h5writeatt(filename,'/precell','abfsamplerate',pipette_sample_rate);
end
try
    pulse_window =   h5readatt(filename,'/precell','pulsetimes');
catch
    pulse_window = [];
end
try
    pulse_rate = h5readatt(filename,'/precell','pulserate');
catch
    pulse_rate = 20;
    h5writeatt(filename,'/precell','pulserate',20);
end

probe_layout =   h5readatt(filename,'/','probelayout');
pad_pitch =      h5readatt(filename,'/','padpitch');
bad_channels =   h5readatt(filename,'/','badchannels');

%% Find Beacon Pulses in Intracellular Data
% We use the patch electrode signal to find the timing of the voltage pulses.
% It has a few stereotyped stages:
% 1 - Testing outside the brain, bursts of 15.5 pulses at 20Hz
% 2 - Slow deflection when probe is inserted in brain
% 3 - 15.5 pulses at 20Hz once, to makes sure probe isn't broken/clogged
% 4 - Pause while electrode lowers to depth
% 5 - 25.5 pulses at 20Hz, repeated every ~2.1 seconds (pauses variable, due
% to software control)

if isempty(pulse_window) || options.override_pulse_times
    fig_id = figure;
    plot((1:length(pipette)) / pipette_sample_rate, pipette);
    ylabel('Intracellular Current (pA)')
    ylabel('Extracellular Voltage (\muV)')
    % It's much easier to distinguish these stages by visual inspection than by
    % algorithm, so for now we ask the user when the probing starts and stops.
    pulse_window(1) = input('When do the test pulses start?\n');
    pulse_window(2) = input('When do the test pulses stop?\n');
    h5writeatt(filename,'/precell','pulsetimes',pulse_window);
    close(fig_id)
end

temp_start = round(pulse_window(1)*pipette_sample_rate);
temp_stop = round(pulse_window(2)*pipette_sample_rate);
%Square wave is sharp enough that we can detect it with simple
%differentiation
intra_dif = pipette(3:end)-pipette(1:end-2);

pulse_times = find(intra_dif > pulse_threshold);
temp_ind = temp_start;
ii = 0;
pulse_on_time=[];

% Pulse volleys are always less than 1.5s, so the following detects the
% first pulse in a volley, and the last pulse in a 1.5s window.

% The following appears to search across pulsetimes
while temp_ind < temp_stop
    % takes the first remaining pulse from pulsetimes as tempfound
    temp_found = find(pulse_times > temp_ind,1);
    if ~isempty(temp_found)
        ii = ii+1;
        pulse_on_time(ii) = pulse_times(temp_found)/pipette_sample_rate;
        % finds the last pulse within 1.5s
        %measurement will always be over 1.5 seconds later
        temp_ind = round((pulse_on_time(ii) + 1.5)*pipette_sample_rate);
        temp_found = find(pulse_times < temp_ind,1,'last');
        pulse_off_time(ii) = pulse_times(temp_found)/pipette_sample_rate;
    else
        temp_ind = temp_stop;
    end
end

%% Measure Power Pulses picked up on probe
% We measure the amplitude of the pulses detected on the extracellular
% electrode with FFT. Because the test signal is stationary and precise,
% and most of the energy is in the first harmonic, it's better to use the
% power in a single FFT bin, than more complex filters.

%Set constants and initialize arrays for results
%Create vectors for [x,y] coordinates of pads - fitX, fitY
num_channels = size(mea,2);
num_cols = probe_layout(2);
num_rows = probe_layout(1);
pitch_x = pad_pitch(1);
pitch_y = pad_pitch(2);
fit_x = pitch_x*(mod(0:num_channels-1,num_cols)-(num_cols-1)/2); %Center at x=0
fit_y = pitch_y*ceil((1:num_channels)/num_cols);

%Don't use the last pulse
num_pulses = length(pulse_on_time);
pos = zeros(num_pulses,3);
pos_conf = zeros(size(pos));
%KCs = zeros(length(pulseontime),2);
gofs = zeros(length(pulse_on_time),1); % goodness of fits
fit_result = cell(num_pulses,1);
%samplelength = round(pulsesamplelength*MEAsamplerate);
power_bin = pulse_rate*pulse_sample_length + 1;
offset = .15;
pulse_power = zeros(num_pulses, size(mea,2));

%Find power of each pulse on each extracellular pad in appropriate FFT time
%bin
for ii=1:num_pulses
    temp_intra_trace = pipette(round(pipette_sample_rate*(pulse_on_time(ii)+offset)):round(pipette_sample_rate*(pulse_on_time(ii)+offset+pulse_sample_length)-1));
    temp_intra_fft = fft(temp_intra_trace);
    intra_pulse_power(ii) = abs(temp_intra_fft(power_bin));
    for j=1:size(mea,2)
        temp_trace = mea(round(mea_sample_rate*(pulse_on_time(ii)+offset)):...
            round(mea_sample_rate*(pulse_on_time(ii)+offset+pulse_sample_length))-1,j);
        temp_fft = fft(temp_trace);
        pulse_power(ii,j) = abs(temp_fft(power_bin))*2/(pulse_sample_length*mea_sample_rate);
    end
end

%% Restrict rest of analysis to working electrodes
if isempty(bad_channels)
    temp_bad_channels = input('Really no bad channels? Fit will not work well with bad channels\nEnter a vector of bad channels, or an empty set to continue with no change\n');
    if ~isempty(temp_bad_channels)
        bad_channels = temp_bad_channels;
        h5writeatt(filename,'/','badchannels',bad_channels);
    end
end

good_channels = 1:size(mea,2);
if ~isempty(bad_channels) && (max(bad_channels) > size(mea,2) || min(bad_channels) < 1)
    error('badchannels data is not valid');
else
    good_channels(bad_channels) = [];
end
fit_x = fit_x(good_channels);
fit_y = fit_y(good_channels);

%% Plot fourier transform amplitude across all channels for last step

%Plot power in pulserate across all channels for each step
fig_pulse_power = figure;
imagesc(pulse_power)
xlabel('Channel number')
ylabel('Step number')
[~,fig_filename] = fileparts(filename);
title(sprintf('%s Pulse Amplitude Across All Channels and Steps',fig_filename),'Interpreter','none');
colorbar('EastOutside')

spikevalSaveFigures(filename, {fig_pulse_power}, {'_pipette_tracking_exemplar_power'}, options);

%savefig([options.results_dir 'fig_pulsepower']);
%saveas(fig_pulsepower,[options.results_dir 'fig_pulsepower.pdf']);


%% Fit each of the measurements, plot probe advancement
fprintf(1,'Starting fit for position of all pipette steps\n');
tic

% fit_x and fit_y are distances along the probe of the electrodes
% these are fed, along with the pulse power per electrode, to the fitting
% function, for nonlinear, least-squares fitting to a 1/r^2 function
parfor i=1:num_pulses
    temp_fit_power = pulse_power(i,good_channels);
    [temp_pos, temp_con, temp_result, temp_gof, temp_conf_int] = fit_function(fit_x, fit_y, temp_fit_power, false);
    fit_result{i} = temp_result;
    pos(i,:) = temp_pos;
    %KCs(i,:) = temp_con;
    gofs(i) = temp_gof.rsquare;
    pos_conf(i,:) = temp_conf_int;
end
% end
fig_final_fit = figure;
h = plot( fit_result{num_pulses}, [fit_x', fit_y'], pulse_power(num_pulses,good_channels)' );
legend( h, 'Inverse Distance', 'fitPower vs. fitX, fitY', 'Location', 'NorthEast' );

spikevalSaveFigures(filename, {fig_final_fit}, {'_pipette_tracking_exemplar_fit3D'}, options);
%keyboard
%{
savefig([options.results_dir 'fit3D']);
saveas(fig_finalfit,[options.results_dir 'fit3D.pdf']);
%}

%% Now that we have the fits, we can infer position
%Create anonymouse functions for fitting probetrack to pipette positions
track_pos = @(pos0,delta,theta,phi,n) repmat(pos0,n,1) - delta*[0:n-1]'*[sind(phi)*cosd(theta),cosd(phi)*cosd(theta),sind(theta)];
track_error = @(pos0,delta,theta,phi) sum(sum((pos-track_pos(pos0,delta,theta,phi,size(pos,1))).^2));
track_resid = @(pos0,delta,theta,phi) sqrt(sum((pos-track_pos(pos0,delta,theta,phi,size(pos,1))).^2,2));

%guesstrack = trackpos(pos(1,:),approxdelta,approxtheta,approxphi,size(pos,1));
%guesstrackerror = trackerror(pos(1,:),approxdelta,approxtheta,approxphi);
%% Model pipette track with least-squares estimate
% Variables are - (x0,y0,z0) - Pipette starting position
%               - delta - step size of pipette (can be input as known
%               knowledge when electrode pitch is known exactly)
%               - theta - the angle is approximate, not good enough for
%               fits
%
% For each step, t=1:length(meastimes), the position of the pipette is:
% (x0,y0,z0) - (0, cosd(theta), sind(theta))*t*delta

%Which optimization function to use?
%http://www.mathworks.com/help/optim/ug/choosing-a-solver.html#brhkghv-19

track_pos_wrapper = @(x,n) track_pos(x(1:3),x(4),x(5),x(6),n);
track_error_wrapper = @(x) track_error(x(1:3),x(4),x(5),x(6));
track_resid_wrapper = @(x) track_resid(x(1:3),x(4),x(5),x(6));

[track_vals,fval,exit_flag,output] = fminunc(track_error_wrapper,[pos(1,:),approx_delta,approx_theta,approx_phi],...
    optimoptions('fminunc','Display','off','Algorithm','quasi-newton'));

track_dev = sqrt(fval/size(pos,1))*2/track_vals(4); %Standard dev of trackvals in microns
track_fit = track_pos_wrapper(track_vals, size(pos,1));

answered = 1;

if 1%options.PlotTrack
    fig_summary = figure('Units','inches','OuterPosition',[5 0 8 8]);
    getappdata(gcf, 'SubplotDefaultAxesLocation')
    setappdata(gcf, 'SubplotDefaultAxesLocation', [0.07 0.07 0.9 0.9])

    gold = [255,215,0]/255;

    %%% Top Down
    subplot(3,3,1)
    axis equal
    if ~answered
        plot(pos(:,1),pos(:,2),'*-r')
    else
        errorbar(pos(:,1),pos(:,2),pos_conf(:,2),'*-r')
    end
    hold on
    plot(track_fit(:,1),track_fit(:,2),'-g')
    daspect([1 1 1 ]);
    %Visualize probe pads
    pad_width = [10, 10];
    for i=1:length(good_channels)
        pad_pos = [fit_x(i),fit_y(i)]-pad_width/2;
        rectangle('Position',[pad_pos,pad_width],'FaceColor',gold)
    end
    title('Top Down View')
    %%% Side View
    subplot(3,3,2)
    axis equal
    if ~answered
        plot(pos(:,2),pos(:,3),'*-r')
    else
        errorbar(pos(:,2),pos(:,3),pos_conf(:,2),'*-r')
    end
    hold on
    plot(track_fit(:,2),track_fit(:,3),'-g')
    daspect([1 1 1 ]);
    %Visualize probe pads
    pad_width = [10,1];
    all_y = unique(fit_y);
    for i=1:length(all_y)
        %padpos = [i,0]-padwidth/2;
        pad_pos = [all_y(i) 0] - pad_width/2;
        rectangle('Position',[pad_pos,pad_width],'FaceColor',gold)
    end
    xlim([min(track_fit(:,2))-10,max(track_fit(:,2))+10])
    title('Side View Rows')
    
    %%% Edge View          
    subplot(3,3,3)
    axis equal
    if ~answered
        plot(pos(:,1),pos(:,3),'*-r')
    else
        errorbar(pos(:,1),pos(:,3),pos_conf(:,1),'*-r')
    end
    hold on
    plot(track_fit(:,1),track_fit(:,3),'-g')
    daspect([1 1 1 ]);
    title('Side View')
    %Visualize probe pads
    pad_width = [10,1];
    all_x = unique(fit_x);
    for i=1:length(all_x)
        %padpos = [i,0]-padwidth/2;
        pad_pos = [all_x(i) 0] - pad_width/2;
        rectangle('Position',[pad_pos,pad_width],'FaceColor',gold)
    end
    xlim([min(pos(:,1))-10, max(pos(:,1))+10]);
    title('Side View Columns')
    
    subplot(3,3,4:6)
    residuals = track_resid_wrapper(track_vals)*2/track_vals(4);
    scatter(1:length(residuals),residuals)
    ylabel('Residual error (microns)')
    xlabel('Step Number')
    title(fig_filename,'Interpreter','none')
    
    subplot(3,3,7:9)
    plot(gofs,'o')
    xlabel('Step Number')
    ylabel('R-square value')
    title('Goodness of fits on each step')
    
    spikevalSaveFigures(filename, {fig_summary}, {'_pipette_tracking_exemplar_summary'}, options);
    
    %savefig([options.results_dir 'fig_summary']);
    %saveas(fig_summary,[options.results_dir 'fig_summary.pdf']);
end
%{
if answered && options.interactive
    finished = true;
    keyboard;
end

if ~options.interactive
    finished = true;
    if options.SaveResults
        saveresults();
    end
    if options.SaveFigure
        savefigure();
    end
else
    while ~answered
        plotauxfigures
       
        doneyet = 'y';%input('Does this look good? y/n\n','s');
        if strcmpi(doneyet,'n') || strcmpi(doneyet,'no')
            answered = true;
            finished = false;
            debug = true;
            plotauxfigures();
        elseif strcmpi(doneyet,'y') || strcmpi(doneyet,'yes')
            answered = true;
            finished = true;
            if options.SaveResults
%                saveresults();
            end
            if options.SaveFigure
%                savefigure();
            end
        end
       
    end
end
%}
answered = true;

% %% Plot 3D version of track
%     gg = figure
%     plot3(pos(:,1),pos(:,2),pos(:,3),'*-r')
%     hold on
%     plot3(track_fit(:,1),track_fit(:,2),track_fit(:,3),'-g')
%     title('3D Plot of Track')
%     axis equal
%     %savefig([options.results_dir 'threeD_path']);
%     %saveas(gg,[options.results_dir 'threeD_path.pdf']);
%     
%     
% 
% end
% 
% out = [pos residuals gofs]';
%csvwrite(options.results_file, out);

%%
%{
figure
plot3(pos(:,1), pos(:,2), pos(:,3))

x = pos(:,1);
y = pos(:,2);
z = pos(:,3);
axis equal
%save('pos', 'pos')
%}