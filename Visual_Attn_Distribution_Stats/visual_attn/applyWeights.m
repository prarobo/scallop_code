function [salOutMap, salOutData] = applyWeights( imgVect, varargin )
%APPLYWEIGHTS applies learned weights to saliency computation

switch nargin
    case 1
        gCM = 0;
        gFM = 0;
        statCM = 0;
        statFM = 0;
        imgIndex = 0;
        totalImages = 0;
    case 2
        gCM = varargin{1}
        gFM = 0;
        statCM = 1;
        statFM = 0;
        imgIndex = 0;
        totalImages = 0;
    case 3
        gCM = varargin{1};
        gFM = varargin{2};
        statCM = 1;
        statFM = 1;
        imgIndex = 0;
        totalImages = 0;
    case 4
        gCM = varargin{1};
        gFM = varargin{2};
        statCM = varargin{3};
        statFM = 1;
        imgIndex = 0;
        totalImages = 0;
    case 5
        gCM = varargin{1};
        gFM = varargin{2};
        statCM = varargin{3};
        statFM = varargin{4};
        imgIndex = 0;
        totalImages = 0;
    case 7
        gCM = varargin{1};
        gFM = varargin{2};
        statCM = varargin{3};
        statFM = varargin{4};
        imgIndex = varargin{5};
        totalImages = varargin{6};
    otherwise
        error('Incompatible number of inputs to applyWeights function, quitting');
end

numImg = length(imgVect);

if imgIndex ~=0 && numImg ~= 1
    error('Single image mode on but multiple image data provided in applyWeights');
end

%% Set saliency parameters and image vector creation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% normType = 'None';
normType = 'Iterative';
features = {'Color','Intensities','Orientations'};
if statCM
    weights = [gCM(1) gCM(2) gCM(3)];
else
    weights = [1 1 1];
end
customSaliencyParams = setSaliencyParams( 'normtype', normType,...
                                          'features', features,...
                                          'weights', weights ); 
params = customSaliencyParams;
                                      
%% Compute Saliency Maps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% loop over all images
for n = 1:numImg
    if imgIndex ~= 0
        fprintf('Processing image %d of %d: computing saliency map ...',imgIndex,totalImages);
    else
        fprintf('Processing image %d of %d: computing saliency map ...',n,numImg);
    end
    
    % make sure that we don't use color features if we don't have a color image
    myParams = params;
    if (imgVect(n).dims == 2)
        myParams = removeColorFeatures(myParams);
    end
    
    % compute the saliency map
    % [salMaps(f),salData] = makeSaliencyMap(imgList(f),myParams);
    
    img = imgVect(n);
    salParams = myParams;
    
    numFeat = length(salParams.features);
    % loop over all requested features
    for f = 1:numFeat
        saliencyData(f).origImage = img;
        saliencyData(f).label = salParams.features{f};
        
        if (strcmp('Orientation',salParams.features{f}))
            
            % for orientation computation, see if we already have an
            % intensity pyramid that we can borrow to make things faster
            idx = strmatch('Intensity',{saliencyData(1:f-1).label});
            if isempty(idx)
                % found no intensity pyramid
                saliencyData(f).pyr = makeFeaturePyramids(img,salParams.features{f},...
                    salParams)
            else
                % found an intensity pyramid - hand it over to be used for orientation filtering
                saliencyData(f).pyr = makeFeaturePyramids(img,salParams.features{f},...
                    salParams,saliencyData(idx(1)).pyr(1));
            end
        else
            
            % for all other features: call with the auxiliary data in varargin
            saliencyData(f).pyr = makeFeaturePyramids(img,salParams.features{f},salParams);
        end
        
        combFM = [];
        numPyr = length(saliencyData(f).pyr);
        
        % center-surround contrasts for all pyramids
        for p = 1:numPyr
            if (strcmp('TopDown',salParams.features{f}))
                
                % special version of centerSurround for TopDown
                [FM,csLevels] = centerSurroundTopDown(saliencyData(f).pyr(p),salParams);
            else
                
                % Plain vanilla version for everything else
                [FM,csLevels] = centerSurround(saliencyData(f).pyr(p),salParams);
            end
            
            saliencyData(f).FM(p,:) = maxNormalize(FM,salParams,[0,1]);
            saliencyData(f).csLevels(p,:) = csLevels;
            
            % combine the feature maps over all scales
            if statFM
                combFM = [combFM customCombineMaps(saliencyData(f).FM(p,:),...
                    [salParams.features{f} 'CM'], gFM{f}(p,:))];
            else
                combFM = [combFM combineMaps(saliencyData(f).FM(p,:),...
                    [salParams.features{f} 'CM'])];
            end
        end
        
        % normalize the combined feature maps
        combFM = maxNormalize(combFM,salParams,[0,1]);
        
        % compute conspicuity maps over all sub-features
        if (numPyr == 1)
            saliencyData(f).CM = combFM;
        else
            % more than 1 sub-feature: additional normalization step
            saliencyData(f).CM = maxNormalize(combineMaps(combFM,[salParams.features{f} 'CM']),...
                salParams,[0,0]);
        end
        
        % weigh the conspicuity map appropriately
        saliencyData(f).CM.data = salParams.weights(f) * saliencyData(f).CM.data / numPyr / numFeat;
        saliencyData(f).date = timeString;
    end % end loop over features
    
    % compute the saliency map by combining all the conspicuity maps
    salmap = combineMaps([saliencyData.CM],'SaliencyMap');
    salmap = maxNormalize(salmap,salParams,[0,1]);
    salmap.parameters = salParams;
    
    salOutMap(n)=salmap;
    salOutData{n}=saliencyData;
    
    fprintf('done\n');
end


