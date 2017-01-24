dawkins_image = rgb2hsv(dawkins_imageCopy);
our_image = rgb2hsv(our_imageCopy);
dawkins_crop = rgb2hsv(dawkins_cropCopy);
our_crop = rgb2hsv(our_cropCopy);


dawkins_image_red=dawkins_image(:,:,1);
dawkins_image_green=dawkins_image(:,:,2);
dawkins_image_blue=dawkins_image(:,:,3);

dawkins_red=dawkins_crop(:,:,1);
dawkins_green=dawkins_crop(:,:,2);
dawkins_blue=dawkins_crop(:,:,3);

our_image_red=our_image(:,:,1);
our_image_green=our_image(:,:,2);
our_image_blue=our_image(:,:,3);

our_red=our_crop(:,:,1);
our_green=our_crop(:,:,2);
our_blue=our_crop(:,:,3);


subplot(231)
imhist(dawkins_image_red/numel(dawkins_image_red))
subplot(232)
imhist(dawkins_image_green/numel(dawkins_image_green))
subplot(233)
imhist(dawkins_image_blue/numel(dawkins_image_blue))
subplot(234)
imhist(dawkins_red/numel(dawkins_red))
subplot(235)
imhist(dawkins_green/numel(dawkins_green))
subplot(236)
imhist(dawkins_blue/numel(dawkins_blue))

figure;
subplot(231)
imhist(our_image_red/numel(our_image_red))
subplot(232)
imhist(our_image_green/numel(our_image_green))
subplot(233)
imhist(our_image_blue/numel(our_image_blue))
subplot(234)
imhist(our_red/numel(our_red))
subplot(235)
imhist(our_green/numel(our_green))
subplot(236)
imhist(our_blue/numel(our_blue))

figure;
subplot(121)
imhist(dawkins_image_green)
subplot(122)
imhist(dawkins_green)

figure;
subplot(121)
imhist(our_image_green)
subplot(122)
imhist(our_green)

figure;imshow(dawkins_green)
