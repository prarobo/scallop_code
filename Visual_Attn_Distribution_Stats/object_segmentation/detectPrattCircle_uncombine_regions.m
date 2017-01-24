function [circleList] = detectPrattCircle_uncombine_regions(origImage, bwImage, varargin)
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
    % imshow(currImage);
    
    [rowI, colI] = find( currImage );
    [circleList(numRegI,1), circleList(numRegI,2), circleList(numRegI,3), ~] = circfit(colI,rowI);

end

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



