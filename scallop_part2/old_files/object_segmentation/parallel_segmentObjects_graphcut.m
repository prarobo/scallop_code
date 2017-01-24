function [ visualAttnOutData ] = parallel_segmentObjects_graphcut( visualAttnInData, fixationWindowSize, numSegments, clearGraphBorders )
%SEGMENTOBJECTS Segment objects from fixation windows

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch nargin
    case 1
        fixationWindowSize = [200 200];
        numSegments = 10;
        clearGraphBorders = false;
    case 2
        numSegments = 10;
        clearGraphBorders = false;
    case 3
        clearGraphBorders = false;
    case 4
    otherwise
        error('Bloody bonker! imcompatible number of arguments in parallel_segmentObjects_graphcut');
end

visualAttnOutData = visualAttnInData;
visualAttnOutData.params.numSegments = numSegments;
visualAttnOutData.params.clearGraphBorders = clearGraphBorders;
visualAttnOutData.params.fixationWindowSize = fixationWindowSize;

numImages = visualAttnOutData.params.numImages;
imageSize = visualAttnOutData.params.imageSize;
fixationWindowSize = visualAttnOutData.params.fixationWindowSize;


reducedCircList(numImages) = struct;
reducedCircListGraph(numImages) = struct;

%% Segmenting objects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

windowRect = calcRect( visualAttnOutData.fixationData.fixations, imageSize, fixationWindowSize );
foldername = visualAttnOutData.fileInfo.foldername;
filename = visualAttnOutData.fileInfo.filename;
fixationsVar = visualAttnOutData.fixationData.fixationsVar;

if matlabpool('size') == 0
    matlabpool open local 8
end

parfor imageI = 1:numImages
    currImage = imread( sprintf('%s/%s', foldername, filename{imageI} ) );
    
    reducedCircList(imageI).fixation = cell(fixationsVar(imageI),1);
    reducedCircListGraph(imageI).fixation = cell(fixationsVar(imageI),1);
    
    for fixationI = 1:fixationsVar(imageI)        
        fprintf('Segmentation image %d of %d, fixation %d of %d ...',imageI, numImages, fixationI, fixationsVar(imageI) );
        fixationWindow = imcrop( currImage, windowRect{imageI}(fixationI,:) );
        
        [graphImage, labelImage, imgFilterSteps] = segmentGraphCut( fixationWindow, numSegments, clearGraphBorders );
        [filterImage, imgFilterSteps] = scallopFilter_enhance( fixationWindow );
        
        % displayFilters( imgFilterSteps );
        circList = detectPrattCircle_uncombine_regions( fixationWindow, filterImage );        
        reducedCircList(imageI).fixation{fixationI} = filterCircles( circList );
        % displayCircles( imgFilterSteps, circList, reducedCircList );
        
        circListGraph = detectPrattCircle_uncombine_regions( fixationWindow, graphImage );        
        reducedCircListGraph(imageI).fixation{fixationI} = filterCircles( circListGraph );
        
%         displayGraphEdgeSegmentation( currImage, windowRect{imageI}(fixationI,:), labelImage,...
%               graphImage, filterImage, reducedCircList(imageI).fixation{fixationI}, reducedCircListGraph(imageI).fixation{fixationI} );
        
        fprintf('done\n');
    end
end

% matlabpool close 

visualAttnOutData.segmentData.reducedCircList = reducedCircList;
visualAttnOutData.segmentData.reducedCircListGraph = reducedCircListGraph;

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

%% Display Graph Edge Segmentation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displayGraphEdgeSegmentation( origImage, rect, labelImage, graphImage, filterImage, reducedCircList, reducedCircListGraph )

subplot('Position',[0.05 0.5 0.4 0.4]);
imshow( origImage );
rectangle('Position', rect, 'LineWidth', 2, 'EdgeColor','red');

subplot('Position',[0.5 0.5 0.4 0.4]);
fixationWindow = imcrop( origImage, rect );
imshow( fixationWindow );

hold on

for circI=1:size(reducedCircList,1)
    t=0:.01:2*pi;
    plot(reducedCircList(circI,1)+reducedCircList(circI,3)*sin(t),reducedCircList(circI,2)+reducedCircList(circI,3)*cos(t), 'red');
end

for circI=1:size(reducedCircListGraph,1)
    t=0:.01:2*pi;
    plot(reducedCircListGraph(circI,1)+reducedCircListGraph(circI,3)*sin(t),reducedCircListGraph(circI,2)+reducedCircListGraph(circI,3)*cos(t), 'green');
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

for circI=1:size(reducedCircList,1)
    t=0:.01:2*pi;
    plot(reducedCircList(circI,1)+reducedCircList(circI,3)*sin(t),reducedCircList(circI,2)+reducedCircList(circI,3)*cos(t), 'red');
end
hold off

bwImage = zeros(size(graphImage,1), size(graphImage,2), 3);
bwImage(:,:,1) = graphImage.*255;
bwImage(:,:,2) = graphImage.*255;
bwImage(:,:,3) = graphImage.*255;
bwImage = im2uint8( bwImage );

subplot('Position',[0.35 0.05 0.3 0.3]);
imshow(label2rgb(labelImage));

subplot('Position',[0.7 0.05 0.3 0.3]);
imshow(bwImage);
hold on

for circI=1:size(reducedCircListGraph,1)
    t=0:.01:2*pi;
    plot(reducedCircListGraph(circI,1)+reducedCircListGraph(circI,3)*sin(t),reducedCircListGraph(circI,2)+reducedCircListGraph(circI,3)*cos(t), 'green');
end
hold off

end





