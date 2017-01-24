function verdict = isPointInsideRectangle(pt, rect, includeBoundary)
%ISPOINTINSIDERECTANGLE check is the give set of points lie inside a given
%rectangle.
%RECT is a bounding box of the form [x y width height]
%PT is a n x 2 vector of points of the form [x1 y1; x2 y2,...]
%VERDICT is a boolean n x 1 matrix that says if the point is present inside
%the rectangle.
%INCLUDEBOUNDARY specifies if the points in the boundary of the rectangle
%are considered inside or outside the rectangle

%% Initialize
switch nargin
    case 2
        includeBoundary = true;
    case 3
    otherwise
        error('Invalid number of arguments in function %s', mfilename);
end

%% Checking points
if includeBoundary
    rect(1:2) = rect(1:2)-1;
    rect(3:4) = rect(3:4)+1;
end
    
verdict = (pt(:,1) > rect(1)) & ...
    (pt(:,2) > rect(2)) & ...
    (pt(:,1) < rect(1)+rect(3)-1) & ...
    (pt(:,2) < rect(2)+rect(4)-1);