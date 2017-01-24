function [] = displayScallopThresholdComparison( scallopTesting )
%DISPLAYSCALLOPTHRESHOLDCOMPARISON Plot the effect of threshold on scallop
%non scallop classification

%% Initialization

scallopPoints = scallopTesting.classData.numberStats.scallopDistrMatchCounts;
nonScallopPoints = scallopTesting.classData.numberStats.nonScallopDistrMatchCounts;
numIntervals = 100;
intervalVect = linspace( 0, max( max(scallopPoints), max(nonScallopPoints) ), numIntervals );
numScallops = length( scallopPoints );

scallopCounts = zeros(1, numIntervals);
nonScallopCounts = zeros(1,numIntervals);

%% Computing Interval Values

for intervalI = 1:numIntervals
    scallopCounts(intervalI) = sum( scallopPoints <= intervalVect(intervalI) );
    %scallopCounts(intervalI) = sum( scallopPoints >= intervalVect(intervalI) );
    nonScallopCounts(intervalI) = sum( nonScallopPoints <= intervalVect(intervalI) );
    %nonScallopCounts(intervalI) = sum( nonScallopPoints <= intervalVect(intervalI) );
end

detectionCounts = scallopCounts./numScallops;
precisionCounts = scallopCounts./(scallopCounts+nonScallopCounts);

%% Plots

subplot(211)
plot(intervalVect, scallopCounts,'red');
hold on
plot(intervalVect, nonScallopCounts,'green');
hold off
xlabel('Template match value');
title('scallop/non-scallop counts');
legend('scallop', 'non-scallop');

subplot(212)
plot(intervalVect, detectionCounts,'red');
hold on
plot(intervalVect, precisionCounts,'green');
hold off
xlabel('Template match value');
title('recall/precision rates');
legend('recall rate', 'precision rate');

% hold on
% plot(7*ones(10,1), linspace(0,1,10))
% hold off

end

