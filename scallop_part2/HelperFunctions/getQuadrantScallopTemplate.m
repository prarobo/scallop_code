function [ numResegScallops, resegAvailable, repMeanScallop, repStddevScallop ] = getQuadrantScallopTemplate( scallopX, scallopY, scallopRad, testRadius, radiusExtnPercent, ...
                                                                                        foldername, filenames)
%GETQUADRANTHOG Get the HOG descriptors for all scallops in a single
%quadrant

%% Initialization
numScallops = length(scallopX);
resegAvailable = true;
repScallop = 0;

%% Main
if numScallops == 0
    resegAvailable = false;
    numResegScallops = 0;    
else
    numResegScallops = numScallops;
    extnTestDia = round(2.*((1+radiusExtnPercent)*testRadius));
    scallopData = zeros(extnTestDia ,extnTestDia , numScallops);
    currInd = 0;
    
    for scallopI = 1:numScallops
        currX = scallopX(scallopI);
        currY = scallopY(scallopI);
        currRad = scallopRad(scallopI);
        currImageName = sprintf('%s/%s',foldername, filenames{scallopI});
        currImage = imread(currImageName);
        imageWidth = size(currImage,2);
        imageHeight = size(currImage,1);
        extnDia = round(2.*((1+radiusExtnPercent)*currRad));
        bb = computeBB(currX, currY, extnDia, extnDia, imageWidth, imageHeight);
        
        % Checking if bounding box is shortended due to boundary and
        % discarding such instances
        if abs(bb(3)-extnDia) > 2 || abs(bb(4)-extnDia) > 2
            numResegScallops = numResegScallops-1;
            continue;
        end
        
        cropImage = imcrop(currImage, bb);
        resizeImage = imresize(cropImage, [extnTestDia extnTestDia]);
        
        currInd = currInd+1;
        scallopData(:,:,currInd) = im2double(rgb2gray(resizeImage));
    end
    
    % Checking if there are any useful scallops from which resegmentation
    % FG masks are calculated
    if numResegScallops == 0
        resegAvailable = false;
    else
        scallopData = scallopData(:,:,1:currInd);
        [repMeanScallop, repStddevScallop] = filterRepScallop(scallopData);
    end
end

end

%% Function to filter representative scallop
function [repMeanScallop, repStddevScallop] = filterRepScallop(scallopData)
    repMeanScallop = mean(scallopData,3);
    repStddevScallop = std(scallopData,0,3);
end
    

