function displayGroundScallops(scallopTesting, imageI)
%DISPLAYGROUNDSCALLOPS Display the groundtruth scallops for a given image
%index

%% Initialize
if imageI > scallopTesting.params.numImages
    error('Given image index exceeds number of images, quitting function');
end

params = scallopTesting.params;
groundTruth = scallopTesting.groundTruth;
fileInfo = scallopTesting.fileInfo;

%% Image filename
currFilename = fullfile(fileInfo.foldername, fileInfo.filenames{imageI});
currImage = imread(currFilename);
currImage = imresize(currImage, params.resizeFactor);

%% Getting circle center and radius
currObjInd = cellfun(@strcmp, groundTruth.ImageName, repmat(fileInfo.filename(imageI),params.numScallops,1));
centerX = groundTruth.X(currObjInd);
centerY = groundTruth.Y(currObjInd);
radius = groundTruth.radius(currObjInd);
           
objectCircle = round([centerX centerY radius]);

%% Draw circles
red = uint8([255 0 0]); % [R G B]
shapeInserter = vision.ShapeInserter('Shape','Circles','BorderColor','Custom','CustomBorderColor',red);
currImage = step(shapeInserter, currImage, int32(objectCircle));

%% Display
imshow(currImage);

end


