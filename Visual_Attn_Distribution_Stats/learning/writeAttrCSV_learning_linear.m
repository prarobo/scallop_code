function [] = writeAttrCSV_learning_linear( params, currDataPoint, imageI )
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
 
fid = fopen( attrFile, 'a' );

%% Writing to file
        
for rowI = 1:params.resizeImageSize
    for colI=1:params.resizeImageSize
        
        % Scallop
        fprintf(fid,'%d',currDataPointObj.grayMap(rowI,colI) );
        if rowI == params.resizeImageSize && colI == params.resizeImageSize
            fprintf(fid,'\n');
        else
            fprintf(fid,',');
        end
    end
end

fclose(fid);

end
