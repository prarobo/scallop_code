% Environment Variables and Clean up
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
close all
clearvars

addpath(genpath('~/Linux_Workspaces/SaliencyToolbox'));
% addpath('visual_attn');
% addpath('object_segmentation');
% addpath('object_segmentation/houghcoins');
% addpath('object_segmentation/CircFit');
% addpath('distribution_2D');
% addpath('statistics');
% addpath('classifier');
% addpath('visualization');
addpath( genpath('.') );

imagesDataDir='/home/prasanna/Linux_Workspaces/Visual_Attention_Data/Images_All';
% visualAttnFile = sprintf('%s/Test_images/visualAttnData.mat',imagesDataDir);
visualAttnFile = sprintf('visualAttnData.mat');
% imageFolder = sprintf('%s/Test_images/comb_mission_images',imagesDataDir );
imageFolder = sprintf('%s/Test_images/scallop_only_set',imagesDataDir );
% imageFolder = sprintf('%s/Test_images/scallop_only_set_unsmoothed',imagesDataDir );
% imageFolder = sprintf('%s/Test_images/tiny_set',imagesDataDir );
% imageFolder = sprintf('%s/Test_images/201107082054',imagesDataDir );
weightsFile = sprintf('%s/Learning_images/saliencyWeights.mat',imagesDataDir);
saliencyMapsFile = sprintf('%s/Test_images/saliencyMaps.mat',imagesDataDir);
timerFile = sprintf('%s/Test_images/timer.mat',imagesDataDir);
% distributionFile = sprintf('%s/Learning_images/scallopDistribution.mat',imagesDataDir);
distributionFile = sprintf('/home/prasanna/Linux_Workspaces/Matlab_linux_new/Scallop Stats/results_archives/scallopGaussianProcess_5_20_noimadjust.mat');
groundTruthFile = sprintf('%s/Test_images/110708_Scallop_DvoraRun_Sizing.csv', imagesDataDir);

programTime = tic;

if( exist(visualAttnFile,'file') )
    load(visualAttnFile);
end

% if matlabpool('size') == 0
%     matlabpool open local 8
% end

% delete(visualAttnFile);

%% Load learning weights
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ext = exist( weightsFile, 'file' );
if ext==0
%     preComputed=0;
    error('No precomputed saliency weights found, quitting\n');
else
%     preComputed=1;
    fprintf('Precomputed saliency weights found\n');
end

% load(weightsFile, 'gFM', 'gCM');
load(weightsFile, 'scallopData');
visualAttnData.params.gFM = scallopData.gFM;
visualAttnData.params.gCM = scallopData.gCM;
clear scallopData;

%% Read Images
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if( ~any( strcmp( fieldnames(visualAttnData), 'fileInfo' ) ) )
    fprintf('Reading test images ...\n');
    numStartImage = 1;
    numSubsetImages = 1299;
    visualAttnData = readImages_distr(imageFolder, visualAttnData, numStartImage, numSubsetImages);
    fprintf('done\n');
    save( visualAttnFile, 'visualAttnData' );

else
    fprintf('Yipee! Test images file information found\n');
end

numImages = visualAttnData.params.numImages;

%% Loading Scallop Ground Truth Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if( ~any( strcmp( fieldnames(visualAttnData), 'statData' ) ) )
    fprintf('Computing stat data ...\n');
    ext = exist( groundTruthFile, 'file' );
    if ext==0
        error('Ground truth file not found, quitting\n');
    else
        fprintf('Computing ground truth ...\n');
        visualAttnData = readGroundTruth(visualAttnData, groundTruthFile);
        save( visualAttnFile, 'visualAttnData' );                
    end
else
    fprintf('Precomputed stat data found\n');
end

%% Top down fixations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcTime = tic;

if( ~any( strcmp( fieldnames(visualAttnData), 'fixationData' ) ) )

fprintf('Applying weights and Computing fixations for top-down maps ...\n');
visualAttnData.params.permanentInhibit = true;
visualAttnData.params.cmWeightStat = true;
visualAttnData.params.fmWeightStat = true;
numFixations = 10;
% fixationType = 'ground';
fixationType = 'visual';

% delete(sprintf('%s/Test_images/saliencyMaps.mat',imagesDataDir));

visualAttnData = parallel_applyWeightsFixations_distr_groundSwitch( visualAttnData, numFixations, saliencyMapsFile, fixationType );
save(visualAttnFile, 'visualAttnData');

else
    fprintf('I have it! Fixation information\n');
end

timeStr.fixation = toc(funcTime);

