function [ param ] = setSaliencyParams( varargin )
%SETSALIENCYPARAMS Used to change the saliency parameters

if mod(length(varargin),2) ~= 0
    error('Inconsistent number of arguments to set SaliencyParams');
end

param = defaultSaliencyParams;

for i=1:2:length(varargin)
    paramName = varargin{i};
    paramVal = varargin{i+1};
    
    switch paramName
        case {'weights', 'normtype', 'features'} 
            param.( paramName ) = paramVal;
        case 'levelParams'
            param.levelParams.minLevel=paramVal(1);
            param.levelParams.maxLevel=paramVal(2);
            param.levelParams.minDelta=paramVal(3);
            param.levelParams.maxDelta=paramVal(4);
            param.levelParams.mapLevel=paramVal(5);
%         case 'features'
%             if strcmp( paramVal, 'TopDown')
%                 param.features = paramVal;
%             else
%                 fprintf('Unrecognized feature type, setting default values');
%             end
        otherwise
            if isfield(param,paramName)
                error('Setting default values for corresponding field: %s\n',paramName);
            else
                error('No field found: %s\n',paramName);
            end
    end
end
            

