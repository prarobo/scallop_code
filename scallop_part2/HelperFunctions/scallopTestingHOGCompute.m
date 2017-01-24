function [ params, objectHOG ] = scallopTestingHOGCompute( params, fileInfo, fixationData, segmentData)
%SCALLOPHOGCOMPUTE Computes the HOG descriptor for circular object

%% Initialize
hogWindowSize = params.hogWindow + 2*params.hogPadWidth;
imageWidth = params.imageSize(2);
imageHeight = params.imageSize(1);
numImages = params.numImages;

hogDes = cell(numImages, 1);
hogAvailable = cell(numImages, 1);

%% Main loop
for imageI = 1:numImages
    fprintf('Processing Image HOG %d of %d ...\n', imageI, numImages);
    numObjects = size(segmentData.circList{imageI},1);
    hogDes{imageI} = cell(numObjects,1);
    hogAvailable{imageI} = true(numObjects,1);
    filepath = fullfile(fileInfo.foldername, fileInfo.filename{imageI});
    currImage = rgb2gray(imread(filepath));

    for objI = 1:numObjects
        % Object information
        currObjectX = round(segmentData.circList{imageI}(objI,1));
        currObjectY = round(segmentData.circList{imageI}(objI,2));
        cropRadius = round(segmentData.circList{imageI}(objI,3) * params.hogScallopCropRadiusMultiplier);
        
        % Bounding box
        bb = computeBB(currObjectX, currObjectY, 2*cropRadius, 2*cropRadius, imageWidth, imageHeight);
        bbSize = bb(3)*bb(4);
        
        % Checking if the bounding box is truncated to retain consistent
        % centered scallops for HOG
        if bbSize < (2*cropRadius+1)^2
            hogAvailable{imageI}(objI) = false;
        else
            % Cropping, enhancing and resizing to HOG dimensions
            cropImage = imcrop(currImage, bb);
            if params.hogLocalEnhance
                cropImage = imadjust(cropImage, stretchlim(cropImage));
            end
            resizeImage = imresize(cropImage, [hogWindowSize hogWindowSize]);
            
            % HOG
            hogDes{imageI}{objI} = single(getHOGDescriptor(resizeImage));
        end
    end
end
        
%% Output
objectHOG.hogAvailable = hogAvailable;
objectHOG.hogDes = hogDes;

end

