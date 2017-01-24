function [ visualAttnOutData ] = classifierStats_graph( visualAttnInData )
%CLASSIFIERSTATS Computes classifier thresholds

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

visualAttnOutData = visualAttnInData;
% totalDistrNum = visualAttnOutData.params.numRadBins * visualAttnOutData.params.numThetaBins * length(visualAttnOutData.params.featureMatCaps);
% startDistrNum = 300;
% endDistrNum = 600;
% polyFitIntervalLen = 50;
% polyFitIntervalMat = startDistrNum:polyFitIntervalLen:endDistrNum;
params = visualAttnOutData.params;

%% Classification Histograms computation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Edge histogram
[visualAttnOutData.classData.origData.scallopDistrMatchCountsEdge,...
    visualAttnOutData.classData.origData.nonScallopDistrMatchCountsEdge,...
    visualAttnOutData.classData.origData.bgDistrMatchCountsEdge] ...
    = computeMatchVect( visualAttnOutData.statData.category, visualAttnOutData.distributionData.dataPointCheck, params );

% Graph histogram
[visualAttnOutData.classData.origData.scallopDistrMatchCountsGraph,...
    visualAttnOutData.classData.origData.nonScallopDistrMatchCountsGraph,...
    visualAttnOutData.classData.origData.bgDistrMatchCountsGraph] ...
    = computeMatchVect( visualAttnOutData.statData.categoryGraph, visualAttnOutData.distributionData.dataPointCheckGraph, params );

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
hist( visualAttnOutData.classData.origData.nonScallopDistrMatchCountsEdge(:), 100 );

subplot(131)
hist( visualAttnOutData.classData.origData.scallopDistrMatchCountsEdge(:),100 );

subplot(133)
hist( visualAttnOutData.classData.origData.bgDistrMatchCountsEdge(:),100 );

% createFit(scallopDistrMatchCounts, nonScallopDistrMatchCounts);
% intersect = input('Enter point of intersection : ');
% intersect = input('Enter point of intersection : ');
% 

intersect = 0;
visualAttnOutData.classData.threshold = intersect;

%% Classification Results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Edge
visualAttnOutData.classData.results.totalScallopsEdge = numel(visualAttnOutData.classData.origData.scallopDistrMatchCountsEdge);
visualAttnOutData.classData.results.totalNonScallopsEdge = numel(visualAttnOutData.classData.origData.nonScallopDistrMatchCountsEdge);
visualAttnOutData.classData.results.totalBGEdge = numel(visualAttnOutData.classData.origData.bgDistrMatchCountsEdge);

visualAttnOutData.classData.results.positiveScallopEdge ...
    = sum( visualAttnOutData.classData.origData.scallopDistrMatchCountsEdge(:) >= intersect );
visualAttnOutData.classData.results.positiveNonScallopsEdge ...
    = sum( visualAttnOutData.classData.origData.nonScallopDistrMatchCountsEdge(:) >= intersect );
visualAttnOutData.classData.results.positivePercentScallopsEdge ...
    = sum( visualAttnOutData.classData.origData.scallopDistrMatchCountsEdge(:) >= intersect )/...
    numel(visualAttnOutData.classData.origData.scallopDistrMatchCountsEdge);
visualAttnOutData.classData.results.positivePercentNonScallopsEdge ...
    = sum( visualAttnOutData.classData.origData.nonScallopDistrMatchCountsEdge(:) >= intersect )/...
    numel(visualAttnOutData.classData.origData.nonScallopDistrMatchCountsEdge);

visualAttnOutData.classData.results.scallopsBGMatchLostEdge = visualAttnOutData.statData.scallopBGDistrMatchNum;

% Graph
visualAttnOutData.classData.results.totalScallopsGraph = numel(visualAttnOutData.classData.origData.scallopDistrMatchCountsGraph);
visualAttnOutData.classData.results.totalNonScallopsGraph = numel(visualAttnOutData.classData.origData.nonScallopDistrMatchCountsGraph);
visualAttnOutData.classData.results.totalBGGraph = numel(visualAttnOutData.classData.origData.bgDistrMatchCountsGraph);

visualAttnOutData.classData.results.positiveScallopGraph ...
    = sum( visualAttnOutData.classData.origData.scallopDistrMatchCountsGraph(:) >= intersect );
visualAttnOutData.classData.results.positiveNonScallopsGraph ...
    = sum( visualAttnOutData.classData.origData.nonScallopDistrMatchCountsGraph(:) >= intersect );
visualAttnOutData.classData.results.positivePercentScallopsGraph ...
    = sum( visualAttnOutData.classData.origData.scallopDistrMatchCountsGraph(:) >= intersect )/...
    numel(visualAttnOutData.classData.origData.scallopDistrMatchCountsGraph);
visualAttnOutData.classData.results.positivePercentNonScallopsGraph ...
    = sum( visualAttnOutData.classData.origData.nonScallopDistrMatchCountsGraph(:) >= intersect )/...
    numel(visualAttnOutData.classData.origData.nonScallopDistrMatchCountsGraph);

visualAttnOutData.classData.results.scallopsBGMatchLostGraph = visualAttnOutData.statData.scallopBGDistrMatchNumGraph;

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

%% Function for Classification Histograms computation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [scallopDistrMatchCounts, nonScallopDistrMatchCounts, bgDistrMatchCounts] = computeMatchVect( category, dataPointCheck, params )

% Initialization
scallopDistrMatchCounts = [];
nonScallopDistrMatchCounts = [];
bgDistrMatchCounts = [];
numImages = params.numImages;

for imageI=1:numImages
    for fixI=1:length(category(imageI).fixations)
        for objI=1:length(category(imageI).fixations{fixI})
            switch category(imageI).fixations{fixI}(objI)
                case 1
                scallopDistrMatchCounts = ...
                    [scallopDistrMatchCounts dataPointCheck{imageI}{fixI}{objI}.scallopMatchPoints];
                case 0
                nonScallopDistrMatchCounts = ...
                    [nonScallopDistrMatchCounts dataPointCheck{imageI}{fixI}{objI}.scallopMatchPoints];
                case 2
                bgDistrMatchCounts = ...
                    [bgDistrMatchCounts dataPointCheck{imageI}{fixI}{objI}.scallopMatchPoints];
            end
        end
    end
end

% normScallopDistrCounts = scallopDistrMatchCounts/max(scallopDistrMatchCounts(:));
% normNonScallopDistrCounts = nonScallopDistrMatchCounts/max(nonScallopDistrMatchCounts(:));

end


