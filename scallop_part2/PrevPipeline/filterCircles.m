function reducedCircleList = filterCircles( circList, fixationWindowSize, varargin )
%FILTERCIRCLES Filter Circle List

%% Initialization

switch nargin
    case 2
        fixationWindowCheck = true;
        fixRad = round( max( fixationWindowSize(:) )/2 );
        fixCenter = round( fixationWindowSize/2 );
        minRadius = 10; %17
        maxRadius = 45; %36
    case 3
        fixationWindowCheck = false;
        params = varargin{1};
        minRadius = params.minAllowableScallopRadius;
        maxRadius = params.maxAllowableScallopRadius;        
    otherwise
        error( 'Boo haha! I quit! Incompatible arguments in function %s', mfilename);
end

numCircles = size(circList,1);
circleAccept = true(numCircles,1);
radiusTolerancePercent = 0.1;
centerToleranceDistance = 10;

%% Circle Radius Filter and Center Limits (fixation level)

if fixationWindowCheck
    for circI = 1:numCircles
        if(circleAccept(circI))
            if( circList(circI,3) < minRadius || circList(circI,3) > maxRadius ||...
                    circList(circI,1) <= 0 || circList(circI,2) <= 0 ||...
                    circList(circI,1) > fixationWindowSize(2) || circList(circI,2) > fixationWindowSize(1) )
                circleAccept(circI) = false;
            end
        end
    end
end

%% Circle Radius Filter and Center Limits (image level)

for circI = 1:numCircles
    if(circleAccept(circI))
        if( circList(circI,3) < minRadius || circList(circI,3) > maxRadius ||...
                circList(circI,1) <= 0 || circList(circI,2) <= 0 ||...
                circList(circI,1) > params.imageSize(2) || circList(circI,2) > params.imageSize(1) )
            circleAccept(circI) = false;
        end
    end
end

%% Circle Nearness Filter

for circI = 1:numCircles-1
    if(circleAccept(circI))        
        for circI2 = circI+1:numCircles
            if(circleAccept(circI2))
                if( ( circList(circI2,3) > (1-radiusTolerancePercent)*circList(circI,3) ||...
                        circList(circI2,3) < (1+radiusTolerancePercent)*circList(circI,3) ) && ...
                        euclideanDistance( circList(circI2,1), circList(circI2,2), circList(circI,1), circList(circI,2) )...
                                                < centerToleranceDistance )
                           circleAccept(circI2) = false;
                           circList(circI,1) = ( circList(circI,1) + circList(circI2,1) )/ 2;
                           circList(circI,2) = ( circList(circI,2) + circList(circI2,2) )/ 2;
                           circList(circI,3) = ( circList(circI,3) + circList(circI2,3) )/ 2;                    
                end
            end
        end
    end
end

%% Circular Fixation Filter

if fixationWindowCheck
    for circI = 1:numCircles
        if(circleAccept(circI))
            if( euclideanDistance(fixCenter(2), fixCenter(1), circList(circI,1), circList(circI,2)) > fixRad - circList(circI,3) )
                circleAccept(circI) = false;
            end
        end
    end
end

%% Circular Radius Extension Filter

if ~fixationWindowCheck
    for circI = 1:numCircles
        if(circleAccept(circI))
            newRadius = round( params.radiusConstrictionFactor * circList(circI,3) );
            if ( circList(circI,1) - newRadius < 1 || circList(circI,2) - newRadius < 1 ||...
                    circList(circI,1) + newRadius > params.imageSize(2) || circList(circI,2) + newRadius > params.imageSize(1) )
                circleAccept(circI) = false;
            end
        end
    end
end

%% Filtered circle list

reducedCircleList = zeros( sum( circleAccept(:) ), size(circList,2) );
currI=1;

for circI = 1:numCircles
    if(circleAccept(circI))
        reducedCircleList(currI,:) = circList(circI,:);
        currI=currI+1;
    end
end

end
