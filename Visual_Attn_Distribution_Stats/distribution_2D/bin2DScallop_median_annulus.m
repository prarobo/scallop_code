function [ currDataPt ] = bin2DScallop_median_annulus( img, centerX, centerY, radius, params )
%BIN2DSCALLOP Discretizes scallops into 2D bins based on polar coordinates

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

thetaMax = 2*pi;
radMax = 1;
valMax = 1;


numBins = [params.numRadBins, params.numThetaBins, params.numDiscretizationBins];
radiusConstrictionFactor = params.radiusConstrictionFactor;

switch nargin
    case 5
    otherwise
        error('Holy hell, bad arguments in function %s, fix it boss', mfilename);
end

currHistImg = cell(numBins(1)+1, numBins(2)+1);
currDataPt = zeros(numBins(1)+1, numBins(2)+1);
for rowI = 1:numBins(1)+1
    for colI = 1:numBins(2)+1
        currHistImg{rowI, colI} = zeros(numBins(3)+1,1);
    end
end

radBins = numBins(1);
thetaBins = numBins(2);
valBins = numBins(3);

radInterval = radMax/radBins;
thetaInterval = thetaMax/thetaBins;
valInterval = valMax/valBins;

persistent shapeInserterWhite;
if isempty(shapeInserterWhite)
     shapeInserterWhite = vision.ShapeInserter('Shape','Circles','Fill',true,'FillColor','White','Opacity',1);
end

persistent shapeInserterBlack;
if isempty(shapeInserterBlack)
     shapeInserterBlack = vision.ShapeInserter('Shape','Circles','Fill',true,'FillColor','Black','Opacity',1);
end

if ~(radiusConstrictionFactor > 1 && radiusConstrictionFactor < 2)
    error('Bloody bullocks! Radius constriction factor is not within 1-2 in function %s', mfilename);
end
whiteRadius = radius * radiusConstrictionFactor;
blackRadius = radius * (1-abs(1-radiusConstrictionFactor));

circlesWhite = int32([centerX centerY whiteRadius]);
circlesBlack = int32([centerX centerY blackRadius]);
mask = step(shapeInserterWhite, zeros(size(img,1), size(img,2)), circlesWhite);
mask = step(shapeInserterBlack, mask, circlesBlack);
mask = logical(mask);

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
subMask = mask(yStart:yEnd, xStart:xEnd);
    
%% 2D discretization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[numRows, numCols] = size(subImg);
newCenterX = (numCols-xDiff)/2;
newCenterY = (numRows-yDiff)/2;
counter=0;

for rowI = 1: numRows
    for colI = 1: numCols
        if subMask(rowI,colI)
             radVal =  computeEuclideanDistance(0 , 0, (colI-newCenterX), -(rowI-newCenterY))/radius;
             thetaVal =  computeAngularTheta(1 , 0, (colI-newCenterX), -(rowI-newCenterY));
             
             if radVal > 1 
                 if radVal < 1.2
                    radVal=1;
                 else
                    error('radVal out of bounds, borderlines cases, radVal = %d',radVal);
                 end
             end            
             
             binRadNum = round(radVal/radInterval);
             binThetaNum = round(thetaVal/thetaInterval);
             binValNum = round(subImg(rowI, colI)/valInterval);
             
             currHistImg{binRadNum+1, binThetaNum+1}(binValNum+1) = currHistImg{binRadNum+1, binThetaNum+1}(binValNum+1) + 1;
             counter = counter+1;
        end
    end
end

%% Saving individual data points
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for rowI = 1:numBins(1)+1
    for colI = 1:numBins(2)+1
%         if sum(currHistImg{rowI, colI})
            % currMean = sum(currHistImg{rowI, colI} .* (0:valInterval:valMax)')/sum(currHistImg{rowI, colI});
            [maxVal, maxPos] = max( currHistImg{rowI, colI} );
            currMode = valInterval * (maxPos-1);
            if maxVal == 0
                currDataPt(rowI, colI) = -1;
            else
                currDataPt(rowI, colI) = currMode;
            end
%         end
    end
end


end

%% Function Euclid Distance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function dist = computeEuclideanDistance( x1, y1, x2, y2 )

dist = sqrt( (x1-x2)^2 + (y1-y2)^2 );

end

%% Function Angular Theta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function theta = computeAngularTheta( x1, y1, x2, y2 )

pt1 = [x1 y1];
pt2 = [x2 y2];

if pt1(1)==pt2(1) && pt1(2)==pt2(2)
    theta = 0;
    return;
end

if pt2(1)==0 && pt2(2)==0
    theta = 0;
    return;
end

angleMag = acos( dot(pt1,pt2)/(norm(pt1)*norm(pt2)) );

if ~isreal(angleMag)
    error('Arc cosine gives unrealistic values!');
end

if y2>y1
    theta = angleMag;
else
    theta = 2*pi-angleMag;
end

if theta == 2*pi
    theta = 0;
end

end



