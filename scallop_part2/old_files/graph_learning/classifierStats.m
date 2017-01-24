function [ visualAttnOutData ] = classifierStats( visualAttnInData )
%CLASSIFIERSTATS Computes classifier thresholds

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

visualAttnOutData = visualAttnInData;
% totalDistrNum = visualAttnOutData.params.numRadBins * visualAttnOutData.params.numThetaBins * length(visualAttnOutData.params.featureMatCaps);
startDistrNum = 300;
endDistrNum = 600;
polyFitIntervalLen = 50;
polyFitIntervalMat = startDistrNum:polyFitIntervalLen:endDistrNum;

%% Classification Histograms
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
scallopDistrMatchCounts = [];
nonScallopDistrMatchCounts = [];
bgDistrMatchCounts = [];

for imageI=1:length(visualAttnOutData.statData.category)
    for fixI=1:length(visualAttnOutData.statData.category(imageI).fixations)
        for objI=1:length(visualAttnOutData.statData.category(imageI).fixations{fixI})
            switch visualAttnOutData.statData.category(imageI).fixations{fixI}(objI)
                case 1
                scallopDistrMatchCounts = ...
                    [scallopDistrMatchCounts visualAttnOutData.distributionData.dataPointCheck{imageI}{fixI}{objI}.scallopMatchPoints];
                case 0
                nonScallopDistrMatchCounts = ...
                    [nonScallopDistrMatchCounts visualAttnOutData.distributionData.dataPointCheck{imageI}{fixI}{objI}.scallopMatchPoints];
                case 2
                bgDistrMatchCounts = ...
                    [bgDistrMatchCounts visualAttnOutData.distributionData.dataPointCheck{imageI}{fixI}{objI}.scallopMatchPoints];
            end
        end
    end
end

visualAttnOutData.segmentData.totalObjects ...
    = numel(scallopDistrMatchCounts) + numel(nonScallopDistrMatchCounts) + numel(bgDistrMatchCounts);

% normScallopDistrCounts = scallopDistrMatchCounts/max(scallopDistrMatchCounts(:));
% normNonScallopDistrCounts = nonScallopDistrMatchCounts/max(nonScallopDistrMatchCounts(:));

visualAttnOutData.classData.origData.scallopDistrMatchCounts = scallopDistrMatchCounts;
visualAttnOutData.classData.origData.nonScallopDistrMatchCounts = nonScallopDistrMatchCounts;

