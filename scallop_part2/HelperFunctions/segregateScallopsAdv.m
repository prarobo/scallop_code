function [ params, scallopPosition ] = segregateScallopsAdv( params, groundTruth )
%SEGREGATESCALLOPS Segregates scallops based on their position. Basically
%it collects the indices of scallops that are present in a small
%segregation window around a point.

%% Initialize
imageWidth = params.imageSize(2);
imageHeight = params.imageSize(1);
groundTruthX = groundTruth.X;
groundTruthY = groundTruth.Y;
indices = cell(imageHeight,imageWidth);

%% Main Loop
for rowI = 1:imageHeight
    fprintf('Scallop segregation row %d ...\n', rowI);
    for colI = 1:imageWidth
       
        % Getting segregation box limits
        bb = computeBB_xylim(colI, rowI, params.segregragationWindow, params.segregragationWindow, ...
                        [0 params.imageSize(2)], [0 params.imageSize(1)]); 

        % Finding points inside segregation box
        indices{rowI,colI} = uint16(find(groundTruthX>=bb(1) & groundTruthX<=bb(2) & groundTruthY>=bb(3) & groundTruthY<=bb(4)));
    end
end

%% Output
scallopPosition.indices = indices;
scallopPosition.numbers = cellfun(@numel, indices);
