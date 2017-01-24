function [ numScallops, hogAvailable, hogDes, scallopIndices ] = getQuadrantHOG( params, scallopPosition, scallopHOG, rowI, colI)
%GETQUADRANTHOG Get the HOG descriptors for all scallops in a single
%quadrant

% Scallop inside quadrant
tempScallopIndices = scallopPosition.indices{rowI,colI};
scallopHogAvailable = scallopHOG.hogAvailable(tempScallopIndices);
numScallops = sum(scallopHogAvailable(:));
scallopIndices = uint16(tempScallopIndices(scallopHogAvailable));
hogAvailable = true;

if numScallops == 0
    hogAvailable = false;
    hogDes = [];
    return;
end

hogDes = single(zeros(numScallops, params.hogDescriptorLength));

for scallopI = 1:numScallops
    scallopInd = scallopIndices(scallopI);
    hogDes(scallopI,:) = scallopHOG.hogDes{scallopInd}';
end

end

