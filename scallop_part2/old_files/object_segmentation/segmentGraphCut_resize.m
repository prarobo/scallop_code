function [ segmentImage, resizeLabelImage, imgFilterSteps ] = segmentGraphCut_resize( workImage, numSegments, clearGraphBorders )
%SEGMENTGRAPHCUT implements graph cut to segment images and returns a label image

%% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filterParams = createRegionFilterParams;
maxGraphWindowSize = 160;
currImageSize = zeros(1,2);
[currImageSize(1), currImageSize(2), ~]= size( workImage );

%% Enhance Image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

enhanceImage = enhanceRGBImage(workImage);
% figure;imshow(workImage);
% imshow(enhanceImage);

if size(enhanceImage, 3) > 1
    grayImage = double(rgb2gray(enhanceImage));
else
    grayImage = double(enhanceImage);
end
% imagesc(grayImage);

resizeImage = graphResizeImage( grayImage, maxGraphWindowSize );
% I = imresize(I,[nr, nc],'bicubic');

%% Apply Graph Cut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% display the image
% figure(1);clf; imagesc(I);colormap(gray);axis off;

% [SegLabel,NcutDiscrete,NcutEigenvectors,NcutEigenvalues,W,imageEdges]= NcutImage(I,numSegments);
[labelImage,~,~,~,~,~] = NcutImage(resizeImage,numSegments);
% figure;imagesc(labelImage);

% display the edges
% figure(2);clf; imagesc(imageEdges); axis off

% display the segmentation
% figure(3);clf
% bw = edge(labelImage,0.01);
% J1=showmask(grayImage,imdilate(bw,ones(2,2))); imagesc(J1);axis off

% display Ncut eigenvectors
% figure(4);clf;set(gcf,'Position',[100,500,200*(nbSegments+1),200]);
% [nr,nc,nb] = size(I);
% for i=1:nbSegments
%     subplot(1,nbSegments,i);
%     imagesc(reshape(NcutEigenvectors(:,i) , nr,nc));axis('image');axis off;
% end

%% Restoring Original Image Size
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

resizeLabelImage = round(imresize(labelImage,currImageSize,'nearest'));
% figure;imagesc(resizeLabelImage);

%% Create Graph Cut Segments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

graphImage = filterGraphSegments( labelImage, clearGraphBorders );
% figure;imshow(graphImage);

%% Filter Graph Cut Image Segments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[segmentImage, imgFilterSteps] = bwFilter( graphImage, filterParams );
% figure;imshow(segmentImage);

imgFilterSteps.gray = grayImage;
% imgFilterSteps.edge = edgeImage;
% imgFilterSteps.clean = cleanImage;
% imgFilterSteps.dilate = dilateImage;
% imgFilterSteps.orig = workImage;

end

%% Function to create graph segments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function graphImage = filterGraphSegments( labelImage, clearGraphBorders )

% Splitting Regions
edgeImage = ~imdilate(edge( labelImage, 'sobel', 0 ), strel('square',3));
% figure;imshow(edgeImage);

graphImage = true(size(labelImage)) & edgeImage;
% imshow(graphImage);

% Clear borders
if clearGraphBorders
    graphImage = imclearborder(graphImage);
end

end

%% Function to Resize Input Graphcut Image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function resizeImage = graphResizeImage( currImage, maxGraphWindowSize )

% Resize factor
resizeFactor = maxGraphWindowSize/max(size(currImage));

% Resizing image
resizeImage = imresize(currImage,resizeFactor,'bicubic');

end









