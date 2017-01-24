figure
for i=1:3
    for j=1:3
        subplot(3,3,(i-1)*3+j)
        imshow(circMaskList{i,j});
        axis off
    end
end