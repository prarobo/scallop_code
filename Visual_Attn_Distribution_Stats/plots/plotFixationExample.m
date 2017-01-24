fixFrame = imread('check/smoothed/frame000024_0.jpg');
fixPt = [197 570];

fixRad = 4;
fixFrame(fixPt(1)-fixRad:fixPt(1)+fixRad, fixPt(2)-fixRad:fixPt(2)+fixRad,:) = 0;
fixFrame(fixPt(1)-fixRad:fixPt(1)+fixRad, fixPt(2)-fixRad:fixPt(2)+fixRad,1) = 255;

fixWinRad = 135;
tempFrame = fixFrame(fixPt(1)-fixWinRad+fixRad:fixPt(1)+fixWinRad-fixRad, fixPt(2)-fixWinRad+fixRad:fixPt(2)+fixWinRad-fixRad,:);

fixFrame(fixPt(1)-fixWinRad-fixRad:fixPt(1)+fixWinRad+fixRad, fixPt(2)-fixWinRad-fixRad:fixPt(2)+fixWinRad+fixRad,:) = 0;
fixFrame(fixPt(1)-fixWinRad+fixRad:fixPt(1)+fixWinRad-fixRad, fixPt(2)-fixWinRad+fixRad:fixPt(2)+fixWinRad-fixRad,:) = tempFrame;

imshow(fixFrame)
