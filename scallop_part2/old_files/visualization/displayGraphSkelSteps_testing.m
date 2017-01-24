function displayGraphSkelSteps_testing( visualAttnData, filterData )
%DISPLAYGRAPHFILTER Displays graph cut based filters

%% User Interface to toggle between images and fixations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imageI = 1;
fixI = 1;
numImages = visualAttnData.params.numImages;
numFixations = visualAttnData.fixationData.fixationsVar(imageI);
numCirc = size( filterData(imageI).fixation{fixI}.reducedCircList, 1 );
if numCirc > 0
    circI = 1;
else
    circI = 0;
end
showInitialFilterCircles = true;

windowRect = calcRect( visualAttnData.fixationData.fixations, ...
    visualAttnData.params.imageSize, visualAttnData.params.fixationWindowSize );

figure;

while true
    displayNow( visualAttnData.fileInfo, filterData, imageI, fixI, circI, showInitialFilterCircles, windowRect{imageI}(fixI,:) );
    
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
                numFixations = visualAttnData.fixationData.fixationsVar(imageI);
                fixI = 1;
                numCirc = size( filterData(imageI).fixation{fixI}.reducedCircList, 1 );
                if numCirc > 0
                    circI = 1;
                else
                    circI = 0;
                end
            case 'w'                
                if imageI ~= numImages
                    imageI = imageI+1;
                else
                    imageI = 1;
                end
                numFixations = visualAttnData.fixationData.fixationsVar(imageI);
                fixI = 1;
                numCirc = size( filterData(imageI).fixation{fixI}.reducedCircList, 1 );
                if numCirc > 0
                    circI = 1;
                else
                    circI = 0;
                end
            case 'a'               
                if fixI ~=1
                    fixI=fixI-1;
                else
                    fixI = numFixations;
                end
                numCirc = size( filterData(imageI).fixation{fixI}.reducedCircList, 1 );
                if numCirc > 0
                    circI = 1;
                else
                    circI = 0;
                end                
            case 'd'
                if fixI ~= numFixations
                    fixI = fixI+1;
                else
                    fixI = 1;
                end
                numCirc = size( filterData(imageI).fixation{fixI}.reducedCircList, 1 );
                if numCirc > 0
                    circI = 1;
                else
                    circI = 0;
                end
            case 'r'
                if numCirc == 0
                    circI = 0;
                else
                    if circI == numCirc
                        circI = 1;
                    else
                        circI = circI+1;
                    end
                end
            case 'f'
                if numCirc == 0
                    circI = 0;
                else
                    if circI == 1
                        circI = numCirc;
                    else
                        circI = circI-1;
                    end
                end
            case 'e'
                if showInitialFilterCircles
                    showInitialFilterCircles = false;
                else
                    showInitialFilterCircles = true;
                end
            case 'q'
                close(gcf);
                break;
            otherwise
                disp('w-next image, s-previous image, a-previous fixation, d-next fixation, r-next circle, f-previous circle, q-quit, e-toggle circles');
        end
    else
        disp('w-next image, s-previous image, a-previous fixation, d-next fixation, r-next circle, f-previous circle, q-quit, , e-toggle circles');
    end
end

end

function displayNow( fileInfo, filterData, imageI, fixI, indCircI, showInitialFilterCircles, rect)

origImage = imread( fullfile(fileInfo.foldername, fileInfo.filename{imageI}) );
filterImage = filterData(imageI).fixation{fixI}.filterImage;
labelImage = filterData(imageI).fixation{fixI}.labelImage;
origCircList = filterData(imageI).fixation{fixI}.origCircList;
%filterCircList = filterData(imageI).fixation{fixI}.filterCircList;
reducedCircList = filterData(imageI).fixation{fixI}.reducedCircList;

subplot('Position',[0.05 0.5 0.4 0.4]);
imshow( origImage );
rectangle('Position', rect, 'LineWidth', 2, 'EdgeColor','red');

subplot('Position',[0.5 0.5 0.4 0.4]);
fixationWindow = imcrop( origImage, rect );
imshow( fixationWindow );

hold on

if showInitialFilterCircles
    for circI=1:size(origCircList,1)
        t=0:.01:2*pi;
        plot(origCircList(circI,1)+origCircList(circI,3)*sin(t),origCircList(circI,2)+origCircList(circI,3)*cos(t), 'red');
    end
end

% for circI=1:size(filterCircList,1)
%     t=0:.01:2*pi;
%     plot(filterCircList(circI,1)+filterCircList(circI,3)*sin(t),filterCircList(circI,2)+filterCircList(circI,3)*cos(t), 'magenta');
% end

for circI=1:size(reducedCircList,1)
    t=0:.01:2*pi;
    plot(reducedCircList(circI,1)+reducedCircList(circI,3)*sin(t),reducedCircList(circI,2)+reducedCircList(circI,3)*cos(t), 'green');
end

hold off


bwImage = zeros(size(filterImage,1), size(filterImage,2), 3);
bwImage(:,:,1) = filterImage.*255;
bwImage(:,:,2) = filterImage.*255;
bwImage(:,:,3) = filterImage.*255;
bwImage = im2uint8( bwImage );

subplot('Position',[0.02 0.05 0.3 0.3]);
imshow(bwImage);
hold on

if showInitialFilterCircles
    for circI=1:size(origCircList,1)
        t=0:.01:2*pi;
        plot(origCircList(circI,1)+origCircList(circI,3)*sin(t),origCircList(circI,2)+origCircList(circI,3)*cos(t), 'red');
    end
end

