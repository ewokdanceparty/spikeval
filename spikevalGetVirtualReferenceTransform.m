function virt_ref_transform = spikevalGetVirtualReferenceTransform(traces)
%{
Returns tne matrix for the linear transformation
that removes the virtual reference from each channel
e.g. traces_virt_ref = virt_ref_transform*traces;

This function was created by Caroline Moore-Kochlacs, which is a
modification of code from Jacob Bernstein
%}


[n_traces n_points] = size(traces);
if n_traces > n_points
    error('traces in wrong orientation');
    % todo, transform or standardize
end

virtref = mean(traces);
virtpower = sum(virtref.^2);
virt_ref_transform = eye(n_traces) - traces*virtref'*ones(1,n_traces)/n_traces/virtpower;

% above more simply recreates code below, that jake wrote
%
% virtref = mean(traces);
% virtpower = sum(virtref_trace.^2);
% for i=1:length(goodchannels)
%     overlap = sum(virtref_trace.*traces(:,goodchannels(i)))/virtpower;
%     traces(:,goodchannels(i)) = traces(:,goodchannels(i))-overlap*virtref;
%     overlaps(i) = overlap;
% end