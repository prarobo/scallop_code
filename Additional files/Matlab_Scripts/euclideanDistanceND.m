%% Euclidean distance function for ND points
% X1 and X2 can be one dimensional vectors. If either X1 of X2 is a 2
% dimensional matrix, then each row should correspond to a n-dimensional
% point. If X1 or X2 have more than 1 point, then the both the point stack
% should have the same number of rows. It is allowed for one of the point
% stacks to have only one point. In this case the distance of all the
% points in the other stack from this simgle point is computed.

function dist = euclideanDistanceND(X1, X2)

% reshaping one dimensional vectors
if size(X1,1)==1 || size(X1,2)==1
    X1 = reshape(X1,1,numel(X1));
end

if size(X2,1)==1 || size(X2,2)==1
    X2 = reshape(X2,1,numel(X2));
end

% checking the dimensionality of ND points
if size(X1,2) ~= size(X2,2)
    error('The number of columns in X1 and X2 need to be the same');
end

if size(X1,1) == 1
    X1 = repmat(X1, size(X2,1), 1);
elseif size(X2,1) == 1
    X2 = repmat(X2, size(X1,1), 1);
end


diff = X1-X2;
diffSq = diff.^2;
dist = sum(diffSq,2).^0.5;

end