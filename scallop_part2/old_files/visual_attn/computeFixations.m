function [ fixations, fixationsFixed, numFixationsVar, salienceVal, salienceLoc ] =...
                        computeFixations( salMaps, salData, varargin )
%COMPUTEFIXATIONS Compute fixations from available saliency maps
    
numImages = length( salMaps );
numFixationsVar=zeros(numImages,1);

switch nargin
    case 2
        numFixations = 0;
        fixationsFixed = false;
        imgIndex = 0;
        permanentInhibit = 0;
    case 3
        permanentInhibit = varargin{1};
        numFixations = 0;
        fixationsFixed = false;
        imgIndex = 0;
    case 4
        permanentInhibit = varargin{1};
        numFixations = varargin{2};
        fixationsFixed = true;
        numFixationsVar=zeros(numImages,1)+numFixations;
        imgIndex = 0;        
    case 6
        permanentInhibit = varargin{1};
        numFixations = varargin{2};
        fixationsFixed = true;
        numFixationsVar=zeros(numImages,1)+numFixations;
        imgIndex = varargin{3};
        totalImages = varargin{4};
    otherwise
        error('Incompatible number of arguments for computeFixations');
end

if imgIndex ~=0 && numImages ~= 1
    error('Single image mode on but multiple image data provided in computeFixations');
end

iterLimit = 20;
wtaLimit = 10000;
saliencyThreshold = 0.25;
myParams = defaultSaliencyParams;
myParams.useRandom = 0;
fixations = {};

