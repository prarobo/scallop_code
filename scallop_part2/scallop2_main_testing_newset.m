%% About
% Scallop part 2 testing file. This file processes new data set. It tries
% to apply the previously developed techniques on the new dataset for
% comparison.

%% Initialization
clc; clearvars;

addpath('HelperFunctions/','Utilities/','DisplayFunctions/','Guis/', 'PrevPipeline/')

imagesDataDir='/home/prasanna/Linux_Workspaces/Dataset';
imageFolder = sprintf('%s/new_mission_select_images',imagesDataDir );
% imageFolderUnsmooth = sprintf('%s/new_mission_images',imagesDataDir );
% groundTruthFile = sprintf('%s/110708_Scallop_DvoraRun_Sizing.csv', imagesDataDir);
groundTruthFile = 'groundTruth.mat';
scallop2TestingFile = 'scallop2Testing.mat';
scallop2LearningFile = 'scallop2Learning.mat';
scallopPrevResultsFile = 'MatFiles/scallop1_img8049.mat';
saliencyMapsFile = sprintf('%s/Test_images/saliencyMaps.mat',imagesDataDir);
lookupFile = 'scallopLookupTable.mat';
scallopDistrFile = 'scallopDistr.mat';
attrFile_testing = 'attrData_testing.csv';
objInfoFile = 'objectInfo_testing.csv';

% assert(strcmp(pwd,'/home/prasanna/Linux_Workspaces/Matlab_linux_new/scallop_part2'));

if( exist(scallop2TestingFile,'file') )
    load(scallop2TestingFile);
else
    scallopTesting.params.imagesDataDir = imagesDataDir;
    scallopTesting.params.imageFolder = imageFolder;
    scallopTesting.params.groundTruthFile = groundTruthFile;
    scallopTesting.params.scallop2LearningFile = scallop2LearningFile;
    scallopTesting.params.scallop2TestingFile = scallop2TestingFile;
    scallopTesting.params.lookupFile = lookupFile;
    scallopTesting.params.scallopDistrFile = scallopDistrFile;
end

global numPoolWorkers poolobj;
numPoolWorkers = 4;

% delete(scallop2TestingFile);

%% Load scallop learning
% Previous results
if( ~any( strcmp( fieldnames(scallopTesting), 'prevParams' ) ) )
    if exist(scallopPrevResultsFile, 'file')
        fprintf('Loading previous scallop results ...\n');
        scallopTesting = loadScallopPrevResultsBarebones(scallopTesting, scallopPrevResultsFile);
        save(scallop2TestingFile, 'scallopTesting');
    else
        error('Previous scallop results not found');
    end
else
    fprintf('Previous scallops results found\n');
end

% Learning data
if exist(scallop2LearningFile, 'file')
    fprintf('Loading scallop learning ...\n');
    load(scallop2LearningFile);
else
    error('Previous scallop results not found');
end

%% Loading Ground Truth
if( ~any( strcmp( fieldnames(scallopTesting), 'groundTruth' ) ) )  
    if exist( groundTruthFile, 'file' )
        fprintf('Computing ground truth ...\n');       

        numImages = 30;
        imageSize = [600 800]; %[960 1280]; 
        
        [scallopTesting.params, scallopTesting.groundTruth, scallopTesting.fileInfo] = readGroundTruthScallopMat(scallopTesting.params, ...
                                                                                            groundTruthFile, imageFolder, ...
                                                                                            numImages, imageSize);        
        save( scallop2TestingFile, 'scallopTesting' );                
    else
        error('Ground truth file not found, quitting\n');
    end
else
    fprintf('Precomputed ground truth data found\n');
end

scallop2LearningFile = 'scallop2Learning.mat';
scallop2TestingFile = 'scallop2Testing.mat';

