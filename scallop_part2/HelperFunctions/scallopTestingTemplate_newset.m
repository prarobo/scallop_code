function [ params, templateData ] = scallopTestingTemplate_newset( params, fileInfo, objectList, ...
                                                              learningParams,  groundTruth, scallopPosition)
%SCALLOPLEARNINGRESEGMENT Performs a 2-region graphcut segmentation using
%the ground truth data as foreground seeds for graphcut.

%% Initialization
params.numOjects = size(objectList,1);
params.imageWidth = learningParams.imageSize(2);
params.imageHeight = learningParams.imageSize(1);
params.templateRadiusExtnPercent = learningParams.templateRadiusExtnPercent;
params.horzBoundary = learningParams.horzBoundary;
params.vertBoundary = learningParams.vertBoundary;
params.useSmoothImages = learningParams.useSmoothImages;

numObjects = params.numObjects;
imageWidth = params.imageWidth;
imageHeight = params.imageHeight;
templateRadiusExtnPercent = params.templateRadiusExtnPercent;
horzBoundary = params.horzBoundary;
vertBoundary = params.vertBoundary;
imageName = fileInfo.filename;

if params.useSmoothImages
    imageFolder = params.imageFolder;
else
    imageFolder = params.imageFolderUnsmooth;
end

templateAvailable = true(numObjects,1);
templateMatchNumbers = cell(numObjects,1);

%% Parallel thread creation
global poolobj numPoolWorkers;
% if isempty(poolobj)
%     poolobj = parpool(numPoolWorkers);
% else
%     if poolobj.NumWorkers == 0
%         poolobj = parpool(numPoolWorkers);
%     end
% end
% parfor_progress(numOjects);


%% Main loop
for objectI = 1:numObjects
    fprintf('Template matching objects %d ...\n', objectI);
    
    % Current scallop information
    currObject = objectList(objectI,:);
    currX = round(currObject(1));
    currY = round(currObject(2));
    currRadius = round(currObject(3));
    currImageName = imageName{currObject(6)};
    filename = sprintf('%s/%s', imageFolder, currImageName);
    currImage = imresize(imread(filename), params.resizeFactor);
    extnTestRad = round(currRadius*(1+templateRadiusExtnPercent));

    % Skipping boundary scallops
    if isBoundaryScallop(currX, currY, horzBoundary, vertBoundary, imageWidth, imageHeight)
        templateAvailable(objectI) = false;
        continue;
    end
    
    % Compute BB and crop image
    bb = computeBB(currX, currY, 2*extnTestRad, 2*extnTestRad, imageWidth, imageHeight);
    cropImage = imcrop(currImage, bb);    
    
    % Scallop template
    [templateAvailable(objectI), templateMeanScallop, templateStddevScallop] ...
                                        = generateScallopTemplate(currX, currY,currRadius, scallopPosition, groundTruth, ...
                                                                    templateRadiusExtnPercent, params.templateFolder);
    
                                                            
   if templateAvailable(objectI)

       % Match template
       templateMatchNumbers{objectI} = computeTemplateMatchValue(cropImage, templateMeanScallop, templateStddevScallop);
       
       % Display
       % displayTemplateMatch(cropImage, templateScallop);
   end
%    parfor_progress;
end
% parfor_progress(0);


%% Output
templateData.templateAvailable = templateAvailable;
templateData.templateMatchNumbers = templateMatchNumbers;

end

%% Function to display segmentation results
function displayTemplateMatch(cropImage, templateScallop)    
end




