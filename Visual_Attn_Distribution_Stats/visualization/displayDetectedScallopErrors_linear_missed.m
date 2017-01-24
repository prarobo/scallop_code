function [] = displayDetectedScallopErrors_linear_missed( scallopTesting )
%DISPLAYDETECTEDSCALLOPERRORS Displays detected scallop errors in radius
%center and total

radiusErrorVect = abs(scallopTesting.classData.segmentResults.radiusErrorVect);
centerErrorVect = abs(scallopTesting.classData.segmentResults.centerErrorVect);
totalErrorVect = scallopTesting.classData.segmentResults.totalErrorVect;

radiusMissedErrorVect = abs(scallopTesting.classData.segmentResults.radiusMissedErrorVect);
centerMissedErrorVect = abs(scallopTesting.classData.segmentResults.centerMissedErrorVect);
totalMissedErrorVect = scallopTesting.classData.segmentResults.totalMissedErrorVect;

totalSegmented = scallopTesting.classData.segmentResults.totalSegmented;
totalMissed = scallopTesting.classData.segmentResults.totalMissed;
totalSkipped = scallopTesting.classData.segmentResults.totalSkipped;

figure;

%% Segmented error plots

subplot(231)
plot( radiusErrorVect );
legend( sprintf('Mean = %f\n Stddev = %f', mean( radiusErrorVect(:) ), std( radiusErrorVect(:) ) ) );
title('Radius error');

subplot(232)
plot( centerErrorVect );
legend( sprintf('Mean = %f\n Stddev = %f', mean( centerErrorVect(:) ), std( centerErrorVect(:) ) ) );
title('Center error');

subplot(233)
plot( totalErrorVect );
legend( sprintf('Mean = %f\n Stddev = %f', mean( totalErrorVect(:) ), std( totalErrorVect(:) ) ) );
title('Total error');

%% Missed error plots

subplot(234)
plot( radiusMissedErrorVect );
legend( sprintf('Mean = %f\n Stddev = %f', mean( radiusMissedErrorVect(:) ), std( radiusMissedErrorVect(:) ) ) );
title('Radius missed error');

subplot(235)
plot( centerMissedErrorVect );
legend( sprintf('Mean = %f\n Stddev = %f', mean( centerMissedErrorVect(:) ), std( centerMissedErrorVect(:) ) ) );
title('Center missed error');

subplot(236)
plot( totalMissedErrorVect );
legend( sprintf('Mean = %f\n Stddev = %f', mean( totalMissedErrorVect(:) ), std( totalMissedErrorVect(:) ) ) );
title('Total missed error');

%% Results

resultsString = sprintf( 'totalSegmented = %f, totalMissed = %f, totalSkipped = %f', totalSegmented, totalMissed, totalSkipped );
suptitle( resultsString );

end

