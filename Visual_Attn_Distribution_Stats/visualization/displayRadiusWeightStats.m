function displayRadiusWeightStats( scallopTesting )
%DISPLAYRADIUSWEIGHTSTATS Compute radius weight statistics

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

params = scallopTesting.params;
distributionData = scallopTesting.distributionData;
statData = scallopTesting.statData;

%% Segregating radius weights


[scallopRadiusWtTemplateVal, nonScallopRadiusWtTemplateVal, skippedScallopRadiusWtTemplateVal, ~,~,~,~,~,~]...
            = segregateValues( params, distributionData, statData, 'matchRadiusWtTemplateVal' );

[scallopTemplateVal, nonScallopTemplateVal, skippedScallopTemplateVal, ~,~,~,~,~,~]...
            = segregateValues( params, distributionData, statData, 'matchTemplateVal' );

[scallopRadiusWtVal, nonScallopRadiusWtVal, skippedScallopRadiusWtVal, ~,~,~,~,~,~]...
            = segregateValues( params, distributionData, statData, 'radiusWt' );
        
[scallopRadiusVal, nonScallopRadiusVal, skippedScallopRadiusVal, ~,~,~,~,~,~]...
            = segregateRadiusValues( params, distributionData, statData );        
        
%% Display plots

displayRadiusPlots( params, scallopRadiusWtTemplateVal, nonScallopRadiusWtTemplateVal,...
                                scallopTemplateVal, nonScallopTemplateVal,...
                                scallopRadiusWtVal, nonScallopRadiusWtVal,...
                                scallopRadiusVal, nonScallopRadiusVal );
        
end

%% Function to segregate match values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [scallopDistrMatchCounts, nonScallopDistrMatchCounts, skippedScallopDistrMatchCounts, ...
          numScallopDataAvailable, numScallopDataUnavailable, ...
          numNonScallopDataAvailable, numNonScallopDataUnavailable, ...
          numSkippedScallopDataAvailable, numSkippedScallopDataUnavailable, ...
          scallopRadiusVal, nonScallopRadiusVal ] ...
            = segregateValues( params, distributionData, statData, matchMetric )

%% Initialization

numImages = params.numImages;

numScallopDataAvailable = 0;
numScallopDataUnavailable = 0;
numNonScallopDataAvailable = 0;
numNonScallopDataUnavailable = 0;
numSkippedScallopDataAvailable = 0;
numSkippedScallopDataUnavailable = 0;

scallopDistrMatchCounts = [];
nonScallopDistrMatchCounts = [];
skippedScallopDistrMatchCounts = [];

%% Data Segregation

for imageI=1:numImages
    numObj = size( distributionData.objList{imageI}, 1 );
    for objI=1:numObj
        
        switch statData.categoryStats(imageI).objects(objI)
            case 1
                if distributionData.dataAvailable{imageI}(objI)
                    numScallopDataAvailable = numScallopDataAvailable + 1;
                    scallopDistrMatchCounts = ...
                        [scallopDistrMatchCounts distributionData.dataPointMatch{imageI}{objI}.(matchMetric) ];
                else
                    numScallopDataUnavailable = numScallopDataUnavailable + 1;
                end
            case 0
                if distributionData.dataAvailable{imageI}(objI)
                    numNonScallopDataAvailable = numNonScallopDataAvailable + 1;
                    nonScallopDistrMatchCounts = ...
                        [nonScallopDistrMatchCounts distributionData.dataPointMatch{imageI}{objI}.(matchMetric)];
                else
                    numNonScallopDataUnavailable = numNonScallopDataUnavailable + 1;
                end
            case -1
                if distributionData.dataAvailable{imageI}(objI)
                    numSkippedScallopDataAvailable = numSkippedScallopDataAvailable + 1;
                    
                    skippedScallopDistrMatchCounts = ...
                        [skippedScallopDistrMatchCounts distributionData.dataPointMatch{imageI}{objI}.(matchMetric)];
                else
                    numSkippedScallopDataUnavailable = numSkippedScallopDataUnavailable + 1;
                end
        end
    end
end

end

