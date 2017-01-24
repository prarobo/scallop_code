function objectList = getObjectList(circList)
%GETOBJECTLIST Object list conversion function from old to new code

% Initialization
numImages = length(circList);
numObjects = cellfun(@size, circList, num2cell(ones(numImages,1)));
totalObjects = sum(numObjects);
objectList = zeros(totalObjects, 6);
currInd = 1;

% Main loop
for imageI = 1:numImages
    currNumObjects = size(circList{imageI},1);
    objectList(currInd:currInd+currNumObjects-1,1:5) = circList{imageI};
    objectList(currInd:currInd+currNumObjects-1,6) = imageI;
    currInd = currInd+currNumObjects;
end

end