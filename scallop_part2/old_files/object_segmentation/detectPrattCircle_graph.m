function [circleList, imgFilterSteps] = detectPrattCircle_graph(origImage, bwImage, labelImage, imgFilterSteps )
% dist is the diatance between cells in the hough space of circle centers
% thresh define low and high thresholds for the canny edge detector

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % addpath('houghcoins');
% interRadInterval = 2;
% 
% switch nargin
%     case 2
%         samplingInterval = 20;
%         radLimits = [20 30];
%     case 3
%         samplingInterval = varargin{1};
%         radLimits = [20 30];
%     case 4
%         samplingInterval = varargin{1};
%         switch numel(varargin{2}) 
%             case 1            
%                 radLimits = [0 varargin{2}];
%             case 2
%                 radLimits = varargin{2};
%             otherwise
%                 error('Bashing my head in the rocks! radius limits incompatible in function detectPrattCircle');
%         end
%     otherwise
%         error('Bloody bonkers, incompatible arguments in detectPrattCircle');
% end
% 
% % smoothFilter = fspecial('average',[3,3]);
% 
% if radLimits(1) < 0 || radLimits(2) > 50
%     error('Unacceptable radius sizes found in rad limits in the function detectPrattCircle');
% end

connComp = bwconncomp( bwImage );
% circleList = zeros(2^connComp.NumObjects-1, 3);
circleList = zeros(connComp.NumObjects, 3);
skelFilterImage = false( size(bwImage) );
imgFilterSteps.graphFilter = cell( size(circleList,1), 1 );

%% Iteration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for numRegI =1:size(circleList,1)
    
%% Get different combination of regions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % currRegCombination = dec2bin(numRegI, connComp.NumObjects);
    numZeros = connComp.NumObjects - numRegI;
    currRegCombination = sprintf('%d', 10^(numRegI-1));
    for zeroI=1:numZeros
        currRegCombination = sprintf('0%s', currRegCombination);
    end
    
    currImage = regionCombinations( connComp, currRegCombination );
    % figure;imshow(currImage);
    
        % Area Filter
    regPoints = labelImage(currImage);
    maskArea = numel(regPoints);
    maxReg = mode(regPoints);
    maxRegArea = sum( regPoints == maxReg );
    
    % Rejecting circles not belonging to a region
    if maxRegArea < 10
        continue;
    end
    
    % Principle region
    regionMask = (labelImage == maxReg);
    % figure; imshow(regionMask);
    
    regionMask = bwperim( regionMask );
    boundaryMask = bwperim( true( size( regionMask ) ) );
    regionMask = regionMask & (~boundaryMask);
    regionIntersect = regionMask & currImage;
    % figure; imshow(regionIntersect);
    
    if sum(regionIntersect(:)) < 10
        continue;
    end
    
    skelFilterImage = skelFilterImage | regionIntersect;
    % imgFilterSteps(numRegI).regionIntersect = regionIntersect;    
    
    [rowI, colI] = find( currImage );
    [circleList(numRegI,1), circleList(numRegI,2), circleList(numRegI,3), ~] = circfit(colI,rowI);    
    
    imgFilterSteps.graphFilter{numRegI}.regionMask = regionMask;
    imgFilterSteps.graphFilter{numRegI}.regionIntersect = regionIntersect;    
end

circleList = removeSkippedCircles( circleList );
imgFilterSteps.skelFilterImage = skelFilterImage;

% subplot(131)
% imshow(origImage);
% 
% subplot(132);
% imshow(circImage);
% 
% subplot(133);
% imshow(bwImage);

end

%% Region Combination Image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function currImage = regionCombinations( connComp, currRegCombination )
    currImage = false(connComp.ImageSize);
    for regI = 1:connComp.NumObjects
        if( str2double(currRegCombination(regI) ) )
            currImage((connComp.PixelIdxList{regI})) = true;
        end
    end
end

%% Remove Skipped Circles function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function skippedCircleList = removeSkippedCircles( circleList )

numCirc = size(circleList,1);
circleAccept = true( numCirc, 1 );

for circI = 1:numCirc
    if circleList(circI,3) == 0
        circleAccept(circI) = false;
    end
end

numCirc = sum(circleAccept(:));
numCols  = size(circleList,2);
skippedCircleList = zeros(numCirc,numCols);

if numCirc ~= 0
    for colI = 1:numCols
        currCol = circleList(:,colI);
        skippedCircleList(:,colI) = currCol(circleAccept);
    end
end

end















