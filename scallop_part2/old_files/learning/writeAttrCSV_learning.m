function [] = writeAttrCSV_learning( params, currDataPoint, imageI )
%WRITEATTRCSV Summary Write aattribute values to csv files

attrFile = params.attrFile;
numImages = params.numImages;

numScallops = length( currDataPoint );

for scallopI = 1:numScallops
    fprintf('Writing image check %d of %d, scallop %d of %d ...', imageI, numImages, scallopI, numScallops);
    
    currDataPointWrite(currDataPoint{scallopI}, params, attrFile );
    fprintf('done\n');
end

end

%% Writing Current Data Point To CSV File
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function currDataPointWrite( currDataPointObj, params, attrFile )

%% Initialization

numFeatures = length(fieldnames(currDataPointObj));
numRadBins = params.numRadBins+1;
numThetaBins = params.numThetaBins+1;
binInterval = 1/params.numDiscretizationBins;
 
fid = fopen( attrFile, 'a' );

%% Writing to file

for featI = 1:numFeatures
    featureFeature = sprintf('%sFeature', params.featureMatCaps{featI} );
        
    for radI = 1:numRadBins
        for thetaI=1:numThetaBins
            
            % Scallop
            if currDataPointObj.(featureFeature)(radI,thetaI) ~= -1
                currBinNum = fix(currDataPointObj.(featureFeature)(radI,thetaI)/binInterval);
            else
                currBinNum = -1;
            end
            fprintf(fid,'%d',currBinNum);
            if featI == numFeatures && radI == numRadBins && thetaI == numThetaBins
                fprintf(fid,'\n');
            else
                fprintf(fid,',');
            end
        end
    end
end

fclose(fid);

end
