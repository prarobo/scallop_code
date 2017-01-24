%% About
% Scallop part 2 learning file. This file processes new data set. It tries
% to apply the previously developed techniques on the new dataset for
% comparison.

%% Initialization
clc; clearvars;

addpath('HelperFunctions/','Utilities/','DisplayFunctions/','Guis/')

imagesDataDir='/home/prasanna/Linux_Workspaces/Dataset';
imageFolder = sprintf('%s/comb_mission_images',imagesDataDir );
imageFolderUnsmooth = sprintf('%s/comb_mission_images_unsmooth',imagesDataDir );
groundTruthFile = sprintf('%s/110708_Scallop_DvoraRun_Sizing.csv', imagesDataDir);
scallop2LearningFile = 'scallop2Learning.mat';

% assert(strcmp(pwd,'/home/prasanna/Linux_Workspaces/Matlab_linux_new/scallop_part2'));

if( exist(scallop2LearningFile,'file') )
    load(scallop2LearningFile);
else
    scallopLearning.params.imagesDataDir = imagesDataDir;
    scallopLearning.params.imageFolder = imageFolder;
    scallopLearning.params.imageFolderUnsmooth = imageFolderUnsmooth;
    scallopLearning.params.groundTruthFile = groundTruthFile;
    scallopLearning.params.scallop2LearningFile = scallop2LearningFile;
end

global numPoolWorkers poolobj;
numPoolWorkers = 4;

% delete(scallop2LearningFile);

%% Loading Ground Truth
if( ~any( strcmp( fieldnames(scallopLearning), 'groundTruth' ) ) )  
    if exist( groundTruthFile, 'file' )
        fprintf('Computing ground truth ...\n');       
        [scallopLearning.params, scallopLearning.groundTruth] = readGroundTruthScallop(scallopLearning.params, ...
                                                                                    groundTruthFile);        
        save( scallop2LearningFile, 'scallopLearning' );                
    else
        error('Ground truth file not found, quitting\n');
    end
else
    fprintf('Precomputed ground truth data found\n');
end

%% Segregate scallops based on position
if( ~any( strcmp( fieldnames(scallopLearning), 'scallopPosition' ) ) )
    fprintf('Computing scallop position segregation...\n');   
    scallopLearning.params.segregragationWindow = 40;
    [scallopLearning.params, scallopLearning.scallopPosition] = segregateScallopsAdv(scallopLearning.params, ...
                                                                                scallopLearning.groundTruth);
    save( scallop2LearningFile, 'scallopLearning' );
else
    fprintf('Precomputed scallop segregation found\n');
end

%% HOG scallop-wise descriptors
if( ~any( strcmp( fieldnames(scallopLearning), 'scallopHOG' ) ) )
    fprintf('Computing scallop HOG descriptors...\n');   
    scallopLearning.params.hogWindow = 24;
    scallopLearning.params.hogPadWidth = 1;
    scallopLearning.params.hogScallopCropRadiusMultiplier = 1.5;
    scallopLearning.params.hogLocalEnhance = true;
    [scallopLearning.params, scallopLearning.scallopHOG] = scallopLearningHOGCompute(scallopLearning.params, ...
                                                                                    scallopLearning.groundTruth);
    save( scallop2LearningFile, 'scallopLearning' );
else
    fprintf('Precomputed scallop HOG found\n');
end

%% HOG quandrant-wise descriptors
% if( ~any( strcmp( fieldnames(scallopLearning), 'quadrantHOG' ) ) )
%     fprintf('Computing scallop HOG descriptors...\n');   
%     [scallopLearning.params, scallopLearning.quadrantHOG] = quadrantLearningHOGCompute(scallopLearning.params, ...
%                                                                                         scallopLearning.scallopPosition, ...
%                                                                                         scallopLearning.scallopHOG);
%     save( scallop2LearningFile, 'scallopLearning' );
% else
%     fprintf('Precomputed scallop HOG found\n');
% end

%% 2-layer segmentation on unsmoothed scallops
% if( ~any( strcmp( fieldnames(scallopLearning), 'resegmentData' ) ) )
%     fprintf('Resegmentation ...\n');
%     scallopLearning.params.resegmentWindowSize = 100;
%     scallopLearning.params.resegmentFGRadius = 10;
%     scallopLearning.params.bgRadiusPercent = 0.3;
%     scallopLearning.params.resegRadiusExtnPercent = 0.25;
%     scallopLearning.params.horzBoundary = 80;
%     scallopLearning.params.vertBoundary = 60;
%     scallopLearning.params.resegApprecPercent = 1.5;
%     scallopLearning.params.useSmoothImages = false;
%     scallopLearning.params.scallopMaskThicknessPercent = 0.15;
%     scallopLearning.params.crescentAngle = 60;
%     scallopLearning.params.centerRadiusPercent = 1;
%     [scallopLearning.params, scallopLearning.resegmentData] = scallopLearningResegment(scallopLearning.params, ...
%                                                                                         scallopLearning.groundTruth, ...
%                                                                                         scallopLearning.scallopPosition);                                                                                   
%     save( scallop2LearningFile, 'scallopLearning' );
% else
%     fprintf('Resegmentation data found\n');
% end

%% Template matching
if( ~any( strcmp( fieldnames(scallopLearning), 'templateData' ) ) )
    fprintf('Template matching ...\n');
    scallopLearning.params.templateRadiusExtnPercent = 0.25;
    scallopLearning.params.horzBoundary = 80;
    scallopLearning.params.vertBoundary = 60;
    scallopLearning.params.useSmoothImages = false;
    [scallopLearning.params, scallopLearning.templateData] = scallopLearningTemplate(scallopLearning.params, ...
                                                                                        scallopLearning.groundTruth, ...
                                                                                        scallopLearning.scallopPosition);                                                                                   
    save( scallop2LearningFile, 'scallopLearning' );
else
    fprintf('Resegmentation data found\n');
end


%% Visualizations
imagesc(scallopLearning.scallopPosition.numbers);
displayResegmentStats(scallopLearning.resegmentData);
guiScallopLearningResegment(scallop2LearningFile);

displayTemplateStats(scallopLearning.templateData);


