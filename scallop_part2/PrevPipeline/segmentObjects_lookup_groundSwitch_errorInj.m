function [ segmentData, graphData ] ...
    = segmentObjects_lookup_groundSwitch_errorInj( fixationData, groundTruth, params, fileInfo, varargin )
%SEGMENTOBJECTS Segment objects from fixation windows

%% Initialization

switch nargin
    case 4
        storeProcessData = false;
        parallelOn = true;
        segmentType = 'graph';
        errorInject = false;
        errorVal = [2 0.1];
    case 5
        storeProcessData = varargin{1};
        parallelOn = true;
        segmentType = 'graph';
        errorInject = false;
        errorVal = [2 0.1];
    case 6
        storeProcessData = varargin{1};
        parallelOn = varargin{2};
        segmentType = 'graph';
        errorInject = false;
        errorVal = [2 0.1];
    case 7
        storeProcessData = varargin{1};
        parallelOn = varargin{2};
        segmentType = varargin{3};
        errorInject = false;
        errorVal = [2 0.1];
    case 8
        storeProcessData = varargin{1};
        parallelOn = varargin{2};
        segmentType = varargin{3};
        errorInject = varargin{4};
        errorVal = [2 0.1];
    case 9
        storeProcessData = varargin{1};
        parallelOn = varargin{2};
        segmentType = varargin{3};
        errorInject = varargin{4};
        errorVal = varargin{5};        
    otherwise
        error('Bloody bonkers! imcompatible number of arguments in %s', mfilename);
end

global numPoolWorkers
numImages = params.numImages;
imageSize = params.imageSize;
fixationWindowSize = params.fixationWindowSize;
numSegments = params.numSegments;

clearGraphBorders = false;

reducedCircList(numImages) = struct;
if storeProcessData
    filterData(numImages) = struct;
    labelData(numImages) = struct;
end

if parallelOn && storeProcessData
    error('Parallel processing and storing process data cannot be done at the same time, error in function %s', mfilename);
end    

% if strcmp(segmentType, 'ground') && storeProcessData
%     error('Cannot do ground truth segmentation and store process at the same time, error in function %s', mfilename);
% end

%% Segmenting objects

foldername = fileInfo.foldername;
filename = fileInfo.filename;
fixationsVar = fixationData.fixationsVar;
reducedCircList(numImages) = struct;
windowRect = calcRect( fixationData.fixations, imageSize, fixationWindowSize );

for imageI = 1:numImages
    numFixations = fixationsVar(imageI);
    currWindowRect = windowRect{imageI};
    
    if strcmp(segmentType, 'graph')    
        currImage = imresize(imread( sprintf('%s/%s', foldername, filename{imageI} ) ),params.resizeFactor);
        currNumSegments = numSegments;
    elseif strcmp(segmentType, 'ground')
        [ currImage, currNumSegments] = createGroundScallopImage( groundTruth(imageI), imageSize, errorInject, errorVal );
    else
        error('Unknown segmentation type, choose between graph and ground, error in function %s', mfilename);
    end

    if storeProcessData
        filterCirc = cell(numFixations,1);
        labelCirc = cell(numFixations,1);
    end        
    fixationCirc = cell(numFixations,1);
    
    if parallelOn
        if matlabpool('size') == 0
            matlabpool(numPoolWorkers)
        end
        parfor fixationI = 1:numFixations
            [finalCircList, ~, ~] = processSegmentObjects( currImage, storeProcessData, ...
                                                            imageI, numImages, fixationI, numFixations, currNumSegments,...
                                                            currWindowRect, clearGraphBorders );
            fixationCirc{fixationI} = finalCircList;                                            
        end
    else
        for fixationI = 1:numFixations
            [finalCircList, filterFixData, labelFixData] = processSegmentObjects( currImage, storeProcessData, ...
                                                           imageI, numImages, fixationI, numFixations, currNumSegments,...
                                                           currWindowRect, clearGraphBorders );
            fixationCirc{fixationI} = finalCircList;
            filterCirc{fixationI} = filterFixData;
            labelCirc{fixationI} = labelFixData;            
        end
     end
    reducedCircList(imageI).fixation = fixationCirc;
    if storeProcessData
        labelData(imageI).fixation = labelCirc;
        filterData(imageI).fixation = filterCirc;
    end 
