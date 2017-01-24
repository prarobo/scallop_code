function [] = displayScallopAnalysis_gFix( scallopTesting, confIntervalData, scallopLookupParams )
%DISPLAYSCALLOPANALYSIS Show scallop detection analysis

%% User Interface to toggle between images

imageI = 1;
fixI = 1;
numImages = scallopTesting.params.numImages;
numFixations = scallopTesting.fixationData.fixationsVar(imageI);

windowRect = calcRect( scallopTesting.fixationData.fixations, ...
                        scallopTesting.params.imageSize, scallopTesting.params.fixationWindowSize );

figure;

currResultsBox = annotation(gcf,'textbox',...
    [0.8 0.05 0.3 0.3],...
    'String',{'Scallop Results' },...
    'FitBoxToText','on');

while true
    delete(currResultsBox);
    currResultsBox = displayNow( scallopTesting, imageI, fixI, windowRect, confIntervalData, scallopLookupParams );
    
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
                numFixations = scallopTesting.fixationData.fixationsVar(imageI);
            case 'w'                
                if imageI ~= numImages
                    imageI = imageI+1;
                else
                    imageI = 1;
                end
                numFixations = scallopTesting.fixationData.fixationsVar(imageI);
            case 'a'               
                if fixI ~=1
                    fixI=fixI-1;
                else
                    fixI = numFixations;
                end
            case 'd'                
                if fixI ~= numFixations
                    fixI = fixI+1;
                else
                    fixI = 1;
                end
            case 'q'
                close(gcf);
                break;
            otherwise
                disp('w/s-next/previous image, a/d-nest/previous fixation, q-quit');
        end
    else
        disp('w/s-next/previous image, a/d-nest/previous fixation, q-quit');
    end
end

end

%% Display Now Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [currResultsBox] = displayNow( scallopTesting, imageI, fixI, windowRect, confIntervalData, scallopLookupParams )
%DISPLAYNOW Redraw all figures based on user options

numImages = scallopTesting.params.numImages;
numFixations = scallopTesting.fixationData.fixationsVar(imageI);
params =scallopTesting.params;

imageFileName = sprintf('%s/%s',scallopTesting.fileInfo.foldername, scallopTesting.fileInfo.filename{imageI});
currImage = imread( imageFileName );
if params.globalAdjustOn
    currImage = imadjust( currImage, stretchlim(currImage) );
end
currGrayImage = rgb2gray( currImage );

% imagesc(1:10);
% cmap = colormap;
cmap=jet;

% colorLimits = computeColorLimits( groundImage, segImage, meanMap, stddevMap);
colorLimits = [0 10];

%% Plot fixation rect with scallop circle

subplot('Position',[0.05 0.5 0.4 0.4]);
imshow(currImage);

hold on
rectangle('Position', windowRect{imageI}(fixI,:), 'LineWidth', 2, 'EdgeColor','red');

%scallopTesting.statData.groundTruth(imageI).loc 
groundScallop = scallopTesting.statData.groundTruth(imageI).loc(fixI,:);
[groundScallopRect, isValid] = computeScallopRect( groundScallop, params );
if isValid
    rectangle('Position', groundScallopRect, 'Curvature',[1 1], 'LineWidth', 2, 'EdgeColor','magenta');
end

if ~isempty(scallopTesting.statData.detectionStats(imageI).scallop{fixI}.circList)
    segScallop = scallopTesting.statData.detectionStats(imageI).scallop{fixI}.circList(1,1:3);
    segScallopRect = computeScallopRect( segScallop, params );
    if isValid
        if scallopTesting.statData.detectionStats(imageI).scallop{fixI}.foundScallop
            rectangle('Position',segScallopRect, 'Curvature',[1 1], 'LineWidth',2, 'EdgeColor','green');
        else
            rectangle('Position',segScallopRect, 'Curvature',[1 1], 'LineWidth',2, 'EdgeColor','blue');
        end
    end
end

hold off

colormap(cmap)
title(sprintf('Image %d of %d, scallop %d of %d (m-ground, g-detected, b-missed)', imageI, numImages, fixI, numFixations));
xlim ([1 scallopTesting.params.imageSize(2)]);
ylim ([1 scallopTesting.params.imageSize(1)]);

%% Plot ground scallop discretization

groundScallop = scallopTesting.statData.groundTruth(imageI).loc(fixI,:);
groundScallop = round([groundScallop(1) groundScallop(2) groundScallop(3)*params.radiusConstrictionFactor ]);
[groundScallopRect, isValid] = computeScallopRect( groundScallop, params );
if isValid
    groundImage = imcrop( currGrayImage, groundScallopRect );
    groundImage = processImage( groundImage, params );
else
    groundImage = false(params.params.resizeImageSize);
end

subplot('Position',[0.5 0.7 0.2 0.2]);
imagesc(groundImage);
axis off
title('Ground discret');
caxis manual
caxis( colorLimits );
colormap(cmap);
colorbar

%% Plot segment scallop discretization

