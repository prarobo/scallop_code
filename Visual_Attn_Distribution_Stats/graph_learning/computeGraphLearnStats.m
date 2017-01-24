function [ graphLearnStats ] = computeGraphLearnStats( scallopReg, scallopLoc )
%COMPUTEGRAPHLEARNSTATS Computes features from graphcut segmentation

%% Areas based on ground truth mask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Creating circle mask
[x,y]=meshgrid(-(scallopLoc(1)-1):(size(labelImage,2)-scallopLoc(1)),-(scallopLoc(2)-1):(size(labelImage,1)-scallopLoc(2)));
circleMask=((x.^2+y.^2)<=scallopLoc(3)^2);

% Region Area
regArea = sum( scallopReg(:) );

% Circle Area
circleArea = sum( circleMask(:) );

% Circle Intersect Area
intersectReg = scallopReg & circleMask;
circleIntersectArea = sum( intersectReg(:) );

%% Compute area and perimeter stats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

maskType = 'circle';
maskParam = scallopLoc;
areaPerimStats = computeAreaPerimStats( scallopReg, maskType, maskParam );

end

%% Function to compute area and perimeter stats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [areaPerimStats] = computeAreaPerimStats( scallopReg, maskType, maskParam )

% Initialization
areaImage = scallopReg;
perimImage = bwperim( scallopReg );
perimImage = perimImage & bwperim( true( size( scallopReg ) ) );
radLimit = 5;
radRangeMin = maskParam(3)-radLimit;
radRangeMax = maskParam(3)+radLimit;

if radRangeMin < 1
    radRangeMin = 1;
end

if radRangeMin > 50
    radRangeMin = 50;
end

if strcmp(maskType, 'circle')

    for radI = radRangeMin:radRangeMask
        % Creating circle mask
        [x,y] = meshgrid(-(maskParam(1)-1):(size(scallopReg,2)-maskParam(1)),-(maskParam(2)-1):(size(scallopReg,1)-maskParam(2)));
        circleMask = ((x.^2+y.^2) <= maskParam^2);
        
        % Region Area
        regArea = sum( scallopReg(:) );
        
        % Circle Area
        circleArea = sum( circleMask(:) );
        
        % Circle Intersect Area
        intersectReg = scallopReg & circleMask;
        circleIntersectArea = sum( intersectReg(:) );
        
        % Circle perimeter
        circlePerim = bwperim( scallopReg );
    end
else
    error('Unrecognized mask type in %s', mfilename);
end

end
