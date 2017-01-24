function cellStrOut = num2cellstr(numMat)
% Converts a numeric matrix into a matrix of cell strings

cellStrOut = cell(size(numMat));

for i=1:numel(numMat)
    cellStrOut{i} = num2str(numMat(i));
end