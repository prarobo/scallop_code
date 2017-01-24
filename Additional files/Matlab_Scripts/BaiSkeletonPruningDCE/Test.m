% I = imread('carriage-17.GIF');
I = imread('testScallop.png');
% I = imresize(I,.75);
bw = im2bw(I);
bw= 1-bw; %the shape must be black, i.e., values zero.

[bw,I0,x,y,x1,y1,aa,bb]=div_skeleton_new(4,1,bw,2);

imshow(bw+I0);
hold on
plot(bb, aa, '.r');
plot(y1, x1, 'og');
plot(y, x, '.g');
hold off

%% Custom additions for comparison
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure; imshow( bwmorph(im2bw(I),'skel'))
figure; plot( bb, aa)