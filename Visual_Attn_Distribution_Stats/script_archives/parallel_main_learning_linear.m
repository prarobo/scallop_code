%% Environment Variables and Clean up
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
close all
clearvars

addpath(genpath('~/Linux_Workspaces/SaliencyToolbox'));
addpath( genpath('~/Linux_Workspaces/Matlab_linux_new/Visual_Attn_Distribution_Stats') );

imagesDataDir='/home/prasanna/Linux_Workspaces/Visual_Attention_Data/Images_All';
% visualAttnFile = sprintf('%s/Test_images/visualAttnData.mat',imagesDataDir);
% visualAttnFile = sprintf('visualAttnData.mat');
% imageFolder = sprintf('%s/Test_images/comb_mission_images',imagesDataDir );
% imageFolder = sprintf('%s/Test_images/scallop_only_set_unsmoothed',imagesDataDir );
% imageFolder = sprintf('%s/Test_images/tiny_set',imagesDataDir );
% imageFolder = sprintf('%s/Test_images/201107082054',imagesDataDir );
% weightsFile = sprintf('%s/Learning_images/saliencyWeights.mat',imagesDataDir);
% saliencyMapsFile = sprintf('%s/Test_images/saliencyMaps.mat',imagesDataDir);
timerFile = sprintf('%s/Test_images/timer.mat',imagesDataDir);
% distributionFile = sprintf('%s/Learning_images/scallopDistribution.mat',imagesDataDir);
% distributionFile = sprintf('/home/prasanna/Linux_Workspaces/Matlab_linux_new/Scallop Stats/results_archives/scallopGaussianProcess_5_20_noimadjust.mat');
groundTruthFile = sprintf('%s/Test_images/110708_Scallop_DvoraRun_Sizing.csv', imagesDataDir);
learnImagesFolder = sprintf('%s/Test_images/comb_mission_images',imagesDataDir );
% learnImagesFolder = sprintf('%s/Test_images/scallop_only_set',imagesDataDir );
learnDistributionFile = 'scallopDistr.mat';
learnAttrFile = 'attrData_learning.csv';
learnScallopInfoFile = 'scallopInfo_learning.csv';

programTime = tic;

% delete(resultsFile);
% delete(distributionFile);
% delete(visualAttnFile);

if( exist(learnDistributionFile,'file') )
    load(learnDistributionFile);
end

% if matlabpool('size') == 0
%     matlabpool open local 8
% end

%% Read Images and Ground Truth Scallops
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('scallopDistr', 'var')
    fprintf('Reading learning images ...\n');
    numStartImage = 1;
    numSubsetImages = 0;
    [scallopDistr.params, scallopDistr.fileInfo] = readImages_learning(learnImagesFolder, numStartImage, numSubsetImages);
    scallopDistr.groundTruth = readGroundTruth_learning(scallopDistr.params, scallopDistr.fileInfo, groundTruthFile);
    save( learnDistributionFile, 'scallopDistr' );    
else
    fprintf('Yipee! Learn images file information found\n');
end

numImages = scallopDistr.params.numImages;

%% Scallop 2D Distribution 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcTime = tic;

if( ~any( strcmp( fieldnames(scallopDistr), 'distributionData' ) ) )
    
    fprintf('Computing current data distribution ...\n');
    scallopDistr.params.resizeImageSize = 11;
    scallopDistr.params.numDiscretizationBins = 10;
    scallopDistr.params.radiusExtn = 0;
    scallopDistr.params.radiusConstrictionFactor = 1.4;
    scallopDistr.params.attrFile = learnAttrFile;
    scallopDistr.params.scallopInfoFile = learnScallopInfoFile;
    scallopDistr.params.globalAdjustOn = false;
    scallopDistr.params.localAdjustOn = true;

    [scallopDistr.distributionData, scallopDistr.scallopInfo, scallopDistr.params] ...
        = parallel_distr2D_learning_linear( scallopDistr.params, scallopDistr.fileInfo, scallopDistr.groundTruth );
    save( learnDistributionFile, 'scallopDistr' );  
else
    fprintf('I have it! Distribution check information\n');
end

timeStr.distribution = toc(funcTime);

%% Scallop Attribute Clustering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcTime = tic;

if( ~any( strcmp( fieldnames(scallopDistr), 'clusterData' ) ) )
    
    fprintf('Computing clusters ...');
    [scallopDistr.clusterData, scallopDistr.params] = cluster_learning_linear( scallopDistr.params );
    save( learnDistributionFile, 'scallopDistr' );
    fprintf('done\n');
else
    fprintf('I have it! Cluster information\n');
end

timeStr.cluster = toc(funcTime);

%% Scallop Quadrant Analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

funcTime = tic;

if( ~any( strcmp( fieldnames(scallopDistr), 'quadrantData' ) ) )
    numWidthQuadrants = 8;
    numHeightQuadrants = 6;
    
    fprintf('Computing quadrant based clusters ...');
    scallopDistr.params.quadrantCircleRad = 4;
    scallopDistr.params.quadrantCircleCenter = [6 6];
    scallopDistr.params.quadrantNumTopVarPoints = 10;
    scallopDistr.params.quadrantNumBottomVarPoints = 10;
    [scallopDistr.quadrantData, scallopDistr.params] = quadrant_learning_linear( scallopDistr.params, numWidthQuadrants, numHeightQuadrants );
    save( learnDistributionFile, 'scallopDistr' );
    fprintf('done\n');
else
    fprintf('I have it! Quadrant information\n');
end

timeStr.quadrant = toc(funcTime);


%% Save Timer Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save( timerFile, 'timeStr' );

%% Visualizations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

annulusOn = true;
% displayClusterScallops_adjustImage( scallopDistr.params, scallopDistr.clusterData, ...
%                             scallopDistr.scallopInfo, scallopDistr.fileInfo, annulusOn );
displayClusterScallops_gradImage( scallopDistr.params, scallopDistr.clusterData, ...
                            scallopDistr.scallopInfo, scallopDistr.fileInfo, annulusOn );
                        
displayQuadrantResults( scallopDistr.params, scallopDistr.quadrantData.quadrantID );                        

displayQuadrantResults_linear( scallopDistr.params, scallopDistr.quadrantData.quadrantID ); 

displayQuadrantResults_clusters( scallopDistr.params, scallopDistr.quadrantData.quadrantID );                        

displayQuadrantResults_clusters_selected( scallopDistr.params, scallopDistr.quadrantData.quadrantID );                        

