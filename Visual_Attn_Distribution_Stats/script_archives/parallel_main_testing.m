%% Environment Variables and Clean up
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
% scallopTestingFile = sprintf('%s/Test_images/scallopTesting.mat',imagesDataDir);
scallopTestingFile = sprintf('scallopTesting.mat');
% imageFolder = sprintf('%s/Test_images/comb_mission_images',imagesDataDir );
imageFolder = sprintf('%s/Test_images/scallop_only_set',imagesDataDir );
% imageFolder = sprintf('%s/Test_images/scallop_only_set_unsmoothed',imagesDataDir );
% imageFolder = sprintf('%s/Test_images/tiny_set',imagesDataDir );
% imageFolder = sprintf('%s/Test_images/201107082054',imagesDataDir );
weightsFile = sprintf('%s/Learning_images/saliencyWeights.mat',imagesDataDir);
saliencyMapsFile = sprintf('%s/Test_images/saliencyMaps.mat',imagesDataDir);
timerFile = 'timer.mat';
% distributionFile = sprintf('%s/Learning_images/scallopDistribution.mat',imagesDataDir);
% distributionFile = sprintf('/home/prasanna/Linux_Workspaces/Matlab_linux_new/Scallop Stats/results_archives/scallopGaussianProcess_5_20_noimadjust.mat');
lookupFile = sprintf('scallopLookupTable.mat');
groundTruthFile = sprintf('%s/Test_images/110708_Scallop_DvoraRun_Sizing.csv', imagesDataDir);
attrFile_testing = 'attrData_testing.csv';
objInfoFile = 'objectInfo_testing.csv';

programTime = tic;

if( exist(scallopTestingFile,'file') )
    load(scallopTestingFile);
end

% if matlabpool('size') == 0
%     matlabpool open local 8
% end

% delete(scallopTestingFile);

%% Load learning weights
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ext = exist( weightsFile, 'file' );
if ext==0
    %     preComputed=0;
    error('No precomputed saliency weights found, quitting\n');
else
    %     preComputed=1;
    fprintf('Precomputed saliency weights found\n');
    if ~exist( 'scallopTesting', 'var')
        load(weightsFile, 'scallopData');
        scallopTesting.params.gFM = scallopData.gFM;
        scallopTesting.params.gCM = scallopData.gCM;
        clear scallopData;
    end
end

%% Read Images
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if( ~any( strcmp( fieldnames(scallopTesting), 'fileInfo' ) ) )
    fprintf('Reading test images ...\n');
    numStartImage = 1;
    numSubsetImages = 0;    %1299;
    scallopTesting = readImages_distr(imageFolder, scallopTesting, numStartImage, numSubsetImages);
    save( scallopTestingFile, 'scallopTesting' );

else
    fprintf('Yipee! Test images file information found\n');
end

numImages = scallopTesting.params.numImages;

%% Loading Scallop Ground Truth Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if( ~any( strcmp( fieldnames(scallopTesting), 'statData' ) ) )
    fprintf('Computing stat data ...\n');
    ext = exist( groundTruthFile, 'file' );
    if ext==0
        error('Ground truth file not found, quitting\n');
    else
        fprintf('Computing ground truth ...\n');
        scallopTesting = readGroundTruth(scallopTesting, groundTruthFile);
        save( scallopTestingFile, 'scallopTesting' );                
    end
else
    fprintf('Precomputed stat data found\n');
end

%% Top down fixations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcTime = tic;

if( ~any( strcmp( fieldnames(scallopTesting), 'fixationData' ) ) )
    
    fprintf('Applying weights and Computing fixations for top-down maps ...\n');
    scallopTesting.params.permanentInhibit = true;
    scallopTesting.params.cmWeightStat = true;
    scallopTesting.params.fmWeightStat = true;
    numFixations = 10;
    fixationType = 'ground';
    % fixationType = 'visual';
    
    % delete(sprintf('%s/Test_images/saliencyMaps.mat',imagesDataDir));
    
    scallopTesting = parallel_applyWeightsFixations_distr_groundSwitch( scallopTesting, numFixations, saliencyMapsFile, fixationType );
    save(scallopTestingFile, 'scallopTesting');
    
else
    fprintf('I have it! Fixation information\n');
end

timeStr.fixation = toc(funcTime);

%% Segment Objects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcTime = tic;
if( ~any( strcmp( fieldnames(scallopTesting), 'segmentData' ) ) )
    
    fprintf('Segment objects ...\n');
    
    scallopTesting.params.numSegments = 10;
    scallopTesting.params.fixationWindowSize = [270 270];    
    scallopTesting.params.contourLengthErrorPercent = 0.3;
    scallopTesting.params.minContourLengthPercent = 0.2;
    scallopTesting.params.contourGraphAreaThresholdPercent = 0.6;
    scallopTesting.params.donutGraphThicknessPercent = 0.2;

    clearGraphBorders = false;
    storeProcessData = false;
    parallelOn = true;
    segmentType = 'ground';
    % segmentType = 'visual';
    
    if storeProcessData
        [scallopTesting.segmentData, scallopTesting.graphData] ...
            = segmentObjects_lookup_groundSwitch( scallopTesting.fixationData, ...
            scallopTesting.statData.groundTruth, ...
            scallopTesting.params, ...
            scallopTesting.fileInfo, ...
            storeProcessData, parallelOn, segmentType );
    else
        [scallopTesting.segmentData, ~] ...
            = segmentObjects_lookup_groundSwitch( scallopTesting.fixationData, ...
            scallopTesting.statData.groundTruth, ...
            scallopTesting.params, ...
            scallopTesting.fileInfo, ...
            storeProcessData, parallelOn, segmentType );
    end
    save( scallopTestingFile, 'scallopTesting' );
