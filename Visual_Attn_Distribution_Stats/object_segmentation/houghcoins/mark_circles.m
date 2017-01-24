function [circList, circimg] = mark_circles(inimg, himg, rbv)

imsize = size(inimg);
circgray(1:imsize(1), 1:imsize(2)) = 0;

circList = cell(length(1:size(rbv,2)),1);
for rcount = 1:size(rbv,2)
  
  % thrshold hough space to get points with maximal chance of being 
  % the centers of a circle.
  % label the image and compute centroid of each point cluster
  % consider the centroids as the centers of the detected circles
  
  SE = strel( 'square', 3);
  bwh = im2bw(himg(:,:,1,rcount), 0.67);
  bwh = imdilate(bwh, SE);
  bwh = imerode(bwh, SE);
  bwh = logical(bwh);
  
  stat = regionprops(bwh, 'Centroid'); 
  circList{rcount}.centers = zeros( size(stat,1), 2 );
  circList{rcount}.radius = rbv(rcount);
  
  for coin = 1:size(stat,1)
    center = stat(coin).Centroid;
    circList{rcount}.centers(coin,:) = [stat(coin).Centroid(1) stat(coin).Centroid(2)]; 
    circgray = circgray + draw_circle(center, rbv(rcount), imsize);    
  end

end

circimg = im2double(inimg);
circimg(:,:,1) = circimg(:,:,1) + circgray;
circimg(:,:,2) = circimg(:,:,2) + circgray;
circimg(:,:,3) = circimg(:,:,3) + circgray;
circimg = imadjust(circimg, [0 1], [0 1]);

end