%% Curve Fitting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% scallopDistr = fitdist( scallopDistrMatchCounts', 'Burr');
% nonScallopDistr = fitdist( nonScallopDistrMatchCounts', 'Burr');
% [scallopDensityFit.f, scallopDensityFit.xi] = ksdensity( normScallopDistrCounts );
% [nonScallopDensityFit.f, nonScallopDensityFit.xi] = ksdensity( normNonScallopDistrCounts );

% scallopHistData = histc( scallopDistrMatchCounts, polyFitIntervalMat );
% nonScallopHistData = histc( nonScallopDistrMatchCounts, polyFitIntervalMat );
% 
% scallopPolyFit = polyfit(polyFitIntervalMat, scallopHistData, 5);
% nonScallopPolyFit = polyfit(polyFitIntervalMat, nonScallopHistData, 5);
% 
% yScallopVal = computePolyVal( polyFitIntervalMat, scallopPolyFit );
% yNonScallopVal = computePolyVal( polyFitIntervalMat, nonScallopPolyFit );

% visualAttnOutData.classData.polyData.scallopHistData = scallopHistData;
% visualAttnOutData.classData.polyData.nonScallopHistData = nonScallopHistData;
% visualAttnOutData.classData.polyData.scallopPolyFit = scallopPolyFit;
% visualAttnOutData.classData.polyData.nonScallopPolyFit = nonScallopPolyFit;
% 
% visualAttnOutData.classData.polyData.xScallopVal = polyFitIntervalMat;
% visualAttnOutData.classData.polyData.yScallopVal = yScallopVal;
% visualAttnOutData.classData.polyData.xNonScallopVal = polyFitIntervalMat;
% visualAttnOutData.classData.polyData.yNonScallopVal = yNonScallopVal;

% visualAttnOutData.classData.polyData.scallopDensityFit = scallopDensityFit;
% visualAttnOutData.classData.polyData.nonScallopDensityFit = nonScallopDensityFit;

% visualAttnOutData.classData.scallopDistrFit = scallopDistr;
% visualAttnOutData.classData.nonScallopDistrFit = nonScallopDistr;

%% Point of intersection of curves
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% a1=scallopDistr.Params(1);
% c1=scallopDistr.Params(2);
% k1=scallopDistr.Params(3);
% 
% a2=nonScallopDistr.Params(1);
% c2=nonScallopDistr.Params(2);
% k2=nonScallopDistr.Params(3);
% 
% curve = @(x) (1+(x/a1)^c1)^k1 - (1+(x/a2)^c2)^k2;
% intersect = fzero( curve, 99 );

subplot(132)
hist( nonScallopDistrMatchCounts(:), 100 );

subplot(131)
hist( scallopDistrMatchCounts(:),100 );

subplot(133)
hist( bgDistrMatchCounts(:),100 );

% createFit(scallopDistrMatchCounts, nonScallopDistrMatchCounts);
% intersect = input('Enter point of intersection : ');
intersect = 0;
% 
visualAttnOutData.classData.threshold = intersect;

%% Classification Results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

visualAttnOutData.classData.results.totalScallops = numel(scallopDistrMatchCounts);
visualAttnOutData.classData.results.totalNonScallops = numel(nonScallopDistrMatchCounts);
visualAttnOutData.classData.results.totalBG = numel(bgDistrMatchCounts);

visualAttnOutData.classData.results.positiveScallops = sum( scallopDistrMatchCounts(:) >= intersect );
visualAttnOutData.classData.results.positiveNonScallops = sum( nonScallopDistrMatchCounts(:) >= intersect );
visualAttnOutData.classData.results.positivePercentScallops = sum( scallopDistrMatchCounts(:) >= intersect )/numel(scallopDistrMatchCounts);
visualAttnOutData.classData.results.positivePercentNonScallops = sum( nonScallopDistrMatchCounts(:) >= intersect )/numel(nonScallopDistrMatchCounts);

visualAttnOutData.classData.results.scallopsBGMatchLost = visualAttnOutData.statData.scallopBGDistrMatchNum;
%% Visualization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% subplot(121)
% % hist( normScallopDistrCounts(:) );
% % hist( scallopDistrMatchCounts(:) );
% histfit( scallopDistrMatchCounts(:), 15, 'burr' );
% % hold on
% %plot( polyFitIntervalMat, yScallopVal, 'r' );
% % plot( scallopDensityFit.xi, scallopDensityFit.f, 'g' );
% %xlim([300 600])
% 
% subplot(122)
% % hist( normNonScallopDistrCounts(:) );
% % hist( nonScallopDistrMatchCounts(:) );
% histfit( nonScallopDistrMatchCounts(:), 15, 'burr' );
% % hold on
% %plot( polyFitIntervalMat, yNonScallopVal, 'r' );
% % plot( nonScallopDensityFit.xi, nonScallopDensityFit.f, 'g' );
% %xlim([300 600])
% 
% figure;
% histfit( scallopDistrMatchCounts(:), 15, 'burr' );
% hold on
% histfit( nonScallopDistrMatchCounts(:), 15, 'burr' );

end


%% Function to generate y values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function yVal = computePolyVal( xVal, polyCoeff )

polyDeg = length(polyCoeff)-1;
yVal = zeros(size(xVal));

for valI = numel(xVal)
    for degI=polyDeg:-1:0
        yVal(valI) = yVal(valI) + xVal(valI)^degI*polyCoeff(polyDeg+1-degI);
    end
end

end

