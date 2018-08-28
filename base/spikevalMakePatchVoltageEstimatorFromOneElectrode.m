function patch_voltage_estimator = spikevalMakePatchVoltageEstimatorFromOneElectrode(convolutive_filter, electrode_voltage, options)

num_filter_pts = options.num_convolution_filter_pts;

f = zeros(length(electrode_voltage),1);
f(1:(num_filter_pts/2)) = convolutive_filter(1:(num_filter_pts/2));
f((end-(num_filter_pts/2)+1):end) = convolutive_filter(((num_filter_pts/2)+1):end);

a = fft(f)./sqrt(num_filter_pts);
b = fft(electrode_voltage)./sqrt(num_filter_pts);

patch_voltage_estimator = ifft(a.*b);
