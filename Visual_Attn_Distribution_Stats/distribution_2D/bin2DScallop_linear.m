function [ currDataPt ] = bin2DScallop_linear( img, centerX, centerY, radius, params )
%BIN2DSCALLOP Discretizes scallops into 2D bins based on polar coordinates

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

radiusConstrictionFactor = params.radiusConstrictionFactor;

switch nargin
    case 5
    otherwise
        error('Holy hell, bad arguments in function %s, fix it boss', mfilename);
end

currDataPt = zeros(params.resizeImageSize);

% persistent shapeInserterWhite;
% if isempty(shapeInserterWhite)
%      shapeInserterWhite = vision.ShapeInserter('Shape','Circles','Fill',true,'FillColor','White','Opacity',1);
% end
% 
% persistent shapeInserterBlack;
% if isempty(shapeInserterBlack)
%      shapeInserterBlack = vision.ShapeInserter('Shape','Circles','Fill',true,'FillColor','Black','Opacity',1);
% end
% 
% if ~(radiusConstrictionFactor > 1 && radiusConstrictionFactor < 2)
%     error('Bloody bullocks! Radius constriction factor is not within 1-2 in function %s', mfilename);
% end
% whiteRadius = radius * radiusConstrictionFactor;
% blackRadius = radius * (1-abs(1-radiusConstrictionFactor));
% 
% circlesWhite = int32([centerX centerY whiteRadius]);
% circlesBlack = int32([centerX centerY blackRadius]);
% mask = step(shapeInserterWhite, zeros(size(img,1), size(img,2)), circlesWhite);
% mask = step(shapeInserterBlack, mask, circlesBlack);
% mask = logical(mask);

%% Sub image initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

radius = radius * radiusConstrictionFactor;

xStart = round(centerX-radius);
xEnd = round(centerX+radius);
yStart = round(centerY-radius);
yEnd = round(centerY+radius);

xDiff = 0;
yDiff = 0;

if xStart < 1
    xDiff = abs(xStart)+1;
    xStart = 1;
end

if yStart < 1
    yDiff = abs(yStart)+1;
    yStart = 1;
end

if xEnd > size(img,2)
    xDiff = -(xEnd-size(img,2));
    xEnd = size(img,2);
end

if yEnd > size(img,1)
    yDiff = -(yEnd-size(img,1));
    yEnd = size(img,1);
end

% if xDiff ~= 0 && yDiff ~= 0 
%     yDiff = 0;
% end

subImg = img(yStart:yEnd, xStart:xEnd);
% subMask = mask(yStart:yEnd, xStart:xEnd);

% Quitting if scallop is very close to boundary
if xDiff ~= 0 || yDiff ~= 0
    currDataPt = currDataPt - 1;
    return;
end
    
%% 2D discretization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if params.localAdjustOn
    subImg = imadjust( subImg );
end
resizeImg = imresize( subImg, [params.resizeImageSize params.resizeImageSize] );
intervalVect = linspace(1, 255, params.numDiscretizationBins);

for intervalI = 1:length( intervalVect )
    if intervalI == 1
        currDataPt( resizeImg <= intervalVect(intervalI) ) = intervalI;
    else
        currDataPt( (resizeImg > intervalVect(intervalI-1) ) & (resizeImg <= intervalVect(intervalI) ) ) = intervalI;
    end
end

end

