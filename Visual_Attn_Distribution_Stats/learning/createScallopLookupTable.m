function [ scallopLookup ] = createScallopLookupTable( params )
%CREATESCALLOPLOOKUPTABLE Generates a lookup table of scallop statistics

%% Initialization
scallopLookup.params = params;
scallopLookup.lookupTable( params.imageSize(1), params.imageSize(2) ) = struct;

% for rowI=1:params.imageSize(1)
%     for colI=1:params.imageSize(2)
%         scallopLookup.lookupTable(rowI,colI).numScallops = 0;
%         scallopLookup.lookupTable(rowI,colI).meanMap = [];
%         scallopLookup.lookupTable(rowI,colI).stddevMap = [];
%     end
% end

%% Computing Lookup table

[quadrantData, ~] = quadrant_learning_lookup( params, params.imageSize(2), params.imageSize(1) );

scallopLookup.lookupTable = transpose( reshape(quadrantData.quadrantID, params.imageSize(2), params.imageSize(1) ) );

end

