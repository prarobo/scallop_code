function [ dist ] = euclideanDistance( x1, y1, x2, y2 )
%EUCLIDEANDISTANCE Computes the euclidean distance between 2 points

xDiff = x1-x2;
yDiff = y1-y2;
dist = sqrt( xDiff.^2 + yDiff.^2 );

end