end

%% Outputs

if storeProcessData
    graphData.labelData = labelData;
    save('filterData.mat', 'filterData');
else
    graphData = [];
end
segmentData.reducedCircList = reducedCircList;

end

%% Function to create ground truth scallop image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ currImage, currNumSegments] = createGroundScallopImage( groundTruthImage, imageSize, errorInject, errorVal )

persistent shapeInserterWhite;
if isempty(shapeInserterWhite)
    shapeInserterWhite = vision.ShapeInserter('Shape','Circles','Fill',true,'FillColor','White','Opacity',1);
end

currImage = uint8( zeros(imageSize(1:2)) );
for scallopI = 1:groundTruthImage.numScallops
    currScallop = round(groundTruthImage.loc(scallopI,:));

    if errorInject
        centerX = currScallop(1) + generateError( errorVal(1) );
        centerY = currScallop(2) + generateError( errorVal(1) );
        radius = currScallop(3)*(1+generateError( errorVal(2) ));
    else
        centerX = currScallop(1);
        centerY = currScallop(2);
        radius = currScallop(3);
    end

    circlesWhite = int32(round([centerX centerY radius]));
    currImage = step(shapeInserterWhite, currImage, circlesWhite);
    % imshow(currImage);
end

currNumSegments = groundTruthImage.numScallops + 1;

end

%% Segment Objects Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [finalCircList, filterData, labelData] = processSegmentObjects( currImage, storeProcessData, ...
                                     imageI, numImages, fixationI, numFixations, numSegments,...
                                     windowRect, clearGraphBorders )

    fprintf('Segmentation image %d of %d, fixation %d of %d ...',imageI, numImages, fixationI, numFixations );
    fixationWindow = imcrop( currImage, windowRect(fixationI,:) );
    % figure; imshow(currImage);
    % figure; imshow(fixationWindow);
    
    % [graphImage, labelImage, imgFilterSteps] = segmentGraphCut_resize( fixationWindow, numSegments, clearGraphBorders );
    [graphImage, labelImage, imgFilterSteps] = segmentGraphCut( fixationWindow, numSegments, clearGraphBorders );
    [filterImage, imgFilterSteps] = scallopFilter_enhance( fixationWindow, imgFilterSteps );
    % [skelFilterImage, imgFilterSteps] = scallopFilter_graph( filterImage, labelImage, imgFilterSteps );
    
    % figure; imshow(filterImage);
    % figure; imshow(skelFilterImage);
    
    % displayFilters( imgFilterSteps );
    % origCircList = detectPrattCircle_uncombine_regions( fixationWindow, filterImage );
    % origCircList = detectPrattCircle( fixationWindow, filterImage );
    [origCircList, imgFilterSteps] = detectTaubinCircle_graph( fixationWindow, filterImage, labelImage, imgFilterSteps );
    % filterCircList = filterCircles( origCircList, size(fixationWindow) );
    % [finalCircList, imgFilterStepsGraph] = filterCirclesGraph( filterCircList, graphImage, labelImage, filterImage, params );
    % finalCircList = filterCircList;
    finalCircList = origCircList;
    
    % skelCircList = detectPrattCircle( fixationWindow, skelFilterImage );
    % skelFilterCircList = filterCircles( skelCircList );
    
    % displayCircles( imgFilterSteps, finalCircList, origCircList );
    
    
    % displayGraphEdgeSegmentation( currImage, windowRect{imageI}(fixationI,:), labelImage,...
    %               graphImage, filterImage, reducedCircList(imageI).fixation{fixationI}, filterCircList, origCircList );
    
        
    if storeProcessData
        labelData = labelImage;
        filterData.labelImage = labelImage;
        filterData.filterImage = filterImage;
        filterData.fixationWindow = fixationWindow;
        filterData.origCircList = origCircList;
        % filterData.filterCircList = filterCircList;
        filterData.reducedCircList = finalCircList;
        filterData.imgFilterSteps = imgFilterSteps;
        % filterData.imgFilterSteps = imgFilterStepsGraph;
    else
        labelData = [];
        filterData = [];
    end
    fprintf('done\n');

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

