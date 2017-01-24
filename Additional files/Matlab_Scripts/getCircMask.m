function circMask = getCircMask(centerX, centerY, radius, imgWidth, imgHeight, numChannels)
%GETCIRCMASK get a circular mask

switch nargin 
    case 5
        numChannels = 1;
    case 6
    otherwise
        error('Number of arguments mismatch in function %s',mfilename);
end

[x,y]=meshgrid(-(centerX-1):(imgWidth-centerX),-(centerY-1):(imgHeight-centerY));

cMask=((x.^2+y.^2)<=radius^2);
% imagesc(circMask) 

circMask = repmat(cMask, 1, 1, numChannels);

end