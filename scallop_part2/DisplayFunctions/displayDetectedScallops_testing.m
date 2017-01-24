function displayDetectedScallops_testing( scallopTesting )
%DISPLAYDETECTEDSCALLOPS Display the detected scallops

%% User Interface to toggle between images

imageI = 1;
objI = 1;
numImages = scallopTesting.params.numImages;
numObjects = size(scallopTesting.distributionData.objList{imageI},1);

if numObjects == 0
    objI = 0;
end

figure;
% set(gcf, 'Position', get(0,'Screensize'));
annotation(gcf,'textbox',...
    [0.1 0.96 0.5 0.03],...
    'String',{sprintf(' w-next image \t\t s-previous image \t\t q-quit')},...
    'FitBoxToText','on');


currMatchesTestBox = annotation(gcf,'textbox',...
    [0.75 0.05 0.2 0.8],...
    'String',{'Scallop Distributions Satisfied' },...
    'FitBoxToText','on');

while true
    delete(currMatchesTestBox);
    currMatchesTestBox = displayNow( scallopTesting, imageI, objI );
    
    ch = waitforbuttonpress;
    if ch == 1
        key = get(gcf,'CurrentCharacter');
        switch key
            case 's'               
                if imageI ~=1
                    imageI=imageI-1;
                else
                    imageI = numImages;
                end
                numObjects = size(scallopTesting.distributionData.objList{imageI},1);
                if numObjects ~= 0
                    objI = 1;
                else
                    objI = 0;
                end
            case 'w'                
                if imageI ~= numImages
                    imageI = imageI+1;
                else
                    imageI = 1;
                end
                numObjects = size(scallopTesting.distributionData.objList{imageI},1);
                if numObjects ~= 0
                    objI = 1;
                else
                    objI = 0;
                end
            case 'a'
                if numObjects ~= 0
                    if objI ~=1
                        objI=objI-1;
                    else
                        objI = numObjects;
                    end
                else
                    objI = 0;
                end
            case 'd'
                if numObjects ~= 0
                    if objI ~= numObjects
                        objI = objI+1;
                    else
                        objI = 1;
                    end
                else
                    objI = 0;
                end
            case 'q'
                close(gcf);
                break;
            otherwise
                disp('w-next image, s-previous image, q-quit');
        end
    else
        disp('w-next image, s-previous image, q-quit');
    end
end

end

%% Function to Redraw all figures based on user options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function currMatchesTestBox = displayNow( scallopTesting, imageI, currObjI )
%DISPLAYNOW Redraw all figures based on user options

%% Initialization

numImages = scallopTesting.params.numImages;
numObj = size(scallopTesting.distributionData.objList{imageI}, 1);
numScallops = scallopTesting.groundTruth.imageWise(imageI).numScallops;
params = scallopTesting.params;
scallopVerdictThreshold = scallopTesting.classData.classificationResults.scallopVerdictThreshold;
scallopMatchMetric = scallopTesting.params.matchMetric;
categoryStats = scallopTesting.statData.categoryStats;

imageFileName = sprintf('%s/%s',scallopTesting.fileInfo.foldername, scallopTesting.fileInfo.filename{imageI});
currImage = imresize(imread( imageFileName ), scallopTesting.params.resizeFactor);

currMatchString = sprintf('Scallop Match Value (%s)\n', scallopMatchMetric);

clf

%% Original Image

subplot('Position',[0.05 0.55 0.4 0.4]);
imshow(currImage);
title(sprintf( 'Image %d', imageI ) )

% hold off

% title(sprintf('Image %d of %d', imageI, numImages));
% xlim ([1 scallopTesting.params.imageSize(2)]);
% ylim ([1 scallopTesting.params.imageSize(1)]);

%% Detected Objects

subplot('Position',[0.05 0.02 0.4 0.4]);
imshow(currImage);

hold on
for scallopI=1:numScallops
    currScallop = scallopTesting.groundTruth.imageWise(imageI).loc(scallopI,:);
    [currScallopRect, isValid] = computeScallopRect( currScallop, params );
    rectangle('Position',currScallopRect, 'Curvature',[1 1], 'LineWidth',2, 'EdgeColor','magenta');    
end