else
    fprintf('I have it! Segmentation information\n');
end

timeStr.segment = toc(funcTime);

%% Loading Scallop Lookup Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ext = exist( lookupFile, 'file' );
if ext==0
    % preComputed=0;
    error('No precomputed scallop lookup found, quitting\n');
else
    % preComputed=1;
    fprintf('Precomputed scallop lookup found\n');
    if( ~any( strcmp( fieldnames(scallopTesting), 'confIntervalData' ) ) )
        if ~exist( 'scallopLookup', 'var')
            fprintf('Loading scallop lookup table ...');
            load(lookupFile);
            fprintf('done\n');
        end
    end
end

%% Scallop Distribution Confidence Intervals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcTime = tic;

if( ~any( strcmp( fieldnames(scallopTesting), 'confIntervalData' ) ) )
    scallopTesting.params.confIntervalScallop = 0.95;
    scallopTesting.params.confIntervalHalfWindow = [20 20];
    
    scallopTesting.params.numDiscretizationBins = scallopLookup.params.numDiscretizationBins;
    scallopTesting.params.globalAdjustOn = scallopLookup.params.globalAdjustOn;
    scallopTesting.params.localAdjustOn = scallopLookup.params.localAdjustOn;
    scallopTesting.params.radiusConstrictionFactor = scallopLookup.params.radiusConstrictionFactor;
    scallopTesting.params.resizeImageSize = scallopLookup.params.resizeImageSize;
    scallopTesting.params.quadrantCircleRad = scallopLookup.params.quadrantCircleRad;
    scallopTesting.params.quadrantCircleCenter = scallopLookup.params.quadrantCircleCenter;
    
    fprintf('Computing confidence interval ...\n');
    [scallopTesting.confIntervalData, scallopTesting.params] = lookup_confInterval( scallopTesting.params, scallopLookup );
    save( scallopTestingFile, 'scallopTesting' );
else
    fprintf('I have it! Confidence Interval information\n');
end
timeStr.confInterval = toc(funcTime);

%% Scallop Distribution Check
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

funcTime = tic;

if( ~any( strcmp( fieldnames(scallopTesting), 'distributionData' ) ) )
    fprintf( 'Computing data distribution discretization and checking');
    discretOn = true;
    checkOn = true;
    writeOn = true;
    scallopTesting.params.attrFile_testing = attrFile_testing;
    scallopTesting.params.objInfoFile = objInfoFile;
    
    [scallopTesting.distributionData, scallopTesting.params] ...
        =  parallel_distr2D_testing_linear( scallopTesting.params, ...
        scallopTesting.fileInfo, ...
        scallopTesting.fixationData, ...
        scallopTesting.segmentData, ...
        scallopTesting.confIntervalData, ...
        discretOn, checkOn, writeOn );
    
    save( scallopTestingFile, 'scallopTesting' );
    
elseif ( ~any( strcmp( fieldnames(scallopTesting.distributionData), 'dataPointCheck' ) ) )
    fprintf( 'Computing data distribution checking');
    discretOn = false;
    checkOn = true;
    writeOn = true;
    scallopTesting.params.attrFile_testing = attrFile_testing;
    scallopTesting.params.objInfoFile = objInfoFile;    
    
    [scallopTesting.distributionData, scallopTesting.params] ...
        =  parallel_distr2D_testing_linear( scallopTesting.params, ...
        scallopTesting.fileInfo, ...
        scallopTesting.fixationData, ...
        scallopTesting.segmentData, ...
        scallopTesting.confIntervalData, ...
        discretOn, checkOn, writeOn, ...
        scallopTesting.distributionData );
    
    save( scallopTestingFile, 'scallopTesting' );
else
    fprintf('I have it! Distribution check information\n');
end

timeStr.distribution = toc(funcTime);

%% Scallop Statistics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

funcTime = tic;

if( ~any( strcmp( fieldnames(scallopTesting.statData), 'detectionStats' ) ) )

fprintf('Computing detection statistics ...\n');
[scallopTesting.statData.detectionStats, scallopTesting.statData.categoryStats, scallopTesting.params] ...
    = detectionStats_testing( scallopTesting.params, scallopTesting.statData.groundTruth, scallopTesting.distributionData);
save( scallopTestingFile, 'scallopTesting' );

else
    fprintf('I have it! Detection statistics information\n');
end

timeStr.statistics = toc(funcTime);

%% Scallop Classifier and Results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

funcTime = tic;

if( ~any( strcmp( fieldnames(scallopTesting), 'classData' ) ) )    
    fprintf('Computing classifier ...\n');
    [scallopTesting.classData, scallopTesting.params] = classifierStats_testing( scallopTesting.params, ...
        scallopTesting.statData, ...
        scallopTesting.distributionData, ...
        scallopTesting.segmentData, ...
        scallopTesting.fixationData );
    save( scallopTestingFile, 'scallopTesting' );
else
    fprintf('I have it! Classifier information\n');
end

timeStr.classifier = toc(funcTime);

%% Save Timer Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save( timerFile, 'timeStr' );

%% Visualizations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% displayDetectedScallops( scallopTesting );
% 
% % displayGroundTruthScallop( scallopTesting );
% % 
% % displayClassificationStats( scallopTesting );
% 
% displayWindowLengths( scallopTesting ); % Display fixation window lengths comparison
% 
% displayDetectedScallopErrors( scallopTesting );
% 
% displaySegmentationEdgeGraphComparison( scallopTesting, filterData );
% 
% load('filterData.mat');
% % displayGraphFilter( scallopTesting, filterData );
% % displayGraphFilterSteps( scallopTesting, filterData );
% displayGraphSkelSteps( scallopTesting, filterData );
% 
% saveResultsCSV( 'Results current' );





