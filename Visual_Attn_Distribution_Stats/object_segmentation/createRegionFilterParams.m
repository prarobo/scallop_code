function regionFilterParams = createRegionFilterParams(varargin)
%CREATREGIONFILTERPARAMS Creat filter parameters

%% Default Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

checkRegionSize = true;
maxRegionSize = 4000;
minRegionSize = 200;

checkAspectRatio = true;
minAspectRatio = 3;
minWidthToHeightRatio = 3;
maxWidthToHeightRatio = Inf;
minHeightToWidthRatio = 1;
maxHeightToWidthRatio = 2;

numRegions = 5;

checkSolidity = true;
minSolidity = 0.1;

checkRegionDim = true;
minRegionWidth = 20;
minRegionHeight = 10;

checkSubRegions = true;

checkCircleFit = true;

%% Setting Default Values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

regionFilterParams.checkRegionSize = checkRegionSize;
regionFilterParams.maxRegionSize = maxRegionSize;
regionFilterParams.minRegionSize = minRegionSize;

regionFilterParams.checkAspectRatio = checkAspectRatio;
regionFilterParams.minAspectRatio = minAspectRatio;
regionFilterParams.minWidthToHeightRatio = minWidthToHeightRatio;
regionFilterParams.maxWidthToHeightRatio = maxWidthToHeightRatio;
regionFilterParams.minHeightToWidthRatio = minHeightToWidthRatio;
regionFilterParams.maxHeightToWidthRatio = maxHeightToWidthRatio;

regionFilterParams.numRegions = numRegions;

regionFilterParams.checkSolidity = checkSolidity;
regionFilterParams.minSolidity = minSolidity;

regionFilterParams.checkRegionDim = checkRegionDim;
regionFilterParams.minRegionWidth = minRegionWidth;
regionFilterParams.minRegionHeight = minRegionHeight;

regionFilterParams.checkSubRegions = checkSubRegions;

regionFilterParams.checkCircleFit = checkCircleFit;

%% Setting Default Values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if mod(nargin,2) ~= 0
    fprintf('\nInvalid number of arguments in createRegionFilterParams, chosing default parameters');
    return
end

for i = 1:nargin/2
    if ~isfield(regionFilterParams, varargin{i*2-1})
        fprintf('\nError: No parameter %s found, skipping parameter',varargin{i*2-1});
        pause(2);
        continue;
    end    
    regionFilterParams.(varargin{i*2-1}) = varargin{i*2};
end

