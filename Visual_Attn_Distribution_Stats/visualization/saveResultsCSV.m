function [ ] = saveResultsCSV( dirname )
%SAVERESULTSCSV Extracts results and saves into csv file

%% Fieldnames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

outputFields =  {    'totalImages';...
    'numGroundTruthScallops';...
    'numSegmentObjects';...
    'numBGObjects';...
    'numScallopsAfterVisual';...
    'percentScallopsAfterVisual';...
    'numScallopsAfterSegment';...
    'percentScallopsAfterSegment';...
    'numScallopsAfterClassifier';...
    'percentScallopsAfterClassifier';...
    'numNonScallopsAfterClassifier';...
    'percentNonScallopsAfterClassifier';...
    'scallopsBGMatchLost';...
    'percentScallopsBGMatchLost';...    
    'numFixations';...
    'fixationWindowSize';...
    'confIntervalScallop';...
    'confIntervalBG';...
    'radiusExtn';...
    'radiusConstrictionFactor';...
    'numDiscretizationBins';...
    'numRadBins';...
    'numThetaBins';...
    %'featureMatCaps';...
    'centerWt';...
    'radiusWt';...
    'distScallopThreshold';...
    'notes';...
    'filename'}; 

%% Loading files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[~,~,filename] = dirr(dirname,'\.mat\>','name');

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numFiles = length(filename);
numFields = length(outputFields);
outFile = 'results.csv';
 
fid = fopen( outFile, 'w' );
for fieldI=1:numFields
    fprintf( fid, '%s,',outputFields{fieldI} );
end
fprintf(fid,'\n');

%% Writing values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for fileI=1:numFiles
    currFile = load(filename{fileI});
    fprintf('Working on file %s ...',filename{fileI});
    
    for fieldI=1:numFields
        fieldVal = getFieldData( outputFields{fieldI}, currFile );        
        fprintf(fid,'%s,',fieldVal);
    end  
    fprintf(fid,'%s,',filename{fileI});
    fprintf(fid,'\n');
    fprintf('done\n');
end

fclose(fid);
end

%% Getting field data function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fieldVal = getFieldData( currField, currFile )

if isfield( currFile, 'visualAttnData' )
    if isfield( currFile.visualAttnData.finalResults, currField ) || isfield( currFile.visualAttnData.params, currField )
        if isfield( currFile.visualAttnData.finalResults, currField )
            if isnumeric(  currFile.visualAttnData.finalResults.(currField) )
                fieldVal = num2str( currFile.visualAttnData.finalResults.(currField) );
            else
                fieldVal = currFile.visualAttnData.finalResults.(currField);
            end
        else
            if isnumeric(  currFile.visualAttnData.params.(currField) )
                fieldVal = num2str( currFile.visualAttnData.params.(currField) );
            else
                fieldVal = currFile.visualAttnData.params.(currField);
            end
        end
    else
        fieldVal = '';
    end
else
    fieldVal = '';
end

clear currFile;

end









