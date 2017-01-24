function [ params, quadrantHOG ] = quadrantLearningHOGCompute( params, scallopPosition, scallopHOG )
%QUADRANTLEARNINGHOGCOMPUTE Computes HOG descriptors for scallops in each
%quadrant

%% Initialization
imageWidth = params.imageSize(2);
imageHeight = params.imageSize(1);

hogAvailable = true(imageWidth, imageHeight);
numScallops = zeros(imageWidth, imageHeight);
scallopIndices = cell(imageWidth, imageHeight);
hogDes = cell(imageWidth, imageHeight);

%% Main Loop
for rowI = 1:imageHeight
    fprintf('Scallop quadrant HOG row %d ...\n', rowI);
    for colI = 1:imageWidth       
        
        % Scallops inside quadrant HOG
        [ numScallops(rowI, colI), hogAvailable(rowI, colI), hogDes{rowI,colI}, scallopIndices{rowI, colI} ] ...
                                = getQuadrantHOG( params, scallopPosition, scallopHOG, rowI, colI);
                            
    end
end

%% Output
quadrantHOG.hogAvailable = hogAvailable;
quadrantHOG.numScallops = uint16(numScallops);
quadrantHOG.scallopIndices = scallopIndices;
quadrantHOG.hogDes = hogDes;

end

