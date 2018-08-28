function regression_result = spikevalRunLinearRegression(patch_voltage_estimator_struct, ordered_electrodes)
%{
Takes n estimators of patch voltage and returns a linear combination that
minimizes the mean-square error with the actual patch voltage
%}

a                   = patch_voltage_estimator_struct.patch;
b                   = patch_voltage_estimator_struct.patch_voltage_estimators_from_single_electrodes_mat;

weights             = regress(a, b(:, ordered_electrodes));

regression_result   = zeros(length(a(:,1)),1);

for ii=1:length(ordered_electrodes)
    regression_result = regression_result + b(:,ordered_electrodes(ii)).* weights(ii,1); 
end