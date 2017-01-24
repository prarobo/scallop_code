function [ visualAttnOutData ] = segmentObjects( visualAttnInData )
%SEGMENTOBJECTS Segment objects from fixation windows

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

visualAttnOutData = visualAttnInData;
numImages = visualAttnOutData.params.numImages;
imageSize = visualAttnOutData.params.imageSize;
fixationWindowSize = visualAttnOutData.params.fixationWindowSize;

visualAttnOutData.segmentData.reducedCircList(numImages) = struct;

%% Segmenting objects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

windowRect = calcRect( visualAttnOutData.fixationData.fixations, imageSize, fixationWindowSize );
    
for imageI = 1:numImages
    currImage = imread( sprintf('%s/%s', visualAttnOutData.fileInfo.foldername, visualAttnOutData.fileInfo.filename{imageI} ) );
    visualAttnOutData.segmentData.reducedCircList(imageI).fixation = cell(visualAttnOutData.fixationData.fixationsVar(imageI),1);
    
    for fixationI = 1:visualAttnOutData.fixationData.fixationsVar(imageI)        
        fprintf('Segmentation image %d of %d, fixation %d of %d ...',imageI, numImages, fixationI, visualAttnOutData.fixationData.fixationsVar(imageI) );
        fixationWindow = imcrop( currImage, windowRect{imageI}(fixationI,:) );
        
        [filterImage, imgFilterSteps] = scallopFilter_enhance( fixationWindow );
        % displayFilters( imgFilterSteps );
        circList = detectPrattCircle( fixationWindow, filterImage );
        visualAttnOutData.segmentData.reducedCircList(imageI).fixation{fixationI} = filterCircles( circList );
        % displayCircles( imgFilterSteps, circList, reducedCircList );
        fprintf('done\n');
    end
end

end

%% Display different filter steps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displayFilters( imgFilterSteps )

subplot(241)
imshow(imgFilterSteps.orig);

subplot(242)
imshow(imgFilterSteps.edge);

subplot(243)
imshow(imgFilterSteps.dilate);

subplot(244)
imshow(imgFilterSteps.imgLargeSmallRegions);

subplot(245)
imshow(imgFilterSteps.width);

subplot(246)
imshow(imgFilterSteps.widthheight);

subplot(247)
imshow(imgFilterSteps.solid);

subplot(248)
imshow(imgFilterSteps.final);

end

%% Display different circles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displayCircles( imgFilterSteps, circList, reducedCircList )

subplot(221)
imshow(imgFilterSteps.orig);

subplot(222)
imshow(imgFilterSteps.orig);
hold on

for ind=1:size(reducedCircList,1)
    t=0:.01:2*pi;
    plot(reducedCircList(ind,1)+reducedCircList(ind,3)*sin(t),reducedCircList(ind,2)+reducedCircList(ind,3)*cos(t));
end
hold off

subplot(223)
bwImage = zeros(size(imgFilterSteps.orig));
bwImage(imgFilterSteps.final==1)=255;
bwImage(:,:,2) = bwImage(:,:,1);
bwImage(:,:,3) = bwImage(:,:,1);

imshow(bwImage);
hold on

for ind=1:size(circList,1)
    t=0:.01:2*pi;
    plot(circList(ind,1)+circList(ind,3)*sin(t),circList(ind,2)+circList(ind,3)*cos(t));
end
hold off

subplot(224)
bwImage = zeros(size(imgFilterSteps.orig));
bwImage(imgFilterSteps.final==1)=255;
bwImage(:,:,2) = bwImage(:,:,1);
bwImage(:,:,3) = bwImage(:,:,1);

imshow(bwImage);
hold on

for ind=1:size(reducedCircList,1)
    t=0:.01:2*pi;
    plot(reducedCircList(ind,1)+reducedCircList(ind,3)*sin(t),reducedCircList(ind,2)+reducedCircList(ind,3)*cos(t));
end
hold off

end

%% Filter Circle List
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function reducedCircleList = filterCircles( circList )

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numCircles = size(circList,1);
circleAccept = true(numCircles,1);
minRadius = 10;
maxRadius = 40;
radiusTolerancePercent = 0.1;
centerToleranceDistance = 10;

%% Circle Radius Filter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for circI = 1:numCircles
    if(circleAccept(circI))
        if( circList(circI,3) < minRadius || circList(circI,3) > maxRadius )
            circleAccept(circI) = false;
        end
    end
end

%% Circle Nearness Filter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for circI = 1:numCircles-1
    if(circleAccept(circI))        
        for circI2 = circI+1:numCircles
            if(circleAccept(circI2))
                if( ( circList(circI2,3) > (1-radiusTolerancePercent)*circList(circI,3) ||...
                        circList(circI2,3) < (1+radiusTolerancePercent)*circList(circI,3) ) && ...
                        euclideanDistance( circList(circI2,1), circList(circI2,2), circList(circI,1), circList(circI,2) ) < centerToleranceDistance )
                           circleAccept(circI2) = false;
                           circList(circI,1) = ( circList(circI,1) + circList(circI2,1) )/ 2;
                           circList(circI,2) = ( circList(circI,2) + circList(circI2,2) )/ 2;
                           circList(circI,3) = ( circList(circI,3) + circList(circI2,3) )/ 2;                    
                end
            end
        end
    end
end

%% Filtered circle list
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

reducedCircleList = zeros( sum( circleAccept(:) ), 3 );
currI=1;

for circI = 1:numCircles
    if(circleAccept(circI))
        reducedCircleList(currI,:) = circList(circI,:);
        currI=currI+1;
    end
end

end







