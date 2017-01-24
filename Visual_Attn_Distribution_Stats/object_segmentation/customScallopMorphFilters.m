function [ imageFilter, processTable, imageFilterSteps, centroidReg ] = customScallopMorphFilters( imageRegions, salImageRegions )
%CUSTOMSCALLOPMORPHFILTERS Morphological operations applied to scallops

numImages = length(imageRegions);

imageFilter = cell(numImages,1);
imageFilterSteps = cell(numImages,1);
processTable = cell(numImages,1);
centroidReg = cell(numImages,1);

for i=1:numImages
    numFixations = length( imageRegions{i} );
    imageFilter{i} = cell(numFixations,1);
    imageFilterSteps{i} = cell(numFixations,1);
    processTable{i} = true(numFixations,1);
    centroidReg{i} = zeros(numFixations,2);
    
    for j=1:numFixations
        fprintf('Filter regions image %d fixation %d ...',i,j);
        
        img = imageRegions{i}{j};
        mask = salImageRegions{i}{j};
%         img_gray = rgb2gray(img);
%         img_hist = histeq(img_gray,hist_bins);
%         level = graythresh(img_hist);
%         img_bw = im2bw(img_hist,level);
%         imageFilters{i}{j}=img_bw;

%%
%%%%%%%% Constants %%%%%%%%%%%

% color_smooth_filter_size = 5;
% smooth_filter_size = 5;
% hist_bins = 8;
% filter_bit_plane = hist_bins+1;
% region_size=40;

%% 
%%%%%%% Image reading %%%%%%%%%%%%%%%%

img_color=img;
% figure;imshow(img_color); 


%%
%%%%%%%%% Color Processing %%%%%%%%%%%%%%%
% img_color_filt = color_filter(img_color, color_smooth_filter_size);
% img_color_enhance = color_enhance(img_color);
% figure;imshow(img_color_filt);
% title('Color Smoothed');

%%
%%%%%%%% Grayscale conversion %%%%%%%%%%%%%%

img_gray=rgb2gray(img_color);
% img_gray_cf=rgb2gray(img_color_filt);
% figure;imshow(img_gray);
% figure;imshow(img_gray_cf);

%%
%%%%%%%%%%%%%%%%%% Smoothing %%%%%%%%%%%%%%%%%%%%%%

smooth_filter_size = 5;
img_smooth = smoothing(img_gray,smooth_filter_size);
% figure;imshow(img_smooth)
% title('Smoothed');

%%
%%%%%%%% CLAHE %%%%%%%%%%

% img_clahe_cf=adapthisteq(img_gray_cf);
% img_clahe=adapthisteq(img_gray);
% figure; imshow(img_clahe);
% figure;imshow(img_clahe_cf);
% title('Color Smoothed - Clahe');

%%
%%%%%%%%%%%%%%%%%% Smoothing %%%%%%%%%%%%%%%%%%%%%%

% img_smooth = smoothing(img_clahe,smooth_filter_size);
% figure;imshow(img_smooth)
% title('Clahe-Smoothed');

%%
%%%%%%%%%%%%%%%% Histeq Binning %%%%%%%%%%%%%%%%%%%%%%%%%
% img_smooth_histeq = histeq( img_smooth, hist_bins);
% figure;imshow(img_smooth_histeq)
% title('Clahe-Smooth-Histeq');

% img_clahe_cf_histeq = histeq( img_clahe_cf, hist_bins);
% figure;imshow(img_clahe_cf_histeq)
% title('Color Smooth-Clahe-Histeq');

% img_hist = img_clahe_cf_histeq;

%% 
%%%%%%% Mask Image %%%%%%%%%%%%%%%%

% img_mask_red=uint8(img(:,:,1).*mask);
% img_mask_green=uint8(img(:,:,2).*mask);
% img_mask_blue=uint8(img(:,:,3).*mask);
% img_mask=zeros(size(img,1), size(img,2),3);
% img_mask(:,:,1)=img_mask_red;
% img_mask(:,:,2)=img_mask_green;
% img_mask(:,:,3)=img_mask_blue;
% img_mask=img_clahe_cf_histeq.*uint8(mask);
% img_mask=img_smooth.*uint8(mask);
% figure;imshow(img_mask);

%% 
%%%%%%% Edge Image %%%%%%%%%%%%%%%%

img_edge=edge(img_smooth);
% figure;imshow(img_edge);
% title('Edge Image');

%% 
%%%%%%% Dilate Image %%%%%%%%%%%%%%%%

se_disk=strel('disk',2);
img_dilate=imdilate(img_edge, se_disk);
% figure;imshow(img_dilate);
% title('Dilate Image');

%% 
%%%%%%% Threshold Image %%%%%%%%%%%%%%%%

% thresh_val=0.5;
% img_thresh=im2bw(img_mask,thresh_val);
% figure;imshow(img_thresh);

%%
%%%%%%%%%%%%%%%%% Bit Plane Slicing %%%%%%%%%%%%%%%%%%%%%%%%

% img_complement = imcomplement(img_mask);
% img_bit_planes = BitPlaneSlice_spl( img_complement, hist_bins );

% img_plane=img_bit_planes(:,:,filter_bit_plane);
% figure;imshow(img_plane);
% title('Bitplane (boundaries) Image');

%%
%%%%%%%%%%%%%%%%% Clear Borders %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% img_borders = imclearborder( img_dilate );

% figure;imshow(img_borders);
% title('Clear borders');


%%
%%%%%%%%%%%%%%%% Region Filter %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
regionFilterParams = createRegionFilterParams;
[img_filter,processVal,imgRegionFilterSteps, centroid] = customScallopBinaryFilters( img_dilate, regionFilterParams );

% figure;imshow(img_filter);
% title('Blob Image');

imageFilter{i}{j}=img_filter;
processTable{i}(j)=processVal;
centroidReg{i}(j,:)=centroid;

%%
%%%%%%%%%%%%%%%% Display Filters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imageFilterSteps{i}{j}.color=img_color;
imageFilterSteps{i}{j}.smooth=img_smooth;
imageFilterSteps{i}{j}.dilate=img_dilate;
imageFilterSteps{i}{j}.filter=img_filter;
imageFilterSteps{i}{j}.regionFilterSteps = imgRegionFilterSteps;

% subplot(231)
% imshow(img_color);
% title('Color');
% 
% subplot(232)
% imshow(img_smooth);
% title('Smooth');
% 
% subplot(233)
% imshow(img_dilate);
% title('Dilate');
% 
% subplot(234)
% imshow(img_large_reg);
% title('Large Region');
% 
% subplot(235)
% imshow(img_reg);
% title('Region');
% 
% subplot(236)
% imshow(img_filter);
% title('Filter');

fprintf('done\n');

    end
end
