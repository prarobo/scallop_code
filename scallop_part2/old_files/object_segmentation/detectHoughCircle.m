function [circList] = detectHoughCircle(origImage, bwImage, varargin)
% dist is the diatance between cells in the hough space of circle centers
% thresh define low and high thresholds for the canny edge detector

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% addpath('houghcoins');
interRadInterval = 2;

switch nargin
    case 2
        samplingInterval = 20;
        radLimits = [20 30];
    case 3
        samplingInterval = varargin{1};
        radLimits = [20 30];
    case 4
        samplingInterval = varargin{1};
        switch numel(varargin{2}) 
            case 1            
                radLimits = [0 varargin{2}];
            case 2
                radLimits = varargin{2};
            otherwise
                error('Bashing my head in the rocks! radius limits incompatible in function detectCircle');
        end
    otherwise
        error('Bloody bonkers, incompatible arguments in detectCircle');
end

% smoothFilter = fspecial('average',[3,3]);

if radLimits(1) < 0 || radLimits(2) > 50
    error('Unacceptable radius sizes found in rad limits in the function detectCircle');
end
    
%% Detecting Circles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% smoothImg = workImage;
% % smoothImg = imfilter(workImg, smoothFilter);
% % figure;imshow(smoothImg);
% 
% edgeImg = edge(rgb2gray(smoothImg), 'sobel');
% % figure; imshow(edgeImg);
% 
% borderImg = imclearborder(edgeImg);
% % figure; imshow(borderImg);
% 
% cleanImg = bwmorph(borderImg, 'clean');
% % figure; imshow(cleanImg);
% 
% dilateImg = imdilate(cleanImg, strel('disk', 3) );
% % figure; imshow(dilateImg);
% 
% cleanImg = bwareaopen(dilateImg, 200 );
% % figure; imshow(cleanImg);
% 
% processImg = cleanImg;

processImg = bwImage;

%radii of the coins to be detected
rbv = radLimits(1):interRadInterval:radLimits(2);

%x,y coordinates of centers to consider
xbv = 1:samplingInterval:size(processImg, 2);
ybv = 1:samplingInterval:size(processImg, 1);

%himg has the hough transform image
processImg = hough_circle(processImg, xbv, ybv, rbv);

%final image with circles marked
[circList, circImage] = mark_circles( origImage, processImg, rbv);
%imshow(circImage);

subplot(131)
imshow(origImage);

subplot(132);
imshow(circImage);

subplot(133);
imshow(bwImage);

end