function inBoundary = isBoundaryScallop(currX, currY, horzBoundary, vertBoundary, imageWidth, imageHeight)
%ISBOUNDARYSCALLOP Function to check for boundary scallops

if currX <= horzBoundary || currX >= imageWidth-horzBoundary ||...
        currY <= vertBoundary || currY >= imageHeight-vertBoundary
    inBoundary = true;
else
    inBoundary = false;
end
