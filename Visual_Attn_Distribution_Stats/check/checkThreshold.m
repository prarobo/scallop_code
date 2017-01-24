smoothedImageList = dir(fullfile('smoothed','*.jpg'));
unsmoothedImageList = dir(fullfile('unsmoothed','*.jpg'));

rect = [80 60 640 480];
smoothImage = imcrop(imread(fullfile('smoothed',smoothedImageList(2).name) ), rect);
smoothGrayImage = adapthisteq(rgb2gray(smoothImage));
smoothThreshLevel = graythresh( smoothGrayImage );
smoothThreshImage = im2bw( smoothGrayImage, smoothThreshLevel );

unsmoothImage = imcrop(imread(fullfile('unsmoothed',unsmoothedImageList(2).name) ), rect);
unsmoothGrayImage = adapthisteq(rgb2gray(unsmoothImage));
unsmoothThreshLevel = graythresh( unsmoothGrayImage );
unsmoothThreshImage = im2bw( unsmoothGrayImage, unsmoothThreshLevel );

figure;
subplot(121); imshow(smoothImage);
subplot(122); imshow(unsmoothImage);

figure;
subplot(121); imshow(smoothThreshImage);
subplot(122); imshow(unsmoothThreshImage);

