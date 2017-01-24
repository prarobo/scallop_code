[Rmag,Rdir] = imgradient(RGB(:,:,1));
[Gmag,Gdir] = imgradient(RGB(:,:,2));
[Bmag,Bdir] = imgradient(RGB(:,:,3));

subplot(331)
imshow(RGB(:,:,1))
subplot(332)
imshow(RGB(:,:,2))
subplot(333)
imshow(RGB(:,:,3))

subplot(334)
imshow(imadjust(RGB(:,:,1)))
subplot(335)
imshow(imadjust(RGB(:,:,2)))
subplot(336)
imshow(imadjust(RGB(:,:,3)))

subplot(337)
imagesc(Rmag)
subplot(338)
imagesc(Gmag)
subplot(339)
imagesc(Bmag)

% subplot(234)
% imshow(imadjust(RGB(:,:,1)))
% subplot(235)
% imshow(imadjust(RGB(:,:,2)))
% subplot(236)
% imshow(imadjust(RGB(:,:,3)))