function [params, fileInfo] = readImages_learning( imgFolder, varargin )
%READIMAGES reads images and stacks them into an images structure

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch nargin
    case 2
        argNumStartImage = 1;
        argNumImages = 0;
    case 3
        argNumStartImage = varargin{1};
        argNumImages = 0;
    case 4
        argNumStartImage = varargin{1};
        argNumImages = varargin{2};
    otherwise
        error('Bloody bonkers! Incompatible arguments in readImages_distr');
end

%% Checking for the existence of image folder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

f_exist = exist(imgFolder);
if f_exist==0
    error('Images path does not exist');
end

%% Read images list
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%fprintf('Reading images ...\n');
f_images=dir(fullfile(imgFolder,'*.jpg'));
if isempty(f_images)
    f_images=dir(fullfile(imgFolder,'*.JPG'));
end
if isempty(f_images)
    f_images=dir(fullfile(imgFolder,'*.png'));
end
if isempty(f_images)
    f_images=dir(fullfile(imgFolder,'*.PNG'));
end
if isempty(f_images)
    error('No image files with given extensions found');
end

numImages = length(f_images);
numStartImage = argNumStartImage;
if argNumImages ~= 0 && argNumImages < numImages
    numImages = argNumImages;
end

%% Read images into structure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

params.numImages = numImages;
fileInfo.filename = cell(numImages,1);
fileInfo.foldername = imgFolder;

for i=numStartImage:numStartImage+numImages-1
    fileInfo.filename{i} = f_images(i).name;
end

%% Images Size
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

origImage = imread(fullfile(imgFolder, f_images(1).name));
params.imageSize = size(origImage);

