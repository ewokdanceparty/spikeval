function out = spikevalGetFourierTransformedPatchVoltage(patch_voltage, options) 
%{
Does a Fourier transform (apodized with a Blackman window) for each section
of patch clamp data of length equal to the convolution filter. This is done
twofold: if the filter is 512 points long, the transform with be done on
the first 512 points, and the next transform will be done starting at the
length of the filter divided by 2 (+1), in this case 257. Returns a matrix
(out) with rows being the Fourier coefficients for each bin equal to the
filter length, with the number of rows being equal to the total number of
bins.
%}

num_filter_pts = options.num_convolution_filter_pts;

num_fts = floor(length(patch_voltage(:,1)) / (num_filter_pts/2)) -1;
blackman_window = blackman(options.num_convolution_filter_pts);

% if options.debug_mode
%    figure
%    title('Blackman window')
%    hold on
%    plot(blackman_window(512), 'Color', [1 .5 0])
% end


out = zeros(num_fts, num_filter_pts);
for i=1:num_fts
   idx = (i-1) * (num_filter_pts/2) + 1;
   temp = fft(blackman_window .* patch_voltage(idx:(idx+(num_filter_pts-1)),1))'./sqrt(num_filter_pts);
   temp_real = real(temp);
   temp_imag = imag(temp)*1;
   temp_in = complex(temp_real, temp_imag);
   out(i,:) = temp_in;
end