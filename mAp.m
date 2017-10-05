function [ avgPrecs, meanDists ] = mAp( precision, recall, distances, steps )
%MAP Summary of this function goes here
%   Detailed explanation goes here
threshs = linspace(0.,1.,steps);
meanDists = zeros(1,steps);
avgPrecs = zeros(1,steps);
for i=1:length(threshs)-1
    idx = recall>threshs(i) & recall<threshs(i+1); %find all successfull cases
    if any(idx)
        avgPrecs(i) = mean(precision(idx));
        idxNotNan = ~isnan(distances) & idx;
        meanDists(i) = mean(distances(idxNotNan));
    else
        avgPrecs(i) = 0;
        meanDists(i) = NaN;
    end
end