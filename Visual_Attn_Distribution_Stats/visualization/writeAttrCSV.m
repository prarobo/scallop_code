function [] = writeAttrCSV( params, fixationsVar, currDataPoint, imageI, numImages )
%WRITEATTRCSV Summary Write aattribute values to csv files

attrFile = 'attrData.csv';
if imageI == 1
    fid = fopen( attrFile, 'w' );
    fclose(fid);
end

for fixI = 1:fixationsVar(imageI)
    numObj = length( currDataPoint{fixI} );
    
    for objI = 1:numObj
        fprintf('Writing image check %d of %d, fixation %d of %d, object %d of %d ...', imageI, numImages, fixI, fixationsVar(imageI), ...
            objI, numObj);
        
        currDataPointWrite(currDataPoint{fixI}{objI}, params, attrFile );
        fprintf('done\n');
    end
end

end

%% Writing Current Data Point To CSV File
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function currDataPointWrite( currDataPointObj, params, attrFile )

%% Initialization

numFeatures = length(fieldnames(currDataPointObj));
numRadBins = params.numRadBins+1;
numThetaBins = params.numThetaBins+1;
binInterval = 1/(params.numDiscretizationBins-1);
 
fid = fopen( attrFile, 'a' );

%% Writing to file

for featI = 1:numFeatures
    FeatureColor = sprintf('%sColor', params.featureMatCaps{featI} );
        
    for radI = 1:numRadBins
        for thetaI=1:numThetaBins
            
            % Scallop
            currBinNum = fix(currDataPointObj.(FeatureColor)(radI,thetaI)/binInterval);
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
