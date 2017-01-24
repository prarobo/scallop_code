function templateMatchNumbers = computeTemplateMatchValue( cropImage, templateMeanScallop, templateStddevScallop )
%COMPUTETEMPLATEMATCHVALUE Performs template matching between a given image
%and template

% Filter test image (smooth)
cropImage = imfilter(cropImage, fspecial('average', 3),'replicate');
grayImage = imresize(rgb2gray(cropImage), size(templateMeanScallop));
currImage = im2double(grayImage);

% Normalizing the template wrt image
imageRange = range(currImage(:));
templateRange = range(templateMeanScallop(:));
templateNormScallop = (templateMeanScallop-min(templateMeanScallop(:))).*(imageRange/templateRange)+min(currImage(:));

% Subtracting the means
currMeanSubImage = currImage-mean(currImage(:));
% templateMeanSubScallop = templateMeanScallop - mean(templateMeanScallop(:));
templateMeanSubScallop = templateNormScallop - mean(templateNormScallop(:));

% Normalizing the standard deviation between 0 and 1
stddevNormFactor = sum(templateStddevScallop(:));
if stddevNormFactor ~= 0
    templateStddevNormScallop = templateStddevScallop./stddevNormFactor;
end

% Correlation match value
correlationMat = templateMeanSubScallop.*currMeanSubImage;
weightedCorrelationMat = correlationMat.*templateStddevNormScallop;
templateMatchNumbers.corrVal = sum(correlationMat(:));
templateMatchNumbers.corrWtVal = sum(weightedCorrelationMat(:));

% SSD match value
ssdMat = (templateMeanSubScallop-currMeanSubImage).^2;
weightedSSDMat = ssdMat.*templateStddevNormScallop;
templateMatchNumbers.ssdVal = sqrt(sum(ssdMat(:)));
templateMatchNumbers.ssdWtVal = sqrt(sum(weightedSSDMat(:)));

% Display results
% displayMatchVal(cropImage, grayImage, currImage, currMeanSubImage, templateMeanScallop, ...
%     templateMeanSubScallop, templateStddevScallop, templateStddevNormScallop);

end

%% Display function
function displayMatchVal(cropImage, grayImage, currImage, currMeanSubImage, templateMeanScallop, ...
    templateMeanSubScallop, templateStddevScallop, templateStddevNormScallop)

numCols = 4;
numRows = 2;

k=1;
subplot(numRows,numCols,k); imshow(cropImage);
subplot(numRows,numCols,k+numCols); imshow(grayImage);

k=2;
subplot(numRows,numCols,k); imagesc(currImage); colorbar;
subplot(numRows,numCols,k+numCols); imagesc(currMeanSubImage); colorbar;

colormap(jet(128));

k=3;
subplot(numRows,numCols,k); imagesc(templateMeanScallop); colorbar;
subplot(numRows,numCols,k+numCols); imagesc(templateMeanSubScallop); colorbar;

k=4;
subplot(numRows,numCols,k); imagesc(templateStddevScallop); colorbar;
subplot(numRows,numCols,k+numCols); imagesc(templateStddevNormScallop); colorbar;

end