%% Filter Circle List based on graph cut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ newCircList, imgFilterSteps ] = filterCirclesGraph( circList, graphImage, labelImage, filterImage, params )

% Initialization
numCircles = size(circList,1);
circleAccept = true(numCircles,1);
% figure; imshow(label2rgb(labelImage));
% figure; imshow(graphImage);
% figure; imshow(filterImage);

contourLengthErrorPercent = params.contourLengthErrorPercent;
minContourLengthPercent = params.minContourLengthPercent;
areaThresholdPercent = params.contourGraphAreaThresholdPercent;
donutRad = params.donutGraphThicknessPercent;

if numCircles ~= 0
    imgFilterSteps(numCircles) = struct;
else
    imgFilterSteps = struct;
end

% Circle Check
for circI = 1:numCircles
    
    imgFilterSteps(circI).circleAccept = false;
    
    % Circle Mask
    [x,y]=meshgrid(-(circList(circI,1)-1):(size(graphImage,2)-circList(circI,1)),-(circList(circI,2)-1):(size(graphImage,1)-circList(circI,2)));
    circleMask=((x.^2+y.^2)<=circList(circI,3)^2);
    imgFilterSteps(circI).circleMask = circleMask;
    %     figure; imshow(circleMask)
    %     axis equal
    
    % Area Filter
    regPoints = labelImage(circleMask);
    maskArea = numel(regPoints);
    maxReg = mode(regPoints);
    maxRegArea = sum( regPoints == maxReg );
    
    % Rejecting circles not belonging to a region
    if maxRegArea < areaThresholdPercent * maskArea
        circleAccept(circI) = false;
        continue;
    end
    
    % Principle region
    regionMask = (labelImage == maxReg);
    regionMask = bwperim( regionMask );
    boundaryMask = bwperim( true( size( regionMask ) ) );
    regionMask = regionMask & (~boundaryMask);
    imgFilterSteps(circI).regionMask = regionMask;
    % figure; imshow(regionMask);
    
    % Donut mask
    dialRad = round(donutRad*circList(circI,3));
    donutMask = imdilate( bwperim(circleMask), strel('disk',dialRad));
    imgFilterSteps(circI).donutMask = donutMask;
    % figure;imshow(donutMask);
    
    % Extracted region boundary
    extractReg = donutMask & regionMask;
    imgFilterSteps(circI).extractReg = extractReg;
    % figure;imshow(extractReg);
    
    % Filter region boundary
    fillReg = imfill(extractReg,'holes');
    if sum(fillReg(:)) - sum(extractReg(:)) <= 0.1*sum(extractReg(:))
        extractReg = fillReg;
    end
    extractReg = bwmorph( extractReg, 'skel');
    extractReg = bwmorph( extractReg, 'spur' );
    connComp = bwconncomp(extractReg);
    contourVect = cellfun(@numel, connComp.PixelIdxList);
    maxContour = find( contourVect == max(contourVect), 1, 'first' );
    filterReg = false(size(extractReg));
    filterReg(connComp.PixelIdxList{maxContour}) = true;
    imgFilterSteps(circI).filterReg = filterReg;
    % figure;imshow(filterReg);
    
    % checking for empty region
    if sum( filterReg(:) ) < minContourLengthPercent * 2 * pi * circList(circI,3)
        circleAccept(circI) = false;
        continue;
    end
    
    % Finding skeleton edges
    [edgePoints.y, edgePoints.x] = find( bwmorph( filterReg, 'endpoints') );
    if length(edgePoints.x) > 2
        iter = 0;
        trimImage = filterReg;
        % figure; imshow(trimImage);
        skelEdges = edgePoints;
        while length(skelEdges.x) > 2
            iter = iter+1;
            if iter > 100
                save('temp.mat');
                error('More than 100 iterations but still many end points, boo!');
            end
            
            [skelEdges.y, skelEdges.x] = find( bwmorph( trimImage, 'endpoints') & trimImage );
            [branchPoints.y, branchPoints.x] = find( bwmorph( trimImage, 'branchpoints') );
            
            numEdgePts = length(skelEdges.x);
            numBranchPts = length(branchPoints.x);
            distVect = zeros( numEdgePts, 1);
            
            for edgeI = 1:numEdgePts
                minDist = inf;
                for branchI = 1:numBranchPts
                    currDist = euclideanDistance( skelEdges.x(edgeI), skelEdges.y(edgeI), branchPoints.x(branchI), branchPoints.y(branchI));
                    if currDist < minDist
                        minDist = currDist;
                    end
                end
                distVect(edgeI) = minDist;
            end
            
            [~,ind] = min(distVect);
            trimImage( skelEdges.y(ind), skelEdges.x(ind) ) = false;
            % figure;imshow(trimImage);
        end
        
        if length(skelEdges.x) <= 1
            if abs( 2 * pi * circList(circI,3) - sum( trimImage(:) ) ) > 2 * pi * circList(circI,3) * contourLengthErrorPercent
                circleAccept(circI) = false;
                continue;
            else
                imgFilterSteps(circI).circleAccept = true;
                continue;
            end
        end
        
    % figure;imshow(filterReg);
    % error('Bloody hell! More than 2 skeleton end points found, I quit');
    elseif length(edgePoints.x) <= 1
        if abs( 2 * pi * circList(circI,3) - sum( filterReg(:) ) ) > 2 * pi * circList(circI,3) * contourLengthErrorPercent
            circleAccept(circI) = false;
            continue;
        else
            imgFilterSteps(circI).circleAccept = true;
            continue;
        end
        
        % figure;imshow(filterReg);
        % error('Bloody hell! Less than 2 skeleton end points found, I quit');
    else
        skelEdges = edgePoints;
    end

    % Line eqn connecting skeleton edges
    lineEqn = lineEqn2Pt( skelEdges.x(1), skelEdges.y(1), skelEdges.x(2), skelEdges.y(2) );
    
    % Perpendicular bisector eqn
    midX = mean( skelEdges.x );
    midY = mean( skelEdges.y );
    m =  -1/(  (skelEdges.y(2)-skelEdges.y(1))/(skelEdges.x(2)-skelEdges.x(1)) );
    perpenLineEqn = lineEqnSlopePt( midX, midY, m );
    
    % Line Mask
    lineMask = constructLineMask( perpenLineEqn, midX, midY, filterReg );
    imgFilterSteps(circI).lineMask = lineMask;
    % figure;imshow(lineMask)
    
    % Find intersection with extracted region boundary
    intersectMask = lineMask & filterReg;
    imgFilterSteps(circI).intersectMask = imdilate( intersectMask, strel('disk',2));
    % figure; imshow(imdilate( intersectMask, strel('disk',2)));
    
    [intersectPoint.y, intersectPoint.x] = find( intersectMask, 1 );
    if isempty(intersectPoint.x)
        subplot(121);   imshow(filterReg);
        subplot(122);   imshow(lineMask);
        error('No intersection point found in graphcut segmentation filter');
    end
    
    if lineEqn.a * intersectPoint.x + lineEqn.b * intersectPoint.y + lineEqn.c >= 0
        [x,y] = meshgrid(1:size(filterReg,2),1:size(filterReg,1));
        circleSliceMask = ( lineEqn.a * x + lineEqn.b * y + lineEqn.c >= 0 );
    else
        [x,y] = meshgrid(1:size(filterReg,2),1:size(filterReg,1));
        circleSliceMask = ( lineEqn.a * x + lineEqn.b * y + lineEqn.c < 0 );
    end
    imgFilterSteps(circI).circleSliceMask = circleSliceMask;
    % figure; imshow(circleSliceMask);
    
    % Extracting circle slice
    circleSlice = bwperim(circleMask) & circleSliceMask;
    imgFilterSteps(circI).circleSlice = circleSlice;
    % figure; imshow(circleSlice);
    
    % Extracting slice of filter region
    filterReg = filterReg & circleSliceMask;
    
    % Getting lengths of contour and circle slice 
    circleSliceLength = sum( circleSlice(:) );
    contourLength = sum( filterReg(:) );
    
    % Remove slices and contours with more than w% error
    imgFilterSteps(circI).circleSliceLength = circleSliceLength;
    imgFilterSteps(circI).contourLength = contourLength;
    if abs( circleSliceLength - contourLength ) > circleSliceLength * contourLengthErrorPercent
        circleAccept(circI) = false;
        continue;
    end
    
    % Remove contours which are too short
    if circleSliceLength  < minContourLengthPercent * 2 * pi * circList(circI,3)
        circleAccept(circI) = false;
        continue;
    end
    
    imgFilterSteps(circI).circleAccept = true;
    
    %     figure;
    %     subplot(231);   imshow(filterImage);
    %     subplot(232);   imshow(label2rgb(labelImage));
    %     subplot(234);   imshow(circleSlice);
    %     subplot(235);   imshow(filterReg);
    