for objI=1:numObj
    currObj = scallopTesting.distributionData.objList{imageI}(objI,:);
    [currObjRect, isValid] = computeScallopRect( currObj, params );
    
    [scallopVerdict, matchVal] = checkScallop( scallopTesting.distributionData.dataPointMatch{imageI}, ...
        scallopVerdictThreshold, scallopMatchMetric, objI );
    if scallopVerdict
        if (categoryStats(imageI).objects(objI) == 1)
            rectangle('Position', currObjRect, 'Curvature',[1 1], ...
                'LineWidth',2, 'EdgeColor','green');
        end
        if (categoryStats(imageI).objects(objI) == 0)
            rectangle('Position', currObjRect, 'Curvature',[1 1], ...
                'LineWidth',2, 'EdgeColor','red');
        end
    else
        if (categoryStats(imageI).objects(objI) == 1)
            rectangle('Position', currObjRect, 'Curvature',[1 1], ...
                'LineWidth',2, 'EdgeColor','cyan');
        end
        if (categoryStats(imageI).objects(objI) == 0)
            rectangle('Position', currObjRect, 'Curvature',[1 1], ...
                'LineWidth',2, 'EdgeColor','blue');
        end
    end
    
    currMatchString = sprintf('%s%f \n', currMatchString, matchVal );
end

if currObjI ~= 0
    currObj = scallopTesting.distributionData.objList{imageI}(currObjI,:);
    [currObjRect, isValid] = computeScallopRect( [currObj(1) currObj(2) params.radiusConstrictionFactor*currObj(3)], params );
    rectangle('Position', currObjRect, 'Curvature',[1 1], 'LineWidth',2, 'EdgeColor','black');
end
hold off
title(sprintf('Objects magenta-ground truth \n green \tscallops classified correctly \n red \t non-scallops classified as scallops \n cyan \t scallops missed \n blue \t non-scallops classified correctly'));

%% Current Object (discretization)

subplot('Position',[0.55 0.02 0.2 0.2]);

if currObjI ~= 0
    currObj = scallopTesting.distributionData.objList{imageI}(currObjI,:);
    outImage = processLocalImage( currImage, currObj, params);
    currMatchVal = scallopTesting.distributionData.dataPointMatch{imageI}{currObjI}.(scallopMatchMetric);
    
    imagesc(outImage)
    title( sprintf('Current match val (%s) = %f', scallopMatchMetric, currMatchVal) );
    axis off
end

%% Current Object (image)

subplot('Position',[0.55 0.3 0.2 0.2]);

if currObjI ~= 0    
    imshow( imcrop( currImage, currObjRect ) );
end

%% Results

currMatchesTestBox = annotation(gcf,'textbox',...
    [0.75 0.05 0.2 0.8],...
    'String',{currMatchString},...
    'FitBoxToText','on');

end

%% Check scallop function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [scallopVerdict, matchVal] = checkScallop( dataPointMatch, threshold, metric, objI )

if isempty(dataPointMatch{objI})
    scallopVerdict = false;
    matchVal = -1;
    return;
end
    
if dataPointMatch{objI}.(metric) <= threshold
    scallopVerdict = true;
else
    scallopVerdict = false;
end
matchVal = dataPointMatch{objI}.(metric);

end

%% Function to compute scallop rect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [currScallopRect, isValid] = computeScallopRect( loc, params )

colStart = round(loc(1) - loc(3));
rowStart = round(loc(2) - loc(3));
dotDia = round(2 * loc(3));

currScallopRect = [colStart rowStart dotDia dotDia];

if colStart < 1 || rowStart < 1 || colStart+dotDia > params.imageSize(2) || rowStart+dotDia > params.imageSize(1)
    isValid = false;
else
    isValid = true;
end

end

%% Function to process image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function outImage = processLocalImage( currImage, currObj, params )

if params.globalAdjustOn
    currImage = imadjust( currImage, stretchlim(currImage) );
end
currGrayImage = rgb2gray( currImage );

centerX = currObj(1);
centerY = currObj(2);
radius = currObj(3);

outImage = bin2DScallop_linear_testing(currGrayImage,...
    centerX,...
    centerY,...
    radius,...
    params);

end

