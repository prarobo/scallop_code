clear all; clc;

frida_small = imread('potato_close.JPG');
fgMask = false(size(frida_small,1), size(frida_small,2));
bgMask = false(size(fgMask));

fgMask(200:end-200, 250:end-250) = true;
temp = imdilate(fgMask, strel('square',3));
temp(fgMask) = false;
fgMask = temp;
fgMask = imdilate(fgMask, strel('square',5));

bgMask(:, 1:50) = true;
bgMask(:, end-50:end) = true;
% temp = imdilate(bgMask, strel('square',3));
% temp(bgMask)=false;
% bgMask = temp;
% bgMask(69:(69+49),38:(38+407))=1;
% bgMask(30:end-30,30:end-30)=0;
% fgMask(237:(237+278), 181:(181+108))=1;

% scaleFactor = 1;
% frida_small = imresize(frida_small, scaleFactor);
% bgMask = logical( imresize(bgMask, scaleFactor));
% fgMask = logical( imresize(fgMask, scaleFactor));

tic
[segmentMask, graphcutResult, outImage, outFgMask, outBgMask]=GraphCutSeedMex(im2double(frida_small), fgMask, bgMask);
toc