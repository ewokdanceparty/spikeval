function centered_filters_mat = spikevalCenterTheConvolutiveFilters(convolutive_filters_mat, options)

centered_filters_mat = zeros(length(convolutive_filters_mat(:,1)), length(convolutive_filters_mat(1,:)));

for ii=1:length(centered_filters_mat(1,:))
    
    first_half  = 1:(options.num_convolution_filter_pts/2);
    second_half = (options.num_convolution_filter_pts/2 + 1):options.num_convolution_filter_pts;
    
    centered_filters_mat(first_half, ii)        = convolutive_filters_mat(second_half, ii);
    centered_filters_mat(second_half, ii)       = convolutive_filters_mat(first_half, ii);

    
end

