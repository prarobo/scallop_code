%% About
% This version of code is ported from scallop work to improve upon the
% existing results. We propose to do the classification based on HOG
% descriptor instead of template matching. This was further
% extended to add a 2 layer segmentation stage to decrease false positives.

%% Initialization
clc; clearvars;

addpath('HelperFunctions/','Utilities/','DisplayFunctions/', 'Guis/')

imagesDataDir='/home/prasanna/Linux_Workspaces/Dataset';
imageFolder = sprintf('%s/comb_mission_images',imagesDataDir );
imageFolderUnsmooth = sprintf('%s/comb_mission_images_unsmooth',imagesDataDir );
groundTruthFile = sprintf('%s/110708_Scallop_DvoraRun_Sizing.csv', imagesDataDir);
scallop2LearningFile = 'scallop2Learning.mat';
scallop2TestingFile = 'scallop2Testing.mat';
% scallopPrevResultsFile = 'MatFiles/scallop1_img8049.mat';
scallopPrevResultsFile = 'MatFiles/scallop1_img1299.mat';

% assert(strcmp(pwd,'/home/prasanna/Linux_Workspaces/Matlab_linux_new/scallop_part2'));

if( exist(scallop2TestingFile,'file') )
    load(scallop2TestingFile);
else
    scallopTesting.params.imagesDataDir = imagesDataDir;
    scallopTesting.params.imageFolder = imageFolder;
    scallopTesting.params.imageFolderUnsmooth = imageFolderUnsmooth;
    scallopTesting.params.groundTruthFile = groundTruthFile;
    scallopTesting.params.scallop2LearningFile = scallop2LearningFile;
    scallopTesting.params.scallop2TestingFile = scallop2TestingFile;
    scallopTesting.params.scallopPrevResultsFile = scallopPrevResultsFile;
end

global numPoolWorkers poolobj
numPoolWorkers = 4;

% delete(scallop2TestingFile);

%% Load scallop previous work results and learning results
% Previous results
if( ~any( strcmp( fieldnames(scallopTesting), 'prevParams' ) ) )
    if exist(scallopPrevResultsFile, 'file')
        fprintf('Loading previous scallop results ...\n');
        scallopTesting = loadScallopPrevResults(scallopTesting, scallopPrevResultsFile);
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

%% HOG descriptors
if( ~any( strcmp( fieldnames(scallopTesting), 'objectHOG' ) ) )
    fprintf('Computing scallop HOG descriptors...\n');   
    
    % Getting parameters from learning
    scallopTesting.params.imageSize = scallopLearning.params.imageSize;
    scallopTesting.params.hogWindow = scallopLearning.params.hogWindow;
    scallopTesting.params.hogPadWidth = scallopLearning.params.hogPadWidth;
    scallopTesting.params.hogScallopCropRadiusMultiplier = scallopLearning.params.hogScallopCropRadiusMultiplier;
    scallopTesting.params.hogLocalEnhance = scallopLearning.params.hogLocalEnhance;
    
    [scallopTesting.params, scallopTesting.objectHOG] = scallopTestingHOGCompute(scallopTesting.params, ...
                                                                                    scallopTesting.fileInfo, ...
                                                                                    scallopTesting.fixationData, ...
                                                                                    scallopTesting.segmentData);
    save( scallop2TestingFile, 'scallopTesting' );
else
    fprintf('Precomputed scallop HOG found\n');
end

%% HOG comparison
if( ~any( strcmp( fieldnames(scallopTesting), 'hogComparison' ) ) )
    fprintf('Comparing HOG descriptors...\n');   
    
    % Getting parameters from learning    
    [scallopTesting.params, scallopTesting.hogComparison] = scallopTestingHOGCompare(scallopTesting.params, ...
                                                                                    scallopTesting.segmentData, ...
                                                                                    scallopTesting.objectHOG, ...
                                                                                    scallopLearning);
    save( scallop2TestingFile, 'scallopTesting' );
else
    fprintf('Precomputed scallop HOG found\n');
end

%% Two region graphcut
% if( ~any( strcmp( fieldnames(scallopTesting), 'resegmentData' ) ) )
%     fprintf('Resegmentation ...\n');
%     [scallopTesting.params, scallopTesting.resegmentData] = scallopTestingResegment(scallopTesting.params, ...
%                                                                                     scallopTesting.fileInfo, ...
%                                                                                     scallopTesting.segmentData.objectList, ...
%                                                                                     scallopLearning.params, ...
%                                                                                     scallopLearning.groundTruth, ...
%                                                                                     scallopLearning.scallopPosition);
%     save( scallop2TestingFile, 'scallopTesting' );
% else
%     fprintf('Resegmentation data found');
% end

%% Template matching
if( ~any( strcmp( fieldnames(scallopTesting), 'templateData' ) ) )
    fprintf('Template matching ...\n');
    scallopTesting.params.resizeFactor=1;
    [scallopTesting.params, scallopTesting.templateData] = scallopTestingTemplate(scallopTesting.params, ...
                                                                                    scallopTesting.fileInfo, ...
                                                                                    scallopTesting.segmentData.objectList, ...
                                                                                    scallopLearning.params, ...
                                                                                    scallopLearning.groundTruth, ...
                                                                                    scallopLearning.scallopPosition);
    save( scallop2TestingFile, 'scallopTesting' );
else
    fprintf('Resegmentation data found');
end

%% Template Classification
if( ~any( strcmp( fieldnames(scallopTesting.classData), 'finalNumbers' ) ) )
    fprintf('Classification...\n');   
    
    [scallopTesting.params, scallopTesting.classData] = scallopTestingClassifier_layer4_hog(scallopTesting);
    save( scallop2TestingFile, 'scallopTesting' );
else
    fprintf('Precomputed scallop classifier found\n');
end

%% Visualization
displayScallopClassifierThreshold(scallopTesting);
displayScallopClassifierThresholdLayer4(scallopTesting);
displayScallopClassifierThresholdLayer4_hog(scallopTesting);

displayResegmentStats(scallopLearning.resegmentData);
displayResegmentStats(scallopTesting.resegmentData);

guiScallopLearningResegment(scallop2LearningFile);
guiScallopTestingResegment(scallop2LearningFile, scallop2TestingFile);

displayTemplateStats(scallopLearning.templateData);
displayTemplateStats(scallopTesting.templateData);


