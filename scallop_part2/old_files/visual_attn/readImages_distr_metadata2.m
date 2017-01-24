function [params, fileInfo] = readImages_distr_metadata2( imgFolder, imageMetaDataFile, params, varargin )
%READIMAGES reads images and stacks them into an images structure

%% Initialization

switch nargin
    case 3
        argNumStartImage = 1;
        argNumImages = 0;
    case 4
        argNumStartImage = varargin{1};
        argNumImages = 0;
    case 5
        argNumStartImage = varargin{1};
        argNumImages = varargin{2};
    otherwise
        error('Bloody bonkers! Incompatible arguments in readImages_distr');
end

%% Checking for the existence of image folder and metadata file

f_exist = exist(imgFolder, 'file');
if f_exist==0
    error('Images path does not exist');
end

f_exist = exist(imageMetaDataFile, 'file');
if f_exist==0
    error('Images metadata file does not exist');
end

%% Reading Images Meta Data

load( imageMetaDataFile );

%% Read images list

fprintf('Reading images ...\n');
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

%% Read images and data into structure

params.startImage = numStartImage;
params.numImages = numImages;
fileInfo.filename = cell(numImages,1);
fileInfo.foldername = imgFolder;

for i=1:numImages
    fileInfo.filename{i} = f_images(i).name;
end

fileInfo.pitch = camera.pitch;
fileInfo.altitude = camera.altitude;
fileInfo.imageWidth = 2*(camera.altitude-1.3*tan(deg2rad(-camera.pitch)))*tan( degtorad(49.92/2) );

%% Images Size

origImage = imread(fullfile(imgFolder, f_images(1).name));
params.imageSize = size(origImage);

