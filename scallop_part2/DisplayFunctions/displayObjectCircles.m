function [ objectCircle, confirmValue ] = displayObjectCircles(currImage, objectRect)
%DISPLAYOBJECTCIRCLES Display circle of input rectangle objects

%% Computing circle center and radius
centerX = objectRect(:,1)-1+objectRect(:,3)/2;
centerY = objectRect(:,2)-1+objectRect(:,4)/2;
radius = mean([objectRect(:,3)/2 objectRect(:,4)/2], 2);
           
objectCircle = round([centerX centerY radius]);

%% Draw circles
red = uint8([255 0 0]); % [R G B]
shapeInserter = vision.ShapeInserter('Shape','Circles','BorderColor','Custom','CustomBorderColor',red);
currImage = step(shapeInserter, currImage, int32(objectCircle));

%% Check if user is satisfied
rect = [];
while isempty(rect)
    [~,rect] = imcrop(currImage);
end

close all;
verdict = isPointInsideRectangle(objectCircle(:,1:2), rect);

if sum(verdict) ~= numel(verdict)
    fprintf('User not satisfied\n')
    confirmValue = false;
else
    fprintf('User satisfied\n')
    confirmValue = true;
end

end


