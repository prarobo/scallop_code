function [ visualAttnOutData ] = ...
    parallel_applyWeightsFixations_distr_groundSwitch( visualAttnInData, numFixations, saveMapsFile, fixationType )
%APPLYWEIGHTSFIXATIONSEFF Apply weights and compute fixations efficient

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global numPoolWorkers

visualAttnOutData = visualAttnInData;
numImages = visualAttnOutData.params.numImages;
gCM = visualAttnOutData.params.gCM;
gFM = visualAttnOutData.params.gFM;
cmWeightStat = visualAttnOutData.params.cmWeightStat;
fmWeightStat = visualAttnOutData.params.fmWeightStat;
permanentInhibit = visualAttnOutData.params.permanentInhibit;

visualAttnOutData.params.numFixations = numFixations;
visualAttnOutData.fileInfo.saliencyMapsFile = saveMapsFile;
visualAttnOutData.params.fixationType = fixationType;

% fixations = cell(1,numImages);
% fixationsFixed = zeros(numImages,1);
% fixationsVar = zeros(numImages,1);
% salienceVal = cell(1,numImages);
% salienceLoc = cell(1,numImages);

foldername = visualAttnOutData.fileInfo.foldername;
filename = visualAttnOutData.fileInfo.filename;

if strcmp( fixationType, 'visual' )
    if matlabpool('size') == 0
        matlabpool(numPoolWorkers)
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
elseif strcmp( fixationType, 'ground' )
    [fixations, fixationsVar, fixationsFixed, salienceVal, salienceLoc] ...
        = groundTruthFixationtRedirect( visualAttnOutData.statData.groundTruth );
else
     error( 'Unknown fixation type in function %d', mfilename );
end

% matlabpool close

visualAttnOutData.fixationData.fixations = fixations;
visualAttnOutData.fixationData.fixationsFixed = fixationsFixed;
visualAttnOutData.fixationData.fixationsVar = fixationsVar;
visualAttnOutData.fixationData.salienceVal = salienceVal;
visualAttnOutData.fixationData.salienceLoc = salienceLoc;

end

%% Ground truth fixation redirect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [fixations, fixationsVar, fixationsFixed, salienceVal, salienceLoc] = groundTruthFixationtRedirect( groundTruth )

% Initialize
numImages = length(groundTruth);
fixations = cell(numImages, 1);
fixationsVar = [groundTruth.numScallops];
fixationsFixed = true(1,numImages);
salienceVal = cell(numImages, 1);
salienceLoc = cell(numImages, 1);
    
% Redirecting ground truth fixations
for imageI = 1:numImages
    % groundTruthFixations{imageI} = zeros(groundTruth(imageI).numScallops,2);
    fixations{imageI} = groundTruth(imageI).loc(:,1:2);
    fixations{imageI} = circshift( fixations{imageI}, [0 1] );
    salienceVal{imageI} = ones( fixationsVar(imageI), 1 );
    salienceLoc{imageI} = groundTruth(imageI).loc(:,1:2);
end

end
