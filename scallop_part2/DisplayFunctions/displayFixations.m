function displayFixations(scallopTesting, imageI)
%DISPLAYFixations Display the top down fixations for a given image
%index

%% Initialize
if imageI > scallopTesting.params.numImages
    error('Given image index exceeds number of images, quitting function');
end

params = scallopTesting.params;
fileInfo = scallopTesting.fileInfo;
fixationData = scallopTesting.fixationData;

%% Image filename
currFilename = fullfile(fileInfo.foldername, fileInfo.filename{imageI});
currImage = imread(currFilename);
currImage = imresize(currImage, params.resizeFactor);

%% Getting circle center and radius
numFixations = fixationData.fixationsVar(imageI);
currFixations = fixationData.fixations{imageI};

objectCircle = zeros(numFixations,3);
objectCircle(:,1) = currFixations(:,2);
objectCircle(:,2) = currFixations(:,1);
objectCircle(:,3) = 2;

%% Draw circles
red = uint8([255 0 0]); % [R G B]
shapeInserter = vision.ShapeInserter('Shape','Circles','BorderColor','Custom','CustomBorderColor',red);
currImage = step(shapeInserter, currImage, int32(objectCircle));

%% Display
imshow(currImage);

end


