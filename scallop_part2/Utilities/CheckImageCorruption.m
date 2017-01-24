%% About
% Used to check if images in a folder are corrupt

%% Initialization
clc; clearvars;
% imageFolder='/home/prasanna/Linux_Workspaces/Scallops/Missions/110708_Scallop_DvoraRun/comb_mission_images_unsmooth';
imageFolder='/home/prasanna/Linux_Workspaces/Dataset/new_mission_images';
imageFolderOriginal = {'/home/prasanna/Linux_Workspaces/Scallops/Missions/110708_Scallop_DvoraRun/201107082054',...
                       '/home/prasanna/Linux_Workspaces/Scallops/Missions/110708_Scallop_DvoraRun/201107082241',...
                       '/home/prasanna/Linux_Workspaces/Scallops/Missions/110708_Scallop_DvoraRun/201107082300',...
                       '/home/prasanna/Linux_Workspaces/Scallops/Missions/110708_Scallop_DvoraRun/201107082321',...
                       '/home/prasanna/Linux_Workspaces/Scallops/Missions/110708_Scallop_DvoraRun/201107082340'};
tempFolder = 'tempFolder';
fileExtn = '.jpg';

%% Get all files from folder
fileList = dir(imageFolder);
filenames = {fileList.name};
numFiles = length(filenames);
fileIndex = true(1,numFiles);

for i=1:numFiles
    [~, ~, currExtn] = fileparts(filenames{i});
    fileIndex(i) = strcmp(fileExtn,currExtn);
end

filenames = filenames(fileIndex);

%% Checking for image corruption

numFiles = length(filenames);
corruptedFileIndex = false(1,numFiles);

for i=1:numFiles
    fprintf('Image %d ...\n',i);
    try
        imread(fullfile(imageFolder,filenames{i}));
    catch
        corruptedFileIndex(i) = true;
    end
end

%% Results
numCorruptedFiles = sum(corruptedFileIndex);
corruptedFilenames = filenames(corruptedFileIndex);

%% Saving original versions of corrupted files to a folder
mkdir(tempFolder);
numSourceFolders = length(imageFolderOriginal);

for i=1:numCorruptedFiles
    srcFile = '';
    for j=1:numSourceFolders
        if exist(fullfile(imageFolderOriginal{j},corruptedFilenames{i}),'file')
            srcFile = fullfile(imageFolderOriginal{j},corruptedFilenames{i});
        else
            continue;
        end
    end
     
    if strcmp(srcFile,'')
        error('Corrupted file not found in originals');
    end
    
    destFile = fullfile(tempFolder,corruptedFilenames{i});
    copyfile(srcFile,destFile);
end

        