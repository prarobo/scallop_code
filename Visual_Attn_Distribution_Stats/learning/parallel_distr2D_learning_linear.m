function [ distributionData, scallopInfo, params ] = parallel_distr2D_learning_linear( params, fileInfo, groundTruth )
%read_scallop_pixel_test Reads scallop pixels from test data set

%% Initialization
numImages = params.numImages;
foldername = fileInfo.foldername;
filename = fileInfo.filename;
   
dataPoint = cell(numImages,1);

% if matlabpool('size') == 0
%     matlabpool open local 7
% end

%% 2D Feature Maps of Scallops
parfor imageI=1:numImages    
    if groundTruth(imageI).numScallops ~= 0
        currFilename = fullfile( foldername, filename{imageI} );
        dataPoint{imageI} = parallelImageProcessing( groundTruth(imageI), currFilename, params, imageI );
    end
end

%     matlabpool close

%% Writing Feature Attributes and Saving Scallop Information to CSV file
fid = fopen( params.attrFile, 'w' );
fclose(fid);
fid = fopen( params.scallopInfoFile, 'w' );
fclose(fid);

for imageI=1:numImages    
    if groundTruth(imageI).numScallops ~= 0
        writeAttrCSV_learning_linear( params, dataPoint{imageI}, imageI );
    end
end
[scallopInfo, params] = writeScallopInfo_learning( params, fileInfo, groundTruth );

distributionData.dataPoint = dataPoint;

end

%% Parallel function discretization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ currDataPointCum ] = parallelImageProcessing( currGroundTruth, currFilename, params, imageI )

numImages = params.numImages;
currImage = imread( currFilename );

%% Feature Channels

if params.globalAdjustOn
    currImage = imadjust( currImage, stretchlim(currImage) );
end
currGrayImage = rgb2gray( currImage );

numScallops = currGroundTruth.numScallops;
currDataPointCum = cell(numScallops, 1);

for scallopI = 1:numScallops
    fprintf('Computing image discretization %d of %d, scallop %d of %d ...', imageI, numImages, scallopI, numScallops);
    
    centerX = currGroundTruth.loc(scallopI, 1);
    centerY = currGroundTruth.loc(scallopI, 2);
    radius = currGroundTruth.loc(scallopI, 3);
    
    %% Distributions of pixels
    
    currDataPoint.grayMap = bin2DScallop_linear(currGrayImage,...
        centerX,...
        centerY,...
        radius,...
        params);
    
    currDataPointCum{scallopI} = currDataPoint;
    fprintf('done\n');
end
end
