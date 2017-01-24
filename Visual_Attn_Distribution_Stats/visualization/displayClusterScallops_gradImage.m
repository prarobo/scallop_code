function displayClusterScallops_gradImage( params, clusterData, scallopInfo, fileInfo, annulusOn )
%DISPLAYCLUSTERSCALLOPS Display scallop clustering

%% Initialization
numClusters = params.numClusters;
scallopCluster = cell(numClusters,1);
scallopClusterNum = zeros(numClusters,1);

%% Processing cluster information
for clusterI = 1:numClusters
    scallopCluster{clusterI} = find( clusterData.id == clusterI );
    scallopClusterNum(clusterI) = numel( scallopCluster{clusterI} );
end

%% GUI with keyboard input
if numClusters ~= 4
    error('GUI not designed for more than 4 clusters');
end

currClusterIndex = ones(numClusters,1);
prevClusterIndex = zeros(numClusters,1);
figure;

while true

    prevClusterIndex = displayNow( params, scallopInfo, currClusterIndex, prevClusterIndex, scallopCluster, fileInfo, annulusOn );
    
    ch = waitforbuttonpress;
    if ch == 1
        key = get(gcf,'CurrentCharacter');
        switch key
            case 'w'
                if currClusterIndex(1) ~= 1
                    currClusterIndex(1) = currClusterIndex(1)-1;
                else
                    currClusterIndex(1) = scallopClusterNum(1);
                end
            case 's'               
                if currClusterIndex(1) ~= scallopClusterNum(1)
                    currClusterIndex(1) = currClusterIndex(1)+1;
                else
                    currClusterIndex(1) = 1;
                end
            case 'e'
                if currClusterIndex(2) ~= 1
                    currClusterIndex(2) = currClusterIndex(2)-1;
                else
                    currClusterIndex(2) = scallopClusterNum(2);
                end
            case 'd'               
                if currClusterIndex(2) ~= scallopClusterNum(2)
                    currClusterIndex(2) = currClusterIndex(2)+1;
                else
                    currClusterIndex(2) = 1;
                end
            case 'r'
                if currClusterIndex(3) ~= 1
                    currClusterIndex(3) = currClusterIndex(3)-1;
                else
                    currClusterIndex(3) = scallopClusterNum(3);
                end
            case 'f'               
                if currClusterIndex(3) ~= scallopClusterNum(3)
                    currClusterIndex(3) = currClusterIndex(3)+1;
                else
                    currClusterIndex(3) = 1;
                end
            case 't'
                if currClusterIndex(4) ~= 1
                    currClusterIndex(4) = currClusterIndex(4)-1;
                else
                    currClusterIndex(4) = scallopClusterNum(4);
                end
            case 'g'               
                if currClusterIndex(4) ~= scallopClusterNum(4)
                    currClusterIndex(4) = currClusterIndex(4)+1;
                else
                    currClusterIndex(4) = 1;
                end
            case 'q'
                close(gcf);
                break;
            otherwise
                disp('w e r t-next cluster image, s d f g-previous cluster image, q-quit');
        end
    else
        disp('w e r t-next cluster image, s d f g-previous cluster image, q-quit');
    end
end

end

%% Display now function, shows images interactively
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function currClusterIndex = displayNow( params, scallopInfo, currClusterIndex, prevClusterIndex, scallopCluster, fileInfo, annulusOn )

numClusters = params.numClusters;
for clusterI = 1:numClusters
    if currClusterIndex( clusterI ) ~= prevClusterIndex( clusterI )
        filename = sprintf('%s/%s', fileInfo.foldername, scallopInfo.filename{ scallopCluster{clusterI}(currClusterIndex(clusterI)) } );
        currImage = imread( filename );
        cropImage = imcrop( currImage, scallopInfo.rect( scallopCluster{clusterI}(currClusterIndex(clusterI)),:));
        adjustImage = enhanceRGBImage( cropImage );
        [gradMagImage, gradDirImage] = imgradient( rgb2gray( adjustImage ));
        % figure; imshow( cropImage );
        % figure; imshow( adjustImage );
        
        if annulusOn
            cropImage = applyAnnulus( cropImage, params, ...
                scallopInfo.loc( scallopCluster{clusterI}(currClusterIndex(clusterI)),:), ...
                scallopInfo.diff( scallopCluster{clusterI}(currClusterIndex(clusterI)),:) );
            gradMagImage = applyAnnulus( gradMagImage, params, ...
                scallopInfo.loc( scallopCluster{clusterI}(currClusterIndex(clusterI)),:), ...
                scallopInfo.diff( scallopCluster{clusterI}(currClusterIndex(clusterI)),:) );
            gradDirImage = applyAnnulus( gradDirImage, params, ...
                scallopInfo.loc( scallopCluster{clusterI}(currClusterIndex(clusterI)),:), ...
                scallopInfo.diff( scallopCluster{clusterI}(currClusterIndex(clusterI)),:) );            
        end

        subplot(3, numClusters, clusterI);        
        % imshow(cropImage);
        imshow(adjustImage);

        subplot(3, numClusters, numClusters+clusterI);        
        image(gradMagImage);
        axis off
        
        subplot(3, numClusters, 2*numClusters+clusterI);
        image(gradDirImage);
        axis off
    end
end

end

%% Applies annulus mask to image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function outImage = applyAnnulus( inImage, params, scallopLoc, scallopDiff )

%% initialization
numLayers = size(inImage,3);
outImage = inImage;
radiusConstrictionFactor = params.radiusConstrictionFactor;
radius = scallopLoc(3);
centerX = (size(inImage,2)/2) - scallopDiff(1);
centerY = (size(inImage,1)/2) - scallopDiff(2);

persistent shapeInserterWhite;
if isempty(shapeInserterWhite)
     shapeInserterWhite = vision.ShapeInserter('Shape','Circles','Fill',true,'FillColor','White','Opacity',1);
end

persistent shapeInserterBlack;
if isempty(shapeInserterBlack)
     shapeInserterBlack = vision.ShapeInserter('Shape','Circles','Fill',true,'FillColor','Black','Opacity',1);
end

%% Create mask
if ~(radiusConstrictionFactor > 1 && radiusConstrictionFactor < 2)
    error('Bloody bullocks! Radius constriction factor is not within 1-2 in function %s', mfilename);
end
whiteRadius = radius * radiusConstrictionFactor;
blackRadius = radius * (1-abs(1-radiusConstrictionFactor));

circlesWhite = int32([centerX centerY whiteRadius]);
circlesBlack = int32([centerX centerY blackRadius]);
mask = step(shapeInserterWhite, zeros(size(inImage,1), size(inImage,2)), circlesWhite);
mask = step(shapeInserterBlack, mask, circlesBlack);
mask = logical(mask);

switch class( inImage )
    case 'uint8'
        mask = uint8(mask);
    case 'double'
        mask = double(mask);
    otherwise
        error('Incompatible image class type: %s, error in function %s', class(inImage), mfilename );
end        

%% Apply mask
for layerI = 1:numLayers
    outImage(:,:,layerI) = outImage(:,:,layerI) .* mask;
end
    
end