end

newCircList = circList( circleAccept, : );

end

%% Compute Line Mask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function lineMask = constructLineMask( perpenLineEqn, midX, midY, filterReg )

    if perpenLineEqn.b == -1
        x_1 = 1:size(filterReg,2);
        ind = (abs(x_1-midX) > 5);
        x_1 = x_1(ind);
        y_1 = perpenLineEqn.a * x_1 + perpenLineEqn.c;
        ind = (y_1>1) & (y_1<size(filterReg,1));
        x_1 = x_1(ind);
        y_1 = y_1(ind);

        
        y_2 = 1:size(filterReg,1);
        ind = (abs(y_2-midY) > 5);
        y_2 = y_2(ind);
        x_2 = (y_2 - perpenLineEqn.c)/perpenLineEqn.a;
        ind = (x_2>1) & (x_2<size(filterReg,2));
        x_2 = x_2(ind);
        y_2 = y_2(ind);
        
        x = [x_1';x_2'];
        y = [y_1';y_2'];
        
        rx = round(x);
        ry = round(y);
        err = abs(x-rx) + abs(y-ry);
        mat = [x y rx ry err];
        % mat = sortrows(mat, 3);
        
        if size(mat,1) < 2
            error('Number of rows in line construction matrix less than 2, bloody hell!');
        end        
        
        if range(rx) > range(ry)
            ind = (rx==min(rx));
            terr = err(ind);
            ty = ry(ind);
            ind = (terr == min(terr));
            x1 = min(rx);
            y1 = ty(ind);

            ind = (rx==max(rx));
            terr = err(ind);
            ty = ry(ind);
            ind = (terr == min(terr));
            x2 = max(rx);
            y2 = ty(ind);
        else
            ind = (ry==min(ry));
            terr = err(ind);
            tx = rx(ind);
            ind = (terr == min(terr));
            x1 = tx(ind);
            y1 = min(ry);

            ind = (ry==max(ry));
            terr = err(ind);
            tx = rx(ind);
            ind = (terr == min(terr));
            x2 = tx(ind);
            y2 = max(ry);
        end            
        %         x1 = mat(1,3);
        %         x2 = mat(2,3);
        %         y1 =  mat(1,4);
        %         y2 =  mat(2,4);
    else
        x1 = - round( perpenLineEqn.c );
        x2 = - round(  perpenLineEqn.c );
        y1 = 1;
        y2 = size(filterReg,1);
        if -round(  perpenLineEqn.c ) > size(filterReg,2) || -round(  perpenLineEqn.c ) < 1
            error('Perpendicular line outside limits (currVal = %d, limits: 0 - %d), bloody hell!',...
                round(  perpenLineEqn.c ), size(filterReg,1));
        end
    end
    
    %     if y1>size(filterReg,1)
    %         y1=size(filterReg,1);
    %     elseif y1<1
    %         y1=1;
    %     end
    %     if y2>size(filterReg,1)
    %         y2=size(filterReg,1);
    %     elseif y2<1
    %         y2=1;
    %     end
    
    lineMask = logical( rgb2gray(insertShape( zeros( size(filterReg) ), 'Line', [x1 y1 x2 y2] )) );    
