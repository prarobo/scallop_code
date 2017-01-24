function [ enhanceImg ] = enhanceRGBImage( img )
%ENHANCERGBIMAGE Enhance a 3 dimensional image (rgb image). Applies
%imadjust on individual dimensions

if ndims(img) == 1 || ndims(img) == 2
    enhanceImg  = imadjust(img);
elseif ndims(img) == 3
    enhanceImg = img;
    enhanceImg(:,:,1) = imadjust( enhanceImg(:,:,1) );
    enhanceImg(:,:,2) = imadjust( enhanceImg(:,:,2) );
    enhanceImg(:,:,3) = imadjust( enhanceImg(:,:,3) );
else
    error('Special image enhancement function cannot deal with 4 or more dimensional image\n');
end

end

