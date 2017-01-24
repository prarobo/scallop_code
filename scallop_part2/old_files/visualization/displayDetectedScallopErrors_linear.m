function [] = displayDetectedScallopErrors_linear( scallopTesting )
%DISPLAYDETECTEDSCALLOPERRORS Displays detected scallop errors in radius
%center and total

radiusErrorVect = abs(scallopTesting.classData.segmentResults.radiusErrorVect);
centerErrorVect = abs(scallopTesting.classData.segmentResults.centerErrorVect);
totalErrorVect = scallopTesting.classData.segmentResults.totalErrorVect;

figure;
subplot(131)
plot( radiusErrorVect );
legend( sprintf('Mean = %d\n Stddev = %d', mean( radiusErrorVect(:) ), sqrt( var( radiusErrorVect(:) ) ) ) );
title('Radius error');

subplot(132)
plot( centerErrorVect );
legend( sprintf('Mean = %d\n Stddev = %d', mean( centerErrorVect(:) ), sqrt( var( centerErrorVect(:) ) ) ) );
title('Center error');

subplot(133)
plot( totalErrorVect );
legend( sprintf('Mean = %d\n Stddev = %d', mean( totalErrorVect(:) ), sqrt( var( totalErrorVect(:) ) ) ) );
title('Total error');

end

