function [ currDataPt ] = bin2DEfficient( img, centerX, centerY, radius, numBins )
%BIN2DSCALLOP Discretizes scallops into 2D bins based on polar coordinates

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch nargin
    case 5
        numBins = [100 100 100];
    case 6
        if numel(numBins) ~= 3
            error('Interval has to contain 3 values in bin2DScallop');
        end
    otherwise
        error('Holy hell, bad arguments in bin2DScallop, fix it boss');
end

% img = fspecial('gaussian',256,32); % generate fake image
% img = uint8( (img-min(img(:)))*255/max(img(:)) );
% centerX=size(img,1)/2; centerY=size(img,2)/2;
% radius = 50;
% numBins = [11 51 51];

%% Sub image initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
[numRows, numCols] = size(subImg);
newCenterX = (numCols-xDiff)/2;
newCenterY = (numRows-yDiff)/2;

%% Filtering Points
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[Y, X, z]=find(subImg);
X = X - newCenterX;
Y = Y - newCenterY;
theta = atan2(Y, X);
rho = sqrt(X.^2+Y.^2);

indMat = (rho <= radius);
rho = rho(indMat);
theta = theta(indMat);
z = z(indMat);

indMat = (theta == 2*pi);
theta(indMat) = 0;

%% 2D discretization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Determine the minimum and the maximum x and y values:
rmin = min(rho); tmin = min(theta);
rmax = max(rho); tmax = max(theta);

% Define the resolution of the grid:
rres=numBins(1)+1; % # of grid points for R coordinate. (change to needed binning)
tres=numBins(2)+1; % # of grid points for theta coordinate (change to needed binning)

F = TriScatteredInterp(double(rho),double(theta),im2double(z),'nearest');

%Evaluate the interpolant at the locations (rhoi, thetai).
%The corresponding value at these locations is Zinterp:

[rhoi,thetai] = meshgrid(linspace(rmin,rmax,rres),linspace(tmin,tmax,tres));
currDataPt = F(rhoi,thetai);

% subplot(1,2,1); imshow(subImg) ; axis square
% subplot(1,2,2); imagesc(currDataPt) ; axis square

end
