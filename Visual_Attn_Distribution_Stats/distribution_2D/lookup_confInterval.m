function [ confIntervalData, scallopLookupParams ] = lookup_confInterval( params, scallopLookup )
%lookup_confInterval computes the confidence intervals from the learning
%data

%% Initialization

scallopLookupTable = scallopLookup.lookupTable;
scallopLookupParams = scallopLookup.params;

confInterval = cell( params.imageSize(1), params.imageSize(2) );
isValidConf = true( params.imageSize(1), params.imageSize(2) );
numPointsConf = zeros( params.imageSize(1), params.imageSize(2) );
pointsIDConf = cell( params.imageSize(1), params.imageSize(2) );
meanPointsConf = cell( params.imageSize(1), params.imageSize(2) );
stddevPointsConf = cell( params.imageSize(1), params.imageSize(2) );

numFeatures = params.resizeImageSize^2;
numRows = params.imageSize(1);
numCols = params.imageSize(2);
imageSize = params.imageSize;
confIntervalHalfWindow = params.confIntervalHalfWindow;
numDiscretizationBins = params.numDiscretizationBins;
confIntervalScallop = params.confIntervalScallop;

%% Generating Confidence Interval Calculations

% if matlabpool('size') == 0
%     matlabpool open local 4
% end

% for rowI = 40:40
for rowI = 1:numRows
    
    %     for colI = 42:42
    for colI = 1:numCols
        fprintf( 'Computing confidence interval: row %d col %d ...', rowI,colI);

        % Calculate the local rectangle to compute statistics
        rowcolLimits = calcRowColLimits( rowI, colI, imageSize, confIntervalHalfWindow );
        
        % Compute local datapoints
        [dataPoints, pointsIDConf{rowI, colI}] = computeLocalDataPoints( scallopLookupTable, rowcolLimits );
        numPointsConf(rowI, colI) = size(dataPoints,1);
        meanPointsConf{rowI, colI} = mean(dataPoints);
        stddevPointsConf{rowI, colI} = std(dataPoints);
        
        % Compute confidence interval
        [isValidConf(rowI,colI), confInterval{rowI,colI} ] ...
            = computeConfInterval(dataPoints, numPointsConf(rowI, colI), numDiscretizationBins, confIntervalScallop, numFeatures );
        
        fprintf('done\n');
    end
end

%% Outputs

confIntervalData.confInterval = confInterval;
confIntervalData.isValid = isValidConf;
confIntervalData.numPoints = numPointsConf;
confIntervalData.pointsID = pointsIDConf;
confIntervalData.meanPoints = meanPointsConf;
confIntervalData.stddevPoints = stddevPointsConf;
% confIntervalData.dataPoints = dataPointsConf;

end

%% Function to compute row column limits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rowcolLimit = calcRowColLimits( rowI, colI, imageSize, confIntervalHalfWindow )
    rowMin = max( rowI - confIntervalHalfWindow(1), 1 );
    rowMax = min( rowI + confIntervalHalfWindow(1), imageSize(1) );
    colMin = max( colI - confIntervalHalfWindow(2), 1 );
    colMax = min( colI + confIntervalHalfWindow(2), imageSize(2) );
    
    rowcolLimit = [rowMin rowMax colMin colMax];
end


%% Function to collect local data points
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [dataPoints, dataPointsID] = computeLocalDataPoints( scallopLookupTable, rowcolLimits )    
    dataPoints = vertcat(scallopLookupTable( rowcolLimits(1):rowcolLimits(2), rowcolLimits(3):rowcolLimits(4)).attributeData);
    dataPointsID = vertcat(scallopLookupTable( rowcolLimits(1):rowcolLimits(2), rowcolLimits(3):rowcolLimits(4)).scallopID);
end

%% Function to compute confidence interval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [isValid, confInterval] = computeConfInterval(dataPoints, numPoints, numDiscretizationBins, confIntervalScallop, numFeatures )

if numPoints
    isValid = true;
    cutOffPoints = numPoints*(1-confIntervalScallop);
    confInterval = true( numDiscretizationBins, numFeatures );
    
    for featI = 1:numFeatures
        freqData = histc( dataPoints(:,featI), 1:numDiscretizationBins );
        
        freqMat = [freqData(:) (1:numDiscretizationBins)'];
        sortMat = sortrows(freqMat, 1);
        sumPoints = 0;
        
        for binI=1:numDiscretizationBins
            sumPoints = sumPoints + sortMat(binI,1);
            if sumPoints < cutOffPoints
                confInterval(sortMat(binI,2),featI)=false;
            end
        end
    end
else
    isValid = false;
    confInterval = [];    
end

end


