function out = spikevalCapROCAndGetAreaUnderCurve(TP, FP)

%{
Caps the ROC curve at FP = 1, so that the area under the curve calculation
only includes data points where FP <=1. To do so, we draw a straight line
between the data point just before FP = 1 and just after.

Then finds area under the curve using the trapezoidal method.
%}

for ii=1:length(FP)
    if FP(ii) < 1 % this is the first datapoint less than 1
        index_of_FP_greater_than_or_equal_to_1  = ii-1;
        index_of_FP_less_than_1                 = ii;
        linear_coefficients                     = polyfit([FP(index_of_FP_less_than_1) FP(index_of_FP_greater_than_or_equal_to_1)], [TP(index_of_FP_less_than_1) TP(index_of_FP_greater_than_or_equal_to_1)], 1);
        a = linear_coefficients(1);
        b = linear_coefficients(2);
        
        out.FP = [1 ; FP(index_of_FP_less_than_1:end)];
        out.TP = [(a+b) ; TP(index_of_FP_less_than_1:end)];
        
        out.area = -1 * trapz(out.FP', out.TP');
        break
    end
end