end

%% Display Graph Edge Segmentation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displayGraphEdgeSegmentation( origImage, rect, labelImage, graphImage, filterImage, reducedCircList, filterCircList, origCircList )

subplot('Position',[0.05 0.5 0.4 0.4]);
imshow( origImage );
rectangle('Position', rect, 'LineWidth', 2, 'EdgeColor','red');

subplot('Position',[0.5 0.5 0.4 0.4]);
fixationWindow = imcrop( origImage, rect );
imshow( fixationWindow );

hold on

for circI=1:size(origCircList,1)
    t=0:.01:2*pi;
    plot(origCircList(circI,1)+origCircList(circI,3)*sin(t),origCircList(circI,2)+origCircList(circI,3)*cos(t), 'red');
end

for circI=1:size(filterCircList,1)
    t=0:.01:2*pi;
    plot(filterCircList(circI,1)+filterCircList(circI,3)*sin(t),filterCircList(circI,2)+filterCircList(circI,3)*cos(t), 'magenta');
end

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

for circI=1:size(origCircList,1)
    t=0:.01:2*pi;
    plot(origCircList(circI,1)+origCircList(circI,3)*sin(t),origCircList(circI,2)+origCircList(circI,3)*cos(t), 'red');
end

for circI=1:size(filterCircList,1)
    t=0:.01:2*pi;
    plot(filterCircList(circI,1)+filterCircList(circI,3)*sin(t),filterCircList(circI,2)+filterCircList(circI,3)*cos(t), 'magenta');
