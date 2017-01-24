function [ params, templateData ] = scallopLearningTemplate( params, groundTruth, scallopPosition)
%SCALLOPLEARNINGRESEGMENT Performs a 2-region graphcut segmentation using
%the ground truth data as foreground seeds for graphcut.

%% Initialization
numScallops = params.numScallops;
imageWidth = params.imageSize(2);
imageHeight = params.imageSize(1);
groundTruthX = groundTruth.X;
groundTruthY = groundTruth.Y;
groundTruthRad = groundTruth.radius;
groundTruthImageName = groundTruth.ImageName;
templateRadiusExtnPercent = params.templateRadiusExtnPercent;
horzBoundary = params.horzBoundary;
vertBoundary = params.vertBoundary;

if params.useSmoothImages
    imageFolder = params.imageFolder;
else
    imageFolder = params.imageFolderUnsmooth;
end

templateAvailable = true(numScallops,1);
templateMatchNumbers = cell(numScallops,1);

%% Parallel thread creation
global poolobj numPoolWorkers;
if isempty(poolobj)
    poolobj = parpool(numPoolWorkers);
else
    if poolobj.NumWorkers == 0
        poolobj = parpool(numPoolWorkers);
    end
end
parfor_progress(numScallops);


%% Main loop
parfor scallopI = 1:numScallops
    fprintf('Template matching scallops %d ...\n', scallopI);
    
    % Current scallop information
    currX = round(groundTruthX(scallopI));
    currY = round(groundTruthY(scallopI));
    currRadius = round(groundTruthRad(scallopI));
    currImageName = groundTruthImageName{scallopI};
    filename = sprintf('%s/%s', imageFolder, currImageName);
    currImage = imread(filename);
    extnTestRad = round(currRadius*(1+templateRadiusExtnPercent));

    % Skipping boundary scallops
    if isBoundaryScallop(currX, currY, horzBoundary, vertBoundary, imageWidth, imageHeight)
        templateAvailable(scallopI) = false;
        continue;
    end
    
    % Compute BB and crop image
    bb = computeBB(currX, currY, 2*extnTestRad, 2*extnTestRad, imageWidth, imageHeight);
    cropImage = imcrop(currImage, bb);    
    
    % Scallop template
    [templateAvailable(scallopI), templateMeanScallop, templateStddevScallop] ...
                                        = generateScallopTemplate(currX, currY,currRadius, scallopPosition, groundTruth, ...
                                                                    templateRadiusExtnPercent, imageFolder);
    
                                                            
   if templateAvailable(scallopI)

       % Match template
       templateMatchNumbers{scallopI} = computeTemplateMatchValue(cropImage, templateMeanScallop, templateStddevScallop);
       
       % Display
       % displayTemplateMatch(cropImage, templateScallop);
   end
   parfor_progress;
end
parfor_progress(0);


%% Output
templateData.templateAvailable = templateAvailable;
templateData.templateMatchNumbers = templateMatchNumbers;

end

%% Function to display segmentation results
function displayTemplateMatch(cropImage, templateScallop)    
end




