function [ checkData ] = checkDataPoint( currDataPoint, params, percentilePoints )
%CHECKDATAPOINT Classifies the given data point

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numFeatures = length(fieldnames(currDataPoint));
numRadBins = params.numRadBins;
numThetaBins = params.numThetaBins;
binInterval = 1/(params.numDiscretizationBins-1);

%% Computing Number of RV satisfied
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for featI = 1:numFeatures
    FeatureColor = sprintf('%sColor', params.featureMatCaps{featI} );
    FeatureColorBG = sprintf('%sColorBG', params.featureMatCaps{featI} );
    
    resultsData.(FeatureColor) = zeros(numRadBins,numThetaBins);
    resultsData.(FeatureColorBG) = zeros(numRadBins,numThetaBins);    
    
    for radI = 1:numRadBins
        for thetaI=1:numThetaBins
            
            % Scallop
            if(~percentilePoints.(FeatureColor).isValid(radI,thetaI))
                resultsData.(FeatureColor)(radI,thetaI) = -1;
            else
                currBinNum = fix(currDataPoint.(FeatureColor)(radI,thetaI)/binInterval);
                if(percentilePoints.(FeatureColor).checkMat{radI,thetaI}(currBinNum+1))
                    resultsData.(FeatureColor)(radI,thetaI) = 1;
                end
            end
            
            % Background
            if(~percentilePoints.(FeatureColorBG).isValid(radI,thetaI))
                resultsData.(FeatureColorBG)(radI,thetaI) = -1;
            else
                currBinNum = fix(currDataPoint.(FeatureColor)(radI,thetaI)/binInterval);
                if(percentilePoints.(FeatureColorBG).checkMat{radI,thetaI}(currBinNum+1))
                    resultsData.(FeatureColorBG)(radI,thetaI) = 1;
                end
            end
            
        end
    end   
end

%% Classification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
checkData.scallopMatchPoints = 0;
checkData.bgMatchPoints = 0;
checkData.bothMatchPoints = 0;
checkData.scallopSkippedPoints = 0;
checkData.bgSkippedPoints = 0;
checkData.bothSkippedPoints = 0;

for featI = 1:numFeatures
    FeatureColor = sprintf('%sColor', params.featureMatCaps{featI} );
    FeatureColorBG = sprintf('%sColorBG', params.featureMatCaps{featI} );
        
    for radI = 1:numRadBins
        for thetaI=1:numThetaBins
            
            % Accepted and Skipped points
            %             if(resultsData.(FeatureColor)(radI,thetaI) == -1 && ...
            %                     resultsData.(FeatureColorBG)(radI,thetaI) == -1 )
            %                 checkDistr = -3;  % Not scallop, not background
            %             elseif(resultsData.(FeatureColor)(radI,thetaI) == -1)
            %                 checkDistr = -1;  % Not scallop
            %             elseif(resultsData.(FeatureColorBG)(radI,thetaI) == -1)
            %                 checkDistr = -2;  % Not background
            %             elseif(resultsData.(FeatureColor)(radI,thetaI) == 1 && ...
            %                     resultsData.(FeatureColorBG)(radI,thetaI) == 1 )
            %                 checkDistr = 3;   % Both scallop and background
            %             elseif(resultsData.(FeatureColor)(radI,thetaI) == 1)
            %                 checkDistr = 1;   % Scallop
            %             elseif(resultsData.(FeatureColorBG)(radI,thetaI) == 1)
            %                 checkDistr = 2;   % Background
            %             end
            
            % Skipped Points
            if resultsData.(FeatureColor)(radI,thetaI) == -1
                checkData.scallopSkippedPoints = checkData.scallopSkippedPoints + 1;
            end
            if resultsData.(FeatureColorBG)(radI,thetaI) == -1
                checkData.bgSkippedPoints = checkData.bgSkippedPoints + 1;
            end
            if (resultsData.(FeatureColor)(radI,thetaI) == -1 && resultsData.(FeatureColorBG)(radI,thetaI) == -1)
                checkData.bothSkippedPoints = checkData.bothSkippedPoints + 1;
            end
            
            % Accepted Points
            if resultsData.(FeatureColor)(radI,thetaI) == 1 
                checkData.scallopMatchPoints = checkData.scallopMatchPoints +1;
            end
            if resultsData.(FeatureColorBG)(radI,thetaI) == 1 
                checkData.bgMatchPoints = checkData.bgMatchPoints + 1;
            end
            if (resultsData.(FeatureColor)(radI,thetaI) == 1 && resultsData.(FeatureColorBG)(radI,thetaI) == 1)
                checkData.bothMatchPoints = checkData.bothMatchPoints + 1;
            end
            
        end
    end    
end

totalPoints = (params.numRadBins+1) * (params.numThetaBins+1) * numFeatures;
checkData.scallopFailPoints = totalPoints - checkData.scallopMatchPoints - checkData.scallopSkippedPoints;
checkData.bgFailPoints = totalPoints - checkData.bgMatchPoints - checkData.bgSkippedPoints;
checkData.bothFailPoints = totalPoints - checkData.bothMatchPoints - checkData.bothSkippedPoints;

end

