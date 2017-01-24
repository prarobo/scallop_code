%% Environment Variables and Clean up
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
close all
clearvars

addpath(genpath('~/Linux_Workspaces/SaliencyToolbox'));
addpath( genpath('.') );

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
    scallopDistr.params.numRadBins = 5;
    scallopDistr.params.numThetaBins = 20;
    scallopDistr.params.numDiscretizationBins = 50;
    scallopDistr.params.featureMatCaps = {'GradMag','GradDir'};
    scallopDistr.params.featureMatSmall = {'gradmag','graddir'};
    %     scallopDistr.params.featureMatCaps = {'Hue', 'Sat', 'Val','GradMag','GradDir'};
    %     scallopDistr.params.featureMatSmall = {'hue', 'sat', 'val','gradmag','graddir'};
    %     scallopDistr.params.featureMatCaps = {'Red', 'Green', 'Blue', 'Hue', 'Sat', 'Val','Lum','Aloc','Bloc','GradMag','GradDir'};
    %     scallopDistr.params.featureMatSmall = {'red', 'green', 'blue', 'hue', 'sat', 'val','lum','aloc','bloc','gradmag','graddir'};
    scallopDistr.params.radiusExtn = 0;
    scallopDistr.params.radiusConstrictionFactor = 1.25;
    scallopDistr.params.attrFile = learnAttrFile;

    [scallopDistr.distributionData, scallopDistr.scallopInfo, scallopDistr.params] ...
        = parallel_distr2D_learning( scallopDistr.params, scallopDistr.fileInfo, scallopDistr.groundTruth );
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
    [scallopDistr.clusterData, scallopDistr.params] = cluster_learning( scallopDistr.params );
    save( learnDistributionFile, 'scallopDistr' );
    fprintf('done\n');
else
    fprintf('I have it! Cluster information\n');
end

timeStr.cluster = toc(funcTime);


%% Save Timer Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save( timerFile, 'timeStr' );

%% Visualizations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

displayClusterScallops_gradImage( scallopDistr.params, scallopDistr.clusterData, scallopDistr.scallopInfo, scallopDistr.fileInfo );





