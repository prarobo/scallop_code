function [ scallopInfo, params ] = writeScallopInfo_learning( params, fileInfo, groundTruth )
%WRITESCALLOPINFO_LEARNING Extracting scallop info from ground truth

%% Initialize
scallopImageCount = [groundTruth.numScallops];
numScallops = sum( scallopImageCount(:) );
params.numScallops = numScallops;

scallopInfo.loc = zeros(numScallops, 3);
scallopInfo.filename = cell(numScallops, 1);
scallopInfo.rect = zeros(numScallops, 4);
scallopInfo.diff = zeros(numScallops, 2);

%% Extracting Data

index = 0;
for imageI = 1:params.numImages
    for scallopI = 1:scallopImageCount(imageI)
        index = index + 1;
        scallopInfo.loc(index,:) = groundTruth(imageI).loc(scallopI,:);
        scallopInfo.filename{index} = fileInfo.filename{imageI};
        [scallopInfo.rect(index,:), scallopInfo.diff(index,:)] = calcRect( params, groundTruth(imageI).loc(scallopI,:) );
    end
end

%% Write to File

writeToFile( scallopInfo, params );

end

%% calcRect Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [rect, diff] = calcRect( params, currScallopLoc )
    rect = zeros(1,4);
    diff = zeros(1,2);
    currScallopLoc = round( currScallopLoc );
    radius = params.radiusConstrictionFactor * currScallopLoc(3);
    
    rect(1) = max( currScallopLoc(1) - radius, 1 );
    rect(2) = max( currScallopLoc(2) - radius, 1 );
    rect(3) = min( currScallopLoc(1) + radius, params.imageSize(2) ) - rect(1) + 1;
    rect(4) = min( currScallopLoc(2) + radius, params.imageSize(1) ) - rect(2) + 1;
    
    if currScallopLoc(1) - radius < 1
        diff(1) = abs( currScallopLoc(1) ) + 1;
    end
    
    if currScallopLoc(2) - radius < 1
        diff(2) = abs( currScallopLoc(2) ) + 1;
    end
end

%% Writing to File
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function writeToFile( scallopInfo, params )
fid = fopen( params.scallopInfoFile, 'a' );

for scallopI = 1:params.numScallops
    
    % Scallop
    fprintf(fid,'%d,',scallopInfo.loc(scallopI, 1) );
    fprintf(fid,'%d,',scallopInfo.loc(scallopI, 2) );
    fprintf(fid,'%d,',scallopInfo.loc(scallopI, 3) );
    fprintf(fid,'%s,',scallopInfo.filename{scallopI} );
    fprintf(fid,'%d,',scallopInfo.rect(scallopI, 1) );
    fprintf(fid,'%d,',scallopInfo.rect(scallopI, 2) );
    fprintf(fid,'%d,',scallopInfo.rect(scallopI, 3) );
    fprintf(fid,'%d,',scallopInfo.rect(scallopI, 4) );
    fprintf(fid,'%d,',scallopInfo.diff(scallopI, 1) );
    fprintf(fid,'%d\n',scallopInfo.diff(scallopI, 2) );
end

fclose(fid);
end


