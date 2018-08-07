function convolutive_filter = spikevalMakeConvolutiveFilter(electrode_voltage, fourier_coefficients_of_patch_voltage_transformed_in_bins, options)

num_filter_pts = options.num_convolution_filter_pts;

num_fts = floor(length(electrode_voltage(:,1)) / (num_filter_pts/2)) -1;
blackman_window = blackman(options.num_convolution_filter_pts);

%{
Here we Fourier transform the electrode voltage in bins
%}

fourier_coefficients_of_electrode_voltage_transformed_in_bins = zeros(num_fts, num_filter_pts);
for i=1:num_fts
   idx = (i-1) * (num_filter_pts/2) + 1;
   temp = fft(blackman_window .* electrode_voltage(idx:(idx+(num_filter_pts-1)),1))'./sqrt(num_filter_pts);
   temp_real = real(temp);
   temp_imag = imag(temp)*1;
   temp_in = complex(temp_real, temp_imag);
   fourier_coefficients_of_electrode_voltage_transformed_in_bins(i,:) = temp_in;
end

%{
This is a linear regression of the Fourier coefficients between the
electrode and patch voltages
%}
beta = zeros(num_filter_pts,1);
for i=1:num_filter_pts
    aa = conj(fourier_coefficients_of_electrode_voltage_transformed_in_bins(:,i));
    bb = fourier_coefficients_of_patch_voltage_transformed_in_bins(:,i);
    cc = fourier_coefficients_of_electrode_voltage_transformed_in_bins(:,i);
    
    num   = sum(aa .*bb);
    denom = sum(aa .*cc);
    
    beta(i,1) = num / denom; % linear regression coefficients  
end
% 
convolutive_filter = circshift(flipud(ifft(beta).* sqrt(num_filter_pts)),1);