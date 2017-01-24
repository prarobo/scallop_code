function [ result ] = customCombineMaps( maps,label,varargin )
%CUSTOMCOMBINEMAPS combines maps using given weights

% customCombineMaps - returns the sum of a vector of maps.
%
% resultMap = combineMaps(maps,label)
%   Adds the data fields in the maps vactor and returns
%   the result as a map with label as the label.
%
% See also dataStructures.

% This file is modified from the SaliencyToolbox - Copyright (C) 2006-2008
% by Dirk B. Walther and the California Institute of Technology.
% See the enclosed LICENSE.TXT document for the license agreement. 
% More information about this project is available at: 
% http://www.saliencytoolbox.net


result = maps(1);
result.label = label;

lm = length(maps);
result.data = zeros(size(maps(1).data));

if nargin == 2
    weights = ones(1,lm);
else
    weights = varargin{1};
    if(length(weights) ~= lm)
        error('Insufficient number of weights, error in weights vector in customCombineMaps, quitting');
    end
end

for m = 1:lm
  result.data = result.data + maps(m).data * weights(m);
end

result.date = timeString;
end

