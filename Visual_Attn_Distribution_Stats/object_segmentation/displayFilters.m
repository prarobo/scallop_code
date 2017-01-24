function displayFilters( imgFilterSteps, imgRect, imgVect )
%DISPLAYFILTERS Display several filters applied to the image during region extraction

%% User Interface to toggle between images and fixations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

image = 1;
fixation = 1;
numImages = length(imgFilterSteps);
numFixations = length(imgFilterSteps{image});

filterFig = figure;
% set(gcf, 'Position', get(0,'Screensize'));
annotation(gcf,'textbox',...
    [0.1 0.96 0.5 0.03],...
    'String',{sprintf(' a-next fixation \t\t d-previous fixation \n w-next image \t\t\t s-previous image \n q-quit')},...
    'FitBoxToText','on');

imgFig = figure;
% set(gcf, 'Position', get(0,'Screensize'));

while true    
    displayNow( imgFilterSteps, image, fixation, imgRect, imgVect, filterFig, imgFig );
    set(0,'CurrentFigure',imgFig)
    
    ch = waitforbuttonpress;
    if ch == 1
        key = get(gcf,'CurrentCharacter');
        switch key
            case 'a'
                if fixation ~=1
                    fixation=fixation-1;
                else
                    fixation = numFixations;
                end
            case 'd'
                if fixation ~= numFixations
                    fixation = fixation+1;
                else
                    fixation = 1;
                end
            case 's'               
                fixation = 1;
                if image ~=1
                    image=image-1;
                else
                    image = numImages;
                end
                numFixations = length(imgFilterSteps{image});
            case 'w'                
                fixation = 1;
                if image ~= numImages
                    image = image+1;
                else
                    image = 1;
                end
                numFixations = length(imgFilterSteps{image});                
            case 'q'
                close all
                break;
            otherwise
                disp('d-next fixation, a-previous fixation, w-next image, s-previous image, q-quit');
                set(0,'CurrentFigure',imgFig)
        end
    else
        disp('d-next fixation, a-previous fixation, w-next image, s-previous image, q-quit');
        set(0,'CurrentFigure',imgFig)
    end
end


function displayNow( imgFilterSteps, image, fixation, imgRect, imgVect, filterFig, imgFig )
%DISPLAYNOW Redraw all figures based on user options

set(0,'CurrentFigure',imgFig)
imshow(imgVect(image).data);
rectangle('Position',imgRect{image}(fixation,:),'LineWidth',2, 'EdgeColor','r');
title(sprintf('Image %d fixation %d',image,fixation));

set(0,'CurrentFigure',filterFig)

plotThis = true;

subplot(241)
imshow(imgFilterSteps{image}{fixation}.color);
title('Color');

subplot(242)
imshow(imgFilterSteps{image}{fixation}.dilate);
title('Dilate');


if isfield(imgFilterSteps{image}{fixation}.regionFilterSteps, 'aspectRatio') && plotThis
    subplot(243)
    imshow(imgFilterSteps{image}{fixation}.regionFilterSteps.aspectRatio);
    title('aspectRatio');
else
    plotThis = false;
end

if isfield(imgFilterSteps{image}{fixation}.regionFilterSteps, 'imgLargeRegions') && plotThis
    subplot(244)    
    imshow(imgFilterSteps{image}{fixation}.regionFilterSteps.imgLargeRegions);
    title('imgLargeRegions');
else
    plotThis = false;
end

if isfield(imgFilterSteps{image}{fixation}.regionFilterSteps, 'imgLargeSmallRegions') && plotThis
    subplot(245)    
    imshow(imgFilterSteps{image}{fixation}.regionFilterSteps.imgLargeSmallRegions);
    title('imgLargeSmallRegions');
else
    plotThis = false;
end

if isfield(imgFilterSteps{image}{fixation}.regionFilterSteps, 'subRegions') && plotThis
    subplot(246)
    imshow(imgFilterSteps{image}{fixation}.regionFilterSteps.subRegions);
    title('subRegions');
else
    plotThis = false;
end

if isfield(imgFilterSteps{image}{fixation}.regionFilterSteps, 'circFit') && plotThis
    subplot(247)
    imshow(imgFilterSteps{image}{fixation}.regionFilterSteps.circFit);
    title('circFit');
else
    plotThis = false;
end

subplot(248)
imshow(imgFilterSteps{image}{fixation}.filter);
title('imgFilter');
