function [ rect ] = calcRect( inputFixations, imgSize, rectSize )
%CALCRECT computes rectangles around fixations

if sum( sum( rectSize < 4 )) ~= 0
    error('Fixation rectangle size too small');
end

numImages = length(inputFixations);
rect = cell(1,numImages);

for i=1:numImages
    numFixations = size(inputFixations{i},1);
    rect{i} = zeros(numFixations,4);
    for j=1:numFixations
        fixX=inputFixations{i}(j,2);
        fixY=inputFixations{i}(j,1);
        
        halfRectWidth = round( rectSize(1)/2 );
        halfRectHeight = round( rectSize(2)/2 );
        
        rectWidth = 2 * halfRectWidth;
        rectHeight = 2 * halfRectHeight;
        
        if round(fixX) - halfRectWidth < 1
            rectX = 1;
            rectWidth = rectWidth - abs(round(fixX) - halfRectWidth) + 1;
        else
            rectX = round(fixX) - halfRectWidth;
        end
        
        if round(fixY) - halfRectHeight < 1
            rectY = 1;
            rectHeight = rectHeight - abs(round(fixY) - halfRectHeight) + 1;
        else
            rectY = round(fixY) - halfRectHeight;
        end

        if round(fixX) + halfRectWidth > imgSize(2)
            rectWidth = rectWidth -...
                        (round(fixX) + halfRectWidth - imgSize(2));
        end
        
        if round(fixY) + halfRectHeight > imgSize(1)
            rectHeight = rectHeight -...
                         (round(fixY) + halfRectHeight - imgSize(1));
        end
        
        rect{i}(j,:) = [rectX rectY rectWidth rectHeight];
    end
end

