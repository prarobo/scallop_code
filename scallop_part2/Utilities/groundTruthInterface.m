%% Environment setup
clc; clearvars;
addpath('HelperFunctions/','DisplayFunctions/');
dataDirectory = '~/Linux_Workspaces/Dataset/new_mission_select_images';
imageExtension = 'ppm';
groundTruthFile = 'groundTruth.mat';

%% Reading images
filenameData = dir(sprintf('%s/*.%s', dataDirectory, imageExtension));
filenameData = {filenameData.name}';
numImagesInFolder = length(filenameData);

numImages = 30;
filenameData = filenameData(1:numImages);

%% Interactive crop rect
objectCirc = cell(numImages,1);
maxObjects = 10;

imageI = 1;
while (imageI<=numImages) 
    currImage = imread(fullfile(dataDirectory, filenameData{imageI}));
    rectList = zeros(maxObjects, 4);
    
    for objI = 1:maxObjects
        % Crop interface
        fprintf('Object %d ...\n', objI);
        [~, currRect] = imcrop(currImage);
        currRect
        
        % Checking if a valid ellipse is input
        if isempty(currRect)
            close all;
            if objI ~= 1
                rectList = rectList(1:objI-1,:);
                [outCirc, confirmValue] = displayObjectCircles(currImage, rectList);
                if ~confirmValue
                    imageI = imageI-1;
                    break;
                else
                    objectCirc{imageI} = outCirc;
                    break;
                end
            else
                rectList = [];
                break;
            end
        else
            rectList(objI,:) = currRect;
        end
    end
    imageI = imageI+1;
end

%% Saving results
groundTruth.objRect = objectCirc;
save(groundTruthFile, 'groundTruth');
