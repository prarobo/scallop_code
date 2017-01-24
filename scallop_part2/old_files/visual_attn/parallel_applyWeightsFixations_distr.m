function [ visualAttnOutData ] = parallel_applyWeightsFixations_distr( visualAttnInData, numFixations, saveMapsFile )
%APPLYWEIGHTSFIXATIONSEFF Apply weights and compute fixations efficient

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

visualAttnOutData = visualAttnInData;
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

foldername = visualAttnOutData.fileInfo.foldername;
filename = visualAttnOutData.fileInfo.filename;

if matlabpool('size') == 0
    matlabpool open local 8
end

parfor imageIndex=1:numImages
    imageFile = sprintf('%s/%s',foldername, filename{imageIndex});
    currImage = imread(imageFile);
    currImgVect = initializeImage(currImage);
    
    [currSalMap, currSalData] = applyWeights( currImgVect, gCM, gFM,...
        cmWeightStat, fmWeightStat, imageIndex, numImages );
    
    [currFixations, currFixationsFixed, currFixationsVar,...
        currSalienceVal, currSalienceLoc] = ...
        computeFixations( currSalMap, currSalData, permanentInhibit,...
        numFixations, imageIndex, numImages);
    
    %     saveSalMap = genvarname(sprintf('sal%d%dMap%d',cmWeightStat, fmWeightStat,imageIndex));
    %     eval([saveSalMap '= currSalMap;']);
    %     if ~exist( saveMapsFile, 'file' )
    %         save( saveMapsFile, saveSalMap);
    %     else
    %         save( saveMapsFile, saveSalMap, '-append');
    %     end
    %     clear sal*Map* ;
    
    fixations{imageIndex} = currFixations{1};
    fixationsFixed(imageIndex) = currFixationsFixed;
    fixationsVar(imageIndex) = currFixationsVar;
    salienceVal{imageIndex} = currSalienceVal{1};
    salienceLoc{imageIndex} = currSalienceLoc{1};    
end

% matlabpool close

visualAttnOutData.fixationData.fixations = fixations;
visualAttnOutData.fixationData.fixationsFixed = fixationsFixed;
visualAttnOutData.fixationData.fixationsVar = fixationsVar;
visualAttnOutData.fixationData.salienceVal = salienceVal;
visualAttnOutData.fixationData.salienceLoc = salienceLoc;

end
