function displayScallopCircles( scallopTesting )
%DISPLAYGROUNDTRUTHSCALLOP Displays each scallop and related processing

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

while true
    displayNow( scallopTesting, imageI );
    
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
            case 'w'                
                if imageI ~= numImages
                    imageI = imageI+1;
                else
                    imageI = 1;
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

function displayNow( scallopTesting, imageI )
%DISPLAYNOW Redraw all figures based on user options

%% Initialization

numImages = scallopTesting.params.numImages;
numObj = size(scallopTesting.distributionData.objList{imageI}, 1);
numOrigObj = size(scallopTesting.distributionData.origObjList{imageI}, 1);
numScallops = scallopTesting.statData.groundTruth(imageI).numScallops;
params = scallopTesting.params;
scallopVerdictThreshold = scallopTesting.classData.classificationResults.scallopVerdictThreshold;
scallopMatchMetric = scallopTesting.params.matchMetric;
categoryStats = scallopTesting.statData.categoryStats;

imageFileName = sprintf('%s/%s',scallopTesting.fileInfo.foldername, scallopTesting.fileInfo.filename{imageI});
currImage = imread( imageFileName );

clf

%% Original Image

subplot('Position',[0.05 0.6 0.4 0.4]);
imshow(currImage);

for scallopI=1:numScallops
    currScallop = scallopTesting.statData.groundTruth(imageI).loc(scallopI,:);
    [currScallopRect, isValid] = computeScallopRect( currScallop, params );
    rectangle('Position',currScallopRect, 'Curvature',[1 1], 'LineWidth',2, 'EdgeColor','magenta');    
end

% hold off

% title(sprintf('Image %d of %d', imageI, numImages));
% xlim ([1 scallopTesting.params.imageSize(2)]);
% ylim ([1 scallopTesting.params.imageSize(1)]);

%% Detected Objects

subplot('Position',[0.55 0.6 0.4 0.4]);
imshow(currImage);

hold on
for scallopI=1:numScallops
    currScallop = scallopTesting.statData.groundTruth(imageI).loc(scallopI,:);
    [currScallopRect, isValid] = computeScallopRect( currScallop, params );
    rectangle('Position',currScallopRect, 'Curvature',[1 1], 'LineWidth',2, 'EdgeColor','magenta');    
end

for objI=1:numOrigObj
    currObj = scallopTesting.distributionData.origObjList{imageI}(objI,:);
    [currObjRect, isValid] = computeScallopRect( currObj, params );
    if isValid
        rectangle('Position', currObjRect, 'Curvature',[1 1], ...
            'LineWidth',2, 'EdgeColor','red');
    end
end

for objI=1:numObj
    currObj = scallopTesting.distributionData.objList{imageI}(objI,:);
    [currObjRect, isValid] = computeScallopRect( currObj, params );
    if isValid
        rectangle('Position', currObjRect, 'Curvature',[1 1], ...
            'LineWidth',2, 'EdgeColor','green');
    end
end

hold off
title(sprintf('Objects magenta-ground truth \n green \tcircle satisfying filter\n red \t circles thrown out'));

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