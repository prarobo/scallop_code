smoothedImageList = dir(fullfile('smoothed','*.jpg'));
unsmoothedImageList = dir(fullfile('unsmoothed','*.jpg'));

numRetinexIter = 1;

smoothImage = imread(fullfile('smoothed',smoothedImageList(2).name) );
smoothRetinexImage = smoothImage;
smoothRetinexImage(:,:,1) = retinex_frankle_mccann( im2double(adapthisteq(smoothRetinexImage(:,:,1))), numRetinexIter);
smoothRetinexImage(:,:,2) = retinex_frankle_mccann( im2double(adapthisteq(smoothRetinexImage(:,:,2))), numRetinexIter);
smoothRetinexImage(:,:,3) = retinex_frankle_mccann( im2double(adapthisteq(smoothRetinexImage(:,:,3))), numRetinexIter);

unsmoothImage = imread(fullfile('unsmoothed',unsmoothedImageList(2).name) );
unsmoothRetinexImage = unsmoothImage;
unsmoothRetinexImage(:,:,1) = retinex_frankle_mccann( im2double(adapthisteq(unsmoothRetinexImage(:,:,1))), numRetinexIter);
unsmoothRetinexImage(:,:,2) = retinex_frankle_mccann( im2double(adapthisteq(unsmoothRetinexImage(:,:,2))), numRetinexIter);
unsmoothRetinexImage(:,:,3) = retinex_frankle_mccann( im2double(adapthisteq(unsmoothRetinexImage(:,:,3))), numRetinexIter);

% figure;
% subplot(121); imshow(smoothImage(:,:,1));
% subplot(122); imshow(unsmoothImage(:,:,1));
% 
% figure;
% subplot(121); imshow(smoothImage(:,:,2));
% subplot(122); imshow(unsmoothImage(:,:,2));
% 
% figure;
% subplot(121); imshow(smoothImage(:,:,3));
% subplot(122); imshow(unsmoothImage(:,:,3));

figure;
subplot(121); imagesc(smoothImage);
subplot(122); imagesc(unsmoothImage);
figure;
subplot(121); imagesc(smoothRetinexImage);
subplot(122); imagesc(unsmoothRetinexImage);
