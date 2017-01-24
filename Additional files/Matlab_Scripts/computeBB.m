function bb = computeBB(centerX, centerY, width, height, xLimits, yLimits)
% COMPUTEBB computes the bounding box using the center of the bounding box
% width and height. If xLimits and yLimits are given, it truncates the
% bounding box based on the limits.

% BB = [xPos yPos Width Height];

%% Initialize
switch nargin
    case 4
        xLimits = [-Inf +Inf];
        yLimits = [-Inf +Inf];
    case 6
        switch numel(xLimits)
            case 1
                xLimits = [1 xLimits];
            case 2
            otherwise
                error('Bloody heavens! Bad xlimits in function %s', mfilename);
        end
        switch numel(yLimits)
            case 1
                yLimits = [1 yLimits];
            case 2
            otherwise
                error('Bloody heavens! Bad ylimits in function %s', mfilename);
        end
    otherwise
        error('Zombies ate my brains! Error in function %s, incompatible number of inputs');
end

%% Half width of BB
halfWidth = round(width/2);
halfHeight = round(height/2);

%% BB Limits
xMin = max(xLimits(1),centerX-halfWidth);
xMax = min(xLimits(2),centerX+halfWidth);
yMin = max(yLimits(1),centerY-halfHeight);
yMax = min(yLimits(2),centerY+halfHeight);

width = xMax-xMin+1;
height = yMax-yMin+1;

%% Output
bb = [xMin yMin width height];

end