end

for circI=1:size(reducedCircList,1)
    t=0:.01:2*pi;
    plot(reducedCircList(circI,1)+reducedCircList(circI,3)*sin(t),reducedCircList(circI,2)+reducedCircList(circI,3)*cos(t), 'green');
end

hold off

% bwImage = zeros(size(graphImage,1), size(graphImage,2), 3);
% bwImage(:,:,1) = graphImage.*255;
% bwImage(:,:,2) = graphImage.*255;
% bwImage(:,:,3) = graphImage.*255;
% bwImage = im2uint8( bwImage );

subplot('Position',[0.35 0.05 0.3 0.3]);
imshow(label2rgb(labelImage));
hold on

for circI=1:size(origCircList,1)
    t=0:.01:2*pi;
    plot(origCircList(circI,1)+origCircList(circI,3)*sin(t),origCircList(circI,2)+origCircList(circI,3)*cos(t), 'red');
end

for circI=1:size(filterCircList,1)
    t=0:.01:2*pi;
    plot(filterCircList(circI,1)+filterCircList(circI,3)*sin(t),filterCircList(circI,2)+filterCircList(circI,3)*cos(t), 'magenta');
end

for circI=1:size(reducedCircList,1)
    t=0:.01:2*pi;
    plot(reducedCircList(circI,1)+reducedCircList(circI,3)*sin(t),reducedCircList(circI,2)+reducedCircList(circI,3)*cos(t), 'green');
end

hold off

% subplot('Position',[0.7 0.05 0.3 0.3]);
% imshow(bwImage);
% hold on

% for circI=1:size(reducedCircListGraph,1)
%     t=0:.01:2*pi;
%     plot(reducedCircListGraph(circI,1)+reducedCircListGraph(circI,3)*sin(t),reducedCircListGraph(circI,2)+reducedCircListGraph(circI,3)*cos(t), 'green');
% end
% hold off

end

%% Generate Error
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function genError =  generateError( errorLimit )

currError = rand;
if errorLimit > 0
    genError = currError * errorLimit;
else
    error('Negtive errors cannot be generated, error in function %s',mfilename);
end

errorSign = rand;
if errorSign < 0.5
    genError = -genError;
end

end

