%% Visual Attention
if( ~any( strcmp( fieldnames(scallopTesting), 'fixationData' ) ) )
    
    fprintf('Applying weights and Computing fixations for top-down maps ...\n');
    scallopTesting.params.permanentInhibit = true;
    scallopTesting.params.cmWeightStat = true;
    scallopTesting.params.fmWeightStat = true;
    numFixations = 10;
    % fixationType = 'ground';
    fixationType = 'visual';
    
    % delete(sprintf('%s/Test_images/saliencyMaps.mat',imagesDataDir));
    % Fixations are of the form [row,col] and not (x,y)
    scallopTesting = parallel_applyWeightsFixations_distr_groundSwitch( scallopTesting, numFixations, saliencyMapsFile, fixationType );
    save(scallop2TestingFile, 'scallopTesting');
    
else
    fprintf('I have it! Fixation information\n');
end

%% Segmentation
if( ~any( strcmp( fieldnames(scallopTesting), 'segmentData' ) ) )
    
    fprintf('Segment objects ...\n');
    
    scallopTesting.params.numSegments = 10;
    scallopTesting.params.fixationWindowSize = [270 270];
    scallopTesting.params.contourLengthErrorPercent = 0.3;
    scallopTesting.params.minContourLengthPercent = 0.2;
    scallopTesting.params.contourGraphAreaThresholdPercent = 0.6;
    scallopTesting.params.donutGraphThicknessPercent = 0.2;
    
    scallopTesting.params.minAllowableScallopRadius = 10;
    scallopTesting.params.maxAllowableScallopRadius = 45;
    
    clearGraphBorders = false;
    storeProcessData = false;
    parallelOn = true;
    % segmentType = 'ground';
    segmentType = 'graph';
    errorInject = false;
    errorVal = [5 0.10];
    
    if storeProcessData
        [scallopTesting.segmentData, scallopTesting.graphData] ...
            = segmentObjects_lookup_groundSwitch_errorInj( scallopTesting.fixationData, ...
            scallopTesting.groundTruth, ...
            scallopTesting.params, ...
            scallopTesting.fileInfo, ...
            storeProcessData, parallelOn, segmentType, errorInject, errorVal );
    else
        [scallopTesting.segmentData, ~] ...
            = segmentObjects_lookup_groundSwitch_errorInj( scallopTesting.fixationData, ...
            scallopTesting.groundTruth, ...
            scallopTesting.params, ...
            scallopTesting.fileInfo, ...
            storeProcessData, parallelOn, segmentType, errorInject, errorVal );
    end
    save( scallop2TestingFile, 'scallopTesting' );
else
    fprintf('I have it! Segmentation information\n');
end

%% Loading Scallop Confidence Interval Data and Radius Distributions
ext = exist( lookupFile, 'file' );
if ext==0
    % preComputed=0;
    error('No precomputed scallop lookup found, quitting\n');
else
    % preComputed=1;
    fprintf('Precomputed scallop lookup found\n');
    if( any( strcmp( fieldnames(scallopTesting), 'distributionData' ) ) )
        if( ~any( strcmp( fieldnames(scallopTesting.distributionData), 'dataPointCheck' ) ) )
            fprintf('Loading scallop lookup table ...');
            load(lookupFile);
            confIntervalData = lookupFile.confIntervalData;
            clear lookupFile;
            fprintf('done\n');
        end
    else
        fprintf('Loading scallop lookup table ...');
        load(lookupFile);
        confIntervalData = scallopLookup.confIntervalData;
        scallopLookupParams = scallopLookup.params;
        clear scallopLookup
        fprintf('done\n');
    end
end

ext = exist( scallopDistrFile, 'file' );
if ext==0
    % preComputed=0;
    error('No precomputed scallop radius distribution found, quitting\n');
else
    % preComputed=1;
    fprintf('Precomputed scallop radius distribution found\n');
    load(scallopDistrFile);
    origRadiusDistr = scallopDistr.radiusData.distrFit;
    clear scallopDistr
end

