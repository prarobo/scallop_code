function [ visualAttnOutData ] = applyWeightsFixations_distr( visualAttnInData, saveMapsFile )
%APPLYWEIGHTSFIXATIONSEFF Apply weights and compute fixations efficient

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

visualAttnOutData = visualAttnInData;
numFixations = 10;
numImages = visualAttnOutData.params.numImages;
gCM = visualAttnOutData.params.gCM;
gFM = visualAttnOutData.params.gFM;
cmWeightStat = visualAttnOutData.params.cmWeightStat;
fmWeightStat = visualAttnOutData.params.fmWeightStat;
permanentInhibit = visualAttnOutData.params.permanentInhibit;

visualAttnOutData.params.numFixations = numFixations;
visualAttnOutData.fileInfo.saliencyMapsFile = saveMapsFile;

visualAttnOutData.fixationData.fixations = cell(1,numImages);
visualAttnOutData.fixationData.fixationsFixed = zeros(numImages,1);
visualAttnOutData.fixationData.fixationsVar = zeros(numImages,1);
visualAttnOutData.fixationData.salienceVal = cell(1,numImages);
visualAttnOutData.fixationData.salienceLoc = cell(1,numImages);


for imageIndex=1:numImages
    imageFile = sprintf('%s/%s',visualAttnOutData.fileInfo.foldername, visualAttnOutData.fileInfo.filename{imageIndex});
    currImage = imread(imageFile);
    currImgVect = initializeImage(currImage);
    
    [currSalMap, currSalData] = applyWeights( currImgVect, gCM, gFM,...
        cmWeightStat, fmWeightStat, imageIndex, numImages );
    
    [currFixations, currFixationsFixed, currFixationsVar,...
        currSalienceVal, currSalienceLoc] = ...
        computeFixations( currSalMap, currSalData, permanentInhibit,...
        numFixations, imageIndex, numImages);
    
    saveSalMap = genvarname(sprintf('sal%d%dMap%d',cmWeightStat, fmWeightStat,imageIndex));
    eval([saveSalMap '= currSalMap;']);
    if ~exist( saveMapsFile, 'file' )
        save( saveMapsFile, saveSalMap);
    else
        save( saveMapsFile, saveSalMap, '-append');
    end
    clear sal*Map* ;
    
    visualAttnOutData.fixationData.fixations{imageIndex} = currFixations{1};
    visualAttnOutData.fixationData.fixationsFixed(imageIndex) = currFixationsFixed;
    visualAttnOutData.fixationData.fixationsVar(imageIndex) = currFixationsVar;
    visualAttnOutData.fixationData.salienceVal{imageIndex} = currSalienceVal{1};
    visualAttnOutData.fixationData.salienceLoc{imageIndex} = currSalienceLoc{1};    
end

end