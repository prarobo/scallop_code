function [ params, scallopHOG ] = scallopLearningHOGCompute( params, groundTruth )
%SCALLOPHOGCOMPUTE Computes the HOG descriptor for each scallop

%% Initialize
hogWindowSize = params.hogWindow + 2*params.hogPadWidth;
imageWidth = params.imageSize(2);
imageHeight = params.imageSize(1);
numScallops = params.numScallops;
params.hogDescriptorLength = (((params.hogWindow/8)-1)^2)*9*4;

hogDes = cell(numScallops, 1);
hogAvailable = true(numScallops, 1);

%% Main loop
for scallopI = 1:numScallops
    fprintf('Processing scallop HOG %d of %d ...\n', scallopI, numScallops);
    
    % Scallop information
    filename = groundTruth.ImageName{scallopI};
    filepath = fullfile(params.imageFolder, filename);
    currImage = rgb2gray(imread(filepath));
    currScallopX = round(groundTruth.X(scallopI));
    currScallopY = round(groundTruth.Y(scallopI));
    cropRadius = round(groundTruth.radius(scallopI) * params.hogScallopCropRadiusMultiplier);
    
    % Bounding box
    bb = computeBB(currScallopX, currScallopY, 2*cropRadius, 2*cropRadius, imageWidth, imageHeight);
    bbSize = bb(3)*bb(4);
    
    % Checking if the bounding box is truncated to retain consistent
    % centered scallops for HOG
    if bbSize < (2*cropRadius+1)^2
        hogAvailable(scallopI) = false;
    else
        % Cropping, enhancing and resizing to HOG dimensions
        cropImage = imcrop(currImage, bb);
        if params.hogLocalEnhance
            cropImage = imadjust(cropImage, stretchlim(cropImage));
        end
        resizeImage = imresize(cropImage, [hogWindowSize hogWindowSize]);
        
        % HOG
        hogDes{scallopI} = single(getHOGDescriptor(resizeImage));
    end
end
        
%% Output
scallopHOG.hogAvailable = hogAvailable;
scallopHOG.hogDes = hogDes;

end