%% Scallop Distribution Check
if( ~any( strcmp( fieldnames(scallopTesting), 'distributionData' ) ) )
    fprintf( 'Computing data distribution discretization and checking');
    discretOn = true;
    checkOn = true;
    writeOn = true;
    scallopTesting.params.attrFile_testing = attrFile_testing;
    scallopTesting.params.objInfoFile = objInfoFile;
    
    [scallopTesting.distributionData, scallopTesting.params] ...
        =  parallel_distr2D_testing_linear_metadata( scallopTesting.params, ...
        scallopTesting.fileInfo, ...
        scallopTesting.fixationData, ...
        scallopTesting.segmentData, ...
        confIntervalData, ...
        scallopLookupParams, ...
        discretOn, checkOn, writeOn, ...
        origRadiusDistr );
    
    save( scallop2TestingFile, 'scallopTesting' );
    % clear confIntervalData
    
elseif ( ~any( strcmp( fieldnames(scallopTesting.distributionData), 'dataPointCheck' ) ) )
    fprintf( 'Computing data distribution checking');
    discretOn = false;
    checkOn = true;
    writeOn = true;
    scallopTesting.params.attrFile_testing = attrFile_testing;
    scallopTesting.params.objInfoFile = objInfoFile;    
    
    [scallopTesting.distributionData, scallopTesting.params] ...
        =  parallel_distr2D_testing_linear_metadata( scallopTesting.params, ...
        scallopTesting.fileInfo, ...
        scallopTesting.fixationData, ...
        scallopTesting.segmentData, ...
        confIntervalData, ...
        scallopLookupParams, ...
        discretOn, checkOn, writeOn, ...
        radiusDistr, ...
        scallopTesting.distributionData );
    
    save( scallop2TestingFile, 'scallopTesting' );
    % clear confIntervalData
else
    fprintf('I have it! Distribution check information\n');
end

%% Scallop Statistics
if( ~any( strcmp( fieldnames(scallopTesting), 'statData' ) ) )

fprintf('Computing detection statistics ...\n');
[scallopTesting.statData.detectionStats, scallopTesting.statData.categoryStats, scallopTesting.params] ...
    = detectionStats_testing_scallopid( scallopTesting.params, scallopTesting.groundTruth.imageWise, scallopTesting.distributionData);
save( scallop2TestingFile, 'scallopTesting' );

else
    fprintf('I have it! Detection statistics information\n');
end

timeStr.statistics = toc(funcTime);

%% Scallop Classifier and Results
if( ~any( strcmp( fieldnames(scallopTesting), 'classData' ) ) )    
    fprintf('Computing classifier ...\n');
    [scallopTesting.classData, scallopTesting.statData.detectionStats, scallopTesting.params] ...
        = classifierStats_testing_boundary( scallopTesting.params, ...
        scallopTesting.statData, ...
        scallopTesting.distributionData, ...
        scallopTesting.groundTruth.imageWise, ...
        scallopTesting.segmentData, ...
        scallopTesting.fixationData );
    save( scallop2TestingFile, 'scallopTesting' );
else
    fprintf('I have it! Classifier information\n');
end

%% Template matching
if( ~any( strcmp( fieldnames(scallopTesting), 'template2Data' ) ) )
    fprintf('Template matching ...\n');
    scallopLearning.params.useSmoothImages = true;
    scallopTesting.segmentData.objectList = getObjectList(scallopTesting.distributionData.objList);
    scallopTesting.params.templateFolder = '/home/prasanna/Linux_Workspaces/Dataset/comb_mission_images_unsmooth';

    [scallopTesting.params, scallopTesting.template2Data] = scallopTestingTemplate_newset(scallopTesting.params, ...
                                                                                            scallopTesting.fileInfo, ...
                                                                                            scallopTesting.segmentData.objectList, ...
                                                                                            scallopLearning.params, ...
                                                                                            scallopLearning.groundTruth, ...
                                                                                            scallopLearning.scallopPosition);
    save( scallop2TestingFile, 'scallopTesting' );
else
    fprintf('Resegmentation data found');
end

%% Visualizations
displayGroundScallops(scallopTesting, 3); 
displayFixations(scallopTesting, 6);

displayScallopThresholdComparison( scallopTesting );

displayTemplateStats(scallopLearning.templateData);
displayTemplateStats(scallopTesting.template2Data);

displayDetectedScallops_testing( scallopTesting );
