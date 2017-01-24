function [ visualAttnOutData ] = distr_2D_confInterval( visualAttnInData, scallopDistribution, varargin )
%DISTR_2D_CONFINTERVAL computes the confidence intervals from the learning
%data

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch nargin
    case 2
        confIntervalScallop = 0.95;
        confIntervalBG = 0.5;
    case 3
        confIntervalScallop = varargin{1};
        confIntervalBG = 0.5;
    case 4
        confIntervalScallop = varargin{1};
        confIntervalBG = varargin{2};
    otherwise
        error('Bloody Balderdash! incompatible number of arguments');
end
visualAttnOutData = visualAttnInData;
visualAttnOutData.params.confIntervalScallop = confIntervalScallop;
visualAttnOutData.params.confIntervalBG = confIntervalBG;

numFeatures = length( scallopDistribution.params.featureMatCaps);
numRadBins = scallopDistribution.params.numRadBins;
numThetaBins = scallopDistribution.params.numThetaBins;
numDiscretizationBins = scallopDistribution.params.numDiscretizationBins;

%% Percentile point calculation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for featI = 1:numFeatures
    FeatureColor = sprintf('%sColor', scallopDistribution.params.featureMatCaps{featI} );
    FeatureColorBG = sprintf('%sColorBG', scallopDistribution.params.featureMatCaps{featI} );  
    percentilePoints.(FeatureColor).isValid = true( numRadBins, numThetaBins );
    percentilePoints.(FeatureColorBG).isValid = true( numRadBins, numThetaBins );
    percentilePoints.(FeatureColor).checkMat = cell( numRadBins, numThetaBins );
    percentilePoints.(FeatureColorBG).checkMat = cell( numRadBins, numThetaBins );
    binIntervals = linspace(0,1,numDiscretizationBins);
    binIndex = 1:numDiscretizationBins;
    
    for radI = 1:numRadBins
        for thetaI=1:numThetaBins
            
            % Scallop
            numPoints = numel(scallopDistribution.arrayFeatureMaps.(FeatureColor){radI,thetaI});
            if(numPoints < 100)
                percentilePoints.(FeatureColor).isValid(radI, thetaI) = false;
                continue;
            end
            percentilePoints.(FeatureColor).checkMat{radI,thetaI}=true(numDiscretizationBins,1);
            cutOffPoints = numPoints*(1-confIntervalScallop);
            freqData = histc(scallopDistribution.arrayFeatureMaps.(FeatureColor){radI,thetaI}(:), binIntervals );
            freqMat = [freqData binIndex'];
            sortMat = sortrows(freqMat, 1);
            sumPoints = 0;
            
            for rowI=1:numDiscretizationBins
                sumPoints = sumPoints + sortMat(rowI,1);
                if sumPoints < cutOffPoints
                    percentilePoints.(FeatureColor).checkMat{radI,thetaI}(sortMat(rowI,2))=false;
                else
                    break;
                end
            end
        end
    end
    
    for radI = 1:numRadBins
        for thetaI=1:numThetaBins
            
            % Background
            numPointsBG = numel(scallopDistribution.arrayFeatureMaps.(FeatureColorBG){radI,thetaI});
            if(numPointsBG < 100)
                percentilePoints.(FeatureColorBG).isValid(radI, thetaI) = false;
                continue;
            end
            percentilePoints.(FeatureColorBG).checkMat{radI,thetaI}=true(numDiscretizationBins,1);
            cutOffPoints = numPointsBG*(1-confIntervalBG);
            freqData = histc(scallopDistribution.arrayFeatureMaps.(FeatureColorBG){radI,thetaI}(:), binIntervals );
            freqMat = [freqData binIndex'];
            sortMat = sortrows(freqMat, 1);
            sumPoints = 0;
            
            for rowI=1:numDiscretizationBins
                sumPoints = sumPoints + sortMat(rowI,1);
                if sumPoints < cutOffPoints
                    percentilePoints.(FeatureColorBG).checkMat{radI,thetaI}(sortMat(rowI,2))=false;
                end
            end            
        end
    end
end

visualAttnOutData.distributionData.percentilePoints = percentilePoints;

end   