%% Segment Objects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcTime = tic;
if( ~any( strcmp( fieldnames(visualAttnData), 'segmentData' ) ) )

fprintf('Segment objects ...\n');
fixationWindowSize = [270 270];
numSegments = 10;
clearGraphBorders = false;
storeProcessData = true;

visualAttnData ...
    = parallel_segmentObjects_graphcut_skel_processDataStorageSwitch( visualAttnData, fixationWindowSize, numSegments, storeProcessData );
save( visualAttnFile, 'visualAttnData' );
else
    fprintf('I have it! Segmentation information\n');
end

timeStr.segment = toc(funcTime);

%% Loading Scallop Distribution Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ext = exist( distributionFile, 'file' );
if ext==0
%     preComputed=0;
    error('No precomputed scallop distributions found, quitting\n');
else
%     preComputed=1;
    fprintf('Precomputed scallop distributions found\n');
end

scallopDistr = load(distributionFile);
scallopDistribution.params = scallopDistr.scallopDistribution.params;
scallopDistribution.scallopDataPoint = scallopDistr.scallopDistribution.scallopDataPoint;
scallopDistribution.arrayFeatureMaps = scallopDistr.scallopDistribution.arrayFeatureMaps;
scallopDistribution.stddevFeatureMaps = scallopDistr.scallopDistribution.stddevFeatureMaps;
clear scallopDistr;

%% Scallop Distribution Confidence Intervals and Calculations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcTime = tic;
confIntervalScallop = 0.95;
confIntervalBG = 0.5;

if( ~any( strcmp( fieldnames(visualAttnData), 'distributionData' ) ) )

fprintf('Computing confidence interval ...\n');
visualAttnData = distr_2D_confInterval(visualAttnData, scallopDistribution, confIntervalScallop, confIntervalBG);

fprintf('Computing current data distribution ...\n');
discretOn = true;
checkOn = true;
visualAttnData = parallel_distr_2D_compute(visualAttnData, scallopDistribution, discretOn, checkOn);
save( visualAttnFile, 'visualAttnData' );

else
    if( ~any( strcmp( fieldnames(visualAttnData.distributionData), 'dataPointCheck' ) ) )
        
        fprintf('Computing confidence interval ...\n');
        visualAttnData = distr_2D_confInterval(visualAttnData, scallopDistribution, confIntervalScallop, confIntervalBG);

        fprintf('Computing current data distribution ...\n');
        discretOn = false;
        checkOn = true;
        visualAttnData = parallel_distr_2D_compute(visualAttnData, scallopDistribution, discretOn, checkOn);
        save( visualAttnFile, 'visualAttnData' );
    else
        fprintf('I have it! Distribution check information\n');
    end
end

timeStr.distribution = toc(funcTime);

%% Scallop Statistics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

funcTime = tic;

if( ~any( strcmp( fieldnames(visualAttnData.statData), 'detection' ) ) )

fprintf('Computing detection statistics ...\n');
visualAttnData = detectionStats_filtered( visualAttnData );
save( visualAttnFile, 'visualAttnData' );

else
    fprintf('I have it! Detection statistics information\n');
end

timeStr.statistics = toc(funcTime);

%% Scallop Classifier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

funcTime = tic;

if( ~any( strcmp( fieldnames(visualAttnData), 'classData' ) ) )

fprintf('Computing classifier ...\n');
visualAttnData = classifierStats( visualAttnData );
save( visualAttnFile, 'visualAttnData' );

else
    fprintf('I have it! Classifier information\n');
end

timeStr.classifier = toc(funcTime);

%% Consolidated Results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

funcTime = tic;

if( ~any( strcmp( fieldnames(visualAttnData), 'finalResults' ) ) )

fprintf('Computing final results ...\n');
visualAttnData = finalResultsCompute( visualAttnData );
save( visualAttnFile, 'visualAttnData' );

else
    fprintf('I have it! Final results\n');
end

timeStr.classifier = toc(funcTime);


%% Save Timer Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save( timerFile, 'timeStr' );

%% Visualizations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

displayDetectedScallops( visualAttnData );

% displayGroundTruthScallop( visualAttnData );
% 
% displayClassificationStats( visualAttnData );

displayWindowLengths( visualAttnData ); % Display fixation window lengths comparison

displayDetectedScallopErrors( visualAttnData );

displaySegmentationEdgeGraphComparison( visualAttnData, filterData );

load('filterData.mat');
% displayGraphFilter( visualAttnData, filterData );
% displayGraphFilterSteps( visualAttnData, filterData );
displayGraphSkelSteps( visualAttnData, filterData );

saveResultsCSV( 'Results current' );