%% Function to segregate radius values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [scallopDistrMatchCounts, nonScallopDistrMatchCounts, skippedScallopDistrMatchCounts, ...
          numScallopDataAvailable, numScallopDataUnavailable, ...
          numNonScallopDataAvailable, numNonScallopDataUnavailable, ...
          numSkippedScallopDataAvailable, numSkippedScallopDataUnavailable ] ...
            = segregateRadiusValues( params, distributionData, statData )

%% Initialization

numImages = params.numImages;

numScallopDataAvailable = 0;
numScallopDataUnavailable = 0;
numNonScallopDataAvailable = 0;
numNonScallopDataUnavailable = 0;
numSkippedScallopDataAvailable = 0;
numSkippedScallopDataUnavailable = 0;

scallopDistrMatchCounts = [];
nonScallopDistrMatchCounts = [];
skippedScallopDistrMatchCounts = [];

%% Data Segregation

for imageI=1:numImages
    numObj = size( distributionData.objList{imageI}, 1 );
    for objI=1:numObj
        
        switch statData.categoryStats(imageI).objects(objI)
            case 1
                if distributionData.dataAvailable{imageI}(objI)
                    numScallopDataAvailable = numScallopDataAvailable + 1;
                    scallopDistrMatchCounts = ...
                        [scallopDistrMatchCounts distributionData.objList{imageI}(objI,3)];
                else
                    numScallopDataUnavailable = numScallopDataUnavailable + 1;
                end
            case 0
                if distributionData.dataAvailable{imageI}(objI)
                    numNonScallopDataAvailable = numNonScallopDataAvailable + 1;
                    nonScallopDistrMatchCounts = ...
                        [nonScallopDistrMatchCounts distributionData.objList{imageI}(objI,3)];
                else
                    numNonScallopDataUnavailable = numNonScallopDataUnavailable + 1;
                end
            case -1
                if distributionData.dataAvailable{imageI}(objI)
                    numSkippedScallopDataAvailable = numSkippedScallopDataAvailable + 1;
                    
                    skippedScallopDistrMatchCounts = ...
                        [skippedScallopDistrMatchCounts distributionData.objList{imageI}(objI,3)];
                else
                    numSkippedScallopDataUnavailable = numSkippedScallopDataUnavailable + 1;
                end
        end
    end
end

end

%% Display Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displayRadiusPlots( params, scallopRadiusWtTemplateVal, nonScallopRadiusWtTemplateVal,...
                                scallopTemplateVal, nonScallopTemplateVal,...
                                scallopRadiusWtVal, nonScallopRadiusWtVal,...
                                scallopRadiusVal, nonScallopRadiusVal )

%% Plot limits

maxBarLimit = max( max( scallopTemplateVal ), max( nonScallopTemplateVal ) );
minBarLimit = min( min( scallopRadiusWtTemplateVal ), min( nonScallopRadiusWtTemplateVal ) );
maxRadiusWtLimit = max( max( scallopRadiusWtVal ), max( nonScallopRadiusWtVal ) );
minRadiusWtLimit = min( min( scallopRadiusWtVal ), min( nonScallopRadiusWtVal ) );
maxRadiusLimit = max( max( scallopRadiusVal ), max( nonScallopRadiusVal ) );
minRadiusLimit = min( min( scallopRadiusVal ), min( nonScallopRadiusVal ) );

subplot(421)
bar(scallopRadiusWtTemplateVal)
ylim([minBarLimit maxBarLimit]);

subplot(422)
bar(nonScallopRadiusWtTemplateVal(1:25))
ylim([minBarLimit maxBarLimit]);

subplot(423)
bar(scallopTemplateVal)
ylim([minBarLimit maxBarLimit]);

subplot(424)
bar(nonScallopTemplateVal(1:25))
ylim([minBarLimit maxBarLimit]);

subplot(425)
bar(scallopRadiusWtVal)
ylim([minRadiusWtLimit maxRadiusWtLimit]);

subplot(426)
bar(nonScallopRadiusWtVal(1:25))
ylim([minRadiusWtLimit maxRadiusWtLimit]);

subplot(427)
bar(scallopRadiusVal)
ylim([minRadiusLimit maxRadiusLimit]);

subplot(428)
bar(nonScallopRadiusVal(1:25))
ylim([minRadiusLimit maxRadiusLimit]);

end