% for circI=1:size(filterCircList,1)
%     t=0:.01:2*pi;
%     plot(filterCircList(circI,1)+filterCircList(circI,3)*sin(t),filterCircList(circI,2)+filterCircList(circI,3)*cos(t), 'magenta');
% end

for circI=1:size(reducedCircList,1)
    t=0:.01:2*pi;
    plot(reducedCircList(circI,1)+reducedCircList(circI,3)*sin(t),reducedCircList(circI,2)+reducedCircList(circI,3)*cos(t), 'green');
end

hold off

subplot('Position',[0.35 0.05 0.3 0.3]);
imshow(label2rgb(labelImage));
hold on

if showInitialFilterCircles
    for circI=1:size(origCircList,1)
        t=0:.01:2*pi;
        plot(origCircList(circI,1)+origCircList(circI,3)*sin(t),origCircList(circI,2)+origCircList(circI,3)*cos(t), 'red');
    end
end

% for circI=1:size(filterCircList,1)
%     t=0:.01:2*pi;
%     plot(filterCircList(circI,1)+filterCircList(circI,3)*sin(t),filterCircList(circI,2)+filterCircList(circI,3)*cos(t), 'magenta');
% end

for circI=1:size(reducedCircList,1)
    t=0:.01:2*pi;
    plot(reducedCircList(circI,1)+reducedCircList(circI,3)*sin(t),reducedCircList(circI,2)+reducedCircList(circI,3)*cos(t), 'green');
end

hold off

% subImgSize = round(size( filterImage )/3);
% if indCircI ~= 0
%     filterStepImage = createFiterStepsImage( filterData(imageI).fixation{fixI}.imgFilterSteps(indCircI), subImgSize );
% else
%     filterStepImage = false( size(filterImage) );
% end

subplot('Position',[0.7 0.05 0.3 0.3]);
% imshow(filterStepImage);
imshow(filterData(imageI).fixation{fixI}.imgFilterSteps.skelFilterImage);
hold on

if showInitialFilterCircles
    for circI=1:size(origCircList,1)
        t=0:.01:2*pi;
        plot(origCircList(circI,1)+origCircList(circI,3)*sin(t),origCircList(circI,2)+origCircList(circI,3)*cos(t), 'red');
    end
end

% for circI=1:size(filterCircList,1)
%     t=0:.01:2*pi;
%     plot(filterCircList(circI,1)+filterCircList(circI,3)*sin(t),filterCircList(circI,2)+filterCircList(circI,3)*cos(t), 'magenta');
% end

for circI=1:size(reducedCircList,1)
    t=0:.01:2*pi;
    plot(reducedCircList(circI,1)+reducedCircList(circI,3)*sin(t),reducedCircList(circI,2)+reducedCircList(circI,3)*cos(t), 'green');
end

hold off

end

%% Create filter steps mosaick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function filterStepImage = createFiterStepsImage( filterDataSteps, subImgSize )

if isfield( filterDataSteps, 'regionMask' )
    if ~isempty(filterDataSteps.regionMask)
        regionMask = imresize( imdilate( filterDataSteps.regionMask, strel('disk',2)), subImgSize );
    else
        regionMask = true( subImgSize );
    end
else
    regionMask = true( subImgSize );
end

if isfield( filterDataSteps, 'donutMask' )
    if ~isempty(filterDataSteps.donutMask)
        donutMask = imresize( filterDataSteps.donutMask, subImgSize );
    else
        donutMask = true( subImgSize );
    end
else
    donutMask = true( subImgSize );
end

if isfield( filterDataSteps, 'extractReg' )
    if ~isempty(filterDataSteps.extractReg)
        extractReg = imresize( imdilate( filterDataSteps.extractReg, strel('disk',2)), subImgSize );
    else
        extractReg = true( subImgSize );
    end
else
    extractReg = true( subImgSize );
end

if isfield( filterDataSteps, 'filterReg' )
    if ~isempty(filterDataSteps.filterReg)
        filterReg = imresize( imdilate( filterDataSteps.filterReg, strel('disk',2)), subImgSize );
    else
        filterReg = true( subImgSize );
    end
else
    filterReg = true( subImgSize );
end

if isfield( filterDataSteps, 'lineMask' )
    if ~isempty(filterDataSteps.lineMask)
        lineMask = imresize( filterDataSteps.donutMask, subImgSize );
    else
        lineMask = true( subImgSize );
    end
else
    lineMask = true( subImgSize );
end

if isfield( filterDataSteps, 'intersectMask' )
    if ~isempty(filterDataSteps.intersectMask)
        intersectMask = imresize( filterDataSteps.intersectMask, subImgSize );
    else
        intersectMask = true( subImgSize );
    end
else
    intersectMask = true( subImgSize );
end

if isfield( filterDataSteps, 'circleSliceMask' )
    if ~isempty(filterDataSteps.circleSliceMask)
        circleSliceMask = imresize( imdilate( filterDataSteps.circleSliceMask, strel('disk',2)), subImgSize );
    else
        circleSliceMask = true( subImgSize );
    end
else
    circleSliceMask = true( subImgSize );
end

if isfield( filterDataSteps, 'circleSlice' )
    if ~isempty(filterDataSteps.circleSlice)
        circleSlice = imresize( imdilate( filterDataSteps.circleSlice, strel('disk',2)), subImgSize );
    else
        circleSlice = true( subImgSize );
    end
else
    circleSlice = true( subImgSize );
end

if filterDataSteps.circleAccept
    decision = true( subImgSize );
else
    decision = false( subImgSize );
end

filterStepImage = [donutMask regionMask extractReg;
                   filterReg lineMask intersectMask;
                   circleSliceMask circleSlice decision];
                   
end
