function [] = spikevalPlotConvolutiveFilters(centered_convolutive_filters_mat)


figure
for ii=1:4
    plot(centered_convolutive_filters_mat(:,2^(ii-1)), 'k')
    hold on
end
title('Convolutive filters from electrodes 1, 2, 4, and 8')