segScallop = scallopTesting.statData.detectionStats(imageI).scallop{fixI}.circList(1,1:3);
segScallop = round([segScallop(1) segScallop(2) segScallop(3)*params.radiusConstrictionFactor ]);
[segScallopRect, isValid] = computeScallopRect( segScallop, params );
if isValid
    segImage = imcrop( currGrayImage, segScallopRect );
    segImage = processImage( segImage, params );
else
    segImage = false(params.resizeImageSize);
end

subplot('Position',[0.5 0.4 0.2 0.2]);
imagesc(segImage);
axis off
title('Segment discret');
colormap(cmap);
caxis manual
caxis( colorLimits );
colorbar

%% Plot reference mean and std deviation

if confIntervalData.isValid(segScallop(2), segScallop(1))
    meanMap = transpose( reshape( confIntervalData.meanPoints{segScallop(2), segScallop(1)}, ...
        params.resizeImageSize, params.resizeImageSize ));
    stddevMap = transpose( reshape( confIntervalData.stddevPoints{segScallop(2), segScallop(1)}, ...
        params.resizeImageSize, params.resizeImageSize ));
else
    meanMap = false(params.resizeImageSize);
    stddevMap = false(params.resizeImageSize);
end

subplot('Position',[0.05 0.1 0.2 0.2]);
imagesc(meanMap)
axis off
title('Mean reference');
colormap(cmap);
caxis manual
caxis( colorLimits );
colorbar

subplot('Position',[0.25 0.1 0.2 0.2]);
imagesc(stddevMap)
axis off
title('Std dev reference');
colormap(cmap);
caxis manual
caxis( colorLimits );
colorbar

%% Plot conf match mat and selected features

currObj = scallopTesting.statData.detectionStats(imageI).scallop{fixI}.circList(1,8);
if confIntervalData.isValid(segScallop(2), segScallop(1))    
    matchMap = scallopTesting.distributionData.dataPointMatch{imageI}{currObj}.confMatchMat;
    selFeatures = scallopTesting.distributionData.dataPointMatch{imageI}{currObj}.topStddevMask;
    selMatchMap = false(params.resizeImageSize);
    selMatchMap(selFeatures) = true;
else
    matchMap = false(params.resizeImageSize);
    selMatchMap = false(params.resizeImageSize);
end

subplot('Position',[0.7 0.7 0.2 0.2]);
imagesc(matchMap)
axis off
title('conf match');
colorbar

subplot('Position',[0.7 0.4 0.2 0.2]);
imagesc(selMatchMap)
axis off
title('Selected features');
colorbar

%% Results

matchVal = scallopTesting.distributionData.dataPointMatch{imageI}{currObj}.matchVal;
matchInvStddevWeightVal = scallopTesting.distributionData.dataPointMatch{imageI}{currObj}.matchInvStddevWeightVal;
matchTopStddevWeightVal = scallopTesting.distributionData.dataPointMatch{imageI}{currObj}.matchTopStddevWeightVal;
matchTemplateVal = scallopTesting.distributionData.dataPointMatch{imageI}{currObj}.matchTemplateVal;
matchTemplateLoc = scallopTesting.distributionData.dataPointMatch{imageI}{currObj}.matchTemplateLoc;
currNumScallopsConf = confIntervalData.numPoints(segScallop(2), segScallop(1));
confVal = scallopLookupParams.confIntervalScallop;

currResultsString = sprintf('Scallop Results\n');
        
currResultsString = sprintf('%s match val  = %f \n', currResultsString, matchVal );
currResultsString = sprintf('%s inv stddev val  = %f \n', currResultsString, matchInvStddevWeightVal );
currResultsString = sprintf('%s top stddev val  = %f \n', currResultsString, matchTopStddevWeightVal );
currResultsString = sprintf('%s match template val  = %f \n', currResultsString, matchTemplateVal );
currResultsString = sprintf('%s match template loc  = %f \n', currResultsString, matchTemplateLoc );
currResultsString = sprintf('%s num scallops  = %f \n', currResultsString, currNumScallopsConf );
currResultsString = sprintf('%s conf val  = %f \n', currResultsString, confVal );

currResultsBox = annotation(gcf,'textbox',...
    [0.6 0.1 0.2 0.2],...
    'String',{currResultsString},...
    'FitBoxToText','on');

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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function outImage = processImage( inImage, params )

outImage = zeros(params.resizeImageSize);

if params.localAdjustOn
    inImage = imadjust( inImage );
end
resizeImage = imresize( inImage, [params.resizeImageSize params.resizeImageSize] );
intervalVect = linspace(1, 255, params.numDiscretizationBins);

for intervalI = 1:length( intervalVect )
    if intervalI == 1
        outImage( resizeImage <= intervalVect(intervalI) ) = intervalI;
    else
        outImage( (resizeImage > intervalVect(intervalI-1) ) & (resizeImage <= intervalVect(intervalI) ) ) = intervalI;
    end
end

end

%% Function to compute color limits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function colorLimits = computeColorLimits(varargin)

if naragin == 0
    error('No imput maps to determine color limits, error in function %s', mfilename);
end

colorLimits = [0 0];

for mapI = 1:nargin
    colorLimits(1) = min( min(varargin{mapI}(:)), colorLimits(1) );
    colorLimits(2) = max( max(varargin{mapI}(:)), colorLimits(2) );
end

end