for f=1:numImages
    if (fixationsFixed)
        if (permanentInhibit)
            tempSalMap = salMaps(f);
            numFixations = numFixationsVar(f);
            
            % loop over the fixations
            for fix = 1:numFixations
                wta = initializeWTA(tempSalMap,myParams);
                if imgIndex ~= 0
                    fprintf('Image %d of %d: computing fixation (pInh on) %d of %d ...',...
                        imgIndex, totalImages, fix, numFixations);
                else
                    fprintf('Image %d of %d: computing fixation (pInh on) %d of %d ...',...
                        f, numImages, fix, numFixations);
                end
                
                % evolve WTA until we have the next winner
                winner = [-1,-1];
                wtaCounter = 0;
                wtaQuit = false;
                
                while(winner(1) == -1)
                    wtaCounter = wtaCounter + 1;
                    [wta,winner] = evolveWTA(wta);
                    
                    if wtaCounter == wtaLimit
                        wtaQuit = true;
                        break;
                    end
                end
                
                if wtaQuit
                    fprintf('quit\n');
                    fix = fix - 1;
                    numFixationsVar(f) = fix;
                    break;
                end

                fprintf('done\n');
                                        
                % get shape data and apply inhibition of return
                shapeData = estimateShape(salMaps(f),salData{f},winner,myParams);
                % wta = applyIOR(wta,winner,myParams,shapeData);
                tempSalMap.data(logical(shapeData.iorMask.data)) =...
                    min(tempSalMap.data(:));
                
                % convert the winner to image coordinates
                fixations{f}(fix,:) = winnerToImgCoords(winner,myParams);
                salienceVal{f}(fix) = salMaps(f).data(winner(1),winner(2));
                salienceLoc{f}(fix,1:2) = winner;
                                
                if sum(sum(tempSalMap.data ~= min(tempSalMap.data(:)))) == 0
                    numFixationsVar(f) = fix;
                    break;
                end
            end
        else
            numFixations = numFixationsVar(f);
            wta = initializeWTA(salMaps(f),myParams);
            
            % loop over the fixations
            for fix = 1:numFixations
                if imgIndex ~= 0
                    fprintf('Image %d of %d: computing fixation (pInh off) %d of %d ...',...
                        imgIndex, totalImages, fix, numFixations);
                else
                    fprintf('Image %d of %d: computing fixation (pInh off) %d of %d ...',...
                        f, numImages, fix, numFixations);
                end
                
                % evolve WTA until we have the next winner
                winner = [-1,-1];
                wtaCounter = 0;
                wtaQuit = false;
                
                while(winner(1) == -1)
                    wtaCounter = wtaCounter + 1;
                    [wta,winner] = evolveWTA(wta);
                    
                    if wtaCounter == wtaLimit
                        wtaQuit = true;
                        break;
                    end
                end
                
                if wtaQuit
                    fprintf('quit\n');
                    fix = fix - 1;
                    numFixationsVar(f) = fix;
                    break;
                end
                
                % get shape data and apply inhibition of return
                shapeData = estimateShape(salMaps(f),salData{f},winner,myParams);
                wta = applyIOR(wta,winner,myParams,shapeData);
                
                % convert the winner to image coordinates
                fixations{f}(fix,:) = winnerToImgCoords(winner,myParams);
                salienceVal{f}(fix) = salMaps(f).data(winner(1),winner(2));
                salienceLoc{f}(fix,1:2) = winner;
                fprintf('done\n');
            end
        end
    else
        if (permanentInhibit)
            tempSalMap = salMaps(f);
            firstWinnerVal = 0;
                        
            while(1)
                wta = initializeWTA(tempSalMap,myParams);
                numFixations = numFixations + 1;
                if imgIndex ~= 0
                    fprintf('Image %d of %d: computing fixations(variable) (pInh on) %d ...',...
                        imgIndex, totalImages, numFixations);
                else
                    fprintf('Image %d of %d: computing fixations(variable) (pInh on) %d ...',...
                        f, numImages, numFixations);
                end
                if numFixations > iterLimit
                    break;
                end
                
                % evolve WTA until we have the next winner
                winner = [-1,-1];
                wtaCounter = 0;
                wtaQuit = false;
                
                while(winner(1) == -1)
                    wtaCounter = wtaCounter + 1;
                    [wta,winner] = evolveWTA(wta);
                    
                    if wtaCounter == wtaLimit
                        wtaQuit = true;
                        break;
                    end
                end
                
                if wtaQuit
                    fprintf('quit\n');
                    fix = fix - 1;
                    numFixationsVar(f) = fix;
                    break;
                end
                fprintf('done\n');
                
                if firstWinnerVal == 0
                    firstWinnerVal = salMaps(f).data(winner(1),winner(2));
                else
                    if salMaps(f).data(winner(1),winner(2)) < firstWinnerVal*saliencyThreshold;
                        fprintf('Image %d Fixation %d salience dropped below the minimum value\n', f, numFixations);
                        break;
                    end
                end
                
                % get shape data and apply inhibition of return
                shapeData = estimateShape(salMaps(f),salData{f},winner,myParams);
                % wta = applyIOR(wta,winner,myParams,shapeData);
                tempSalMap.data(logical(shapeData.iorMask.data)) =...
                    min(tempSalMap.data(:));
                                
                % convert the winner to image coordinates
                fixations{f}(fix,:) = winnerToImgCoords(winner,myParams);
                salienceVal{f}(fix) = salMaps(f).data(winner(1),winner(2));
                salienceLoc{f}(fix,1:2) = winner;
            end
            numFixationsVar(f) = numFixations-1;
            
        else
            firstWinnerVal = 0;
            wta = initializeWTA(salMaps(f),myParams);
            
            while(1)
                numFixations = numFixations + 1;
                if imgIndex ~= 0
                    fprintf('Image %d of %d: computing fixations(variable) (pInh off) %d ...',...
                        imgIndex, numImages, numFixations);
                else
                    fprintf('Image %d of %d: computing fixations(variable) (pInh off) %d ...',...
                        f, numImages, numFixations);
                end
                if numFixations > iterLimit
                    break;
                end
                
                % evolve WTA until we have the next winner
                winner = [-1,-1];
                wtaCounter = 0;
                wtaQuit = false;
                
                while(winner(1) == -1)
                    wtaCounter = wtaCounter + 1;
                    [wta,winner] = evolveWTA(wta);
                    
                    if wtaCounter == wtaLimit
                        wtaQuit = true;
                        break;
                    end
                end
                
                if wtaQuit
                    fprintf('quit\n');
                    fix = fix - 1;
                    numFixationsVar(f) = fix;
                    break;
                end
                fprintf('done\n');
                
                if firstWinnerVal == 0
                    firstWinnerVal = salMaps(f).data(winner(1),winner(2));
                else
                    if salMaps(f).data(winner(1),winner(2)) < firstWinnerVal*saliencyThreshold;
                        fprintf('Image %d Fixation %d salience dropped below the minimum value\n', f, numFixations);
                        break;
                    end
                end
                
                % get shape data and apply inhibition of return
                shapeData = estimateShape(salMaps(f),salData{f},winner,myParams);
                wta = applyIOR(wta,winner,myParams,shapeData);
                
                % convert the winner to image coordinates
                fixations{f}(fix,:) = winnerToImgCoords(winner,myParams);
                salienceVal{f}(fix) = salMaps(f).data(winner(1),winner(2));
                salienceLoc{f}(fix,1:2) = winner;
            end
            numFixationsVar(f) = numFixations-1;
        end
    end
    numFixations = 0;
end

end

% currScallopData.fixations = fixations;
% currScallopData.fixationsFixed = fixationsFixed;
% currScallopData.numFixationsVar = numFixationsVar;
% currScallopData.salienceVal = salienceVal;
% currScallopData.salienceLoc = salienceLoc;









