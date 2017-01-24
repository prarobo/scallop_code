function displayDetectedScallops( visualAttnData )
%DISPLAYDETECTEDSCALLOPS Display the detected scallops

%% User Interface to toggle between images
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imageI = 1;
numImages = visualAttnData.params.numImages;

windowRect = calcRect( visualAttnData.fixationData.fixations, ...
    visualAttnData.params.imageSize, visualAttnData.params.fixationWindowSize );

figure;
% set(gcf, 'Position', get(0,'Screensize'));
annotation(gcf,'textbox',...
    [0.1 0.96 0.5 0.03],...
    'String',{sprintf(' w-next image \t\t s-previous image \t\t q-quit')},...
    'FitBoxToText','on');


currMatchesTestBox = annotation(gcf,'textbox',...
    [0.75 0.05 0.2 0.8],...
    'String',{'Scallop Distributions Satisfied' },...
    'FitBoxToText','on');

while true
    delete(currMatchesTestBox);
    currMatchesTestBox = displayNow( visualAttnData, imageI, windowRect );
    
    ch = waitforbuttonpress;
    if ch == 1
        key = get(gcf,'CurrentCharacter');
        switch key
            case 's'               
                if imageI ~=1
                    imageI=imageI-1;
                else
                    imageI = numImages;
                end
            case 'w'                
                if imageI ~= numImages
                    imageI = imageI+1;
                else
                    imageI = 1;
                end
            case 'q'
                close(gcf);
                break;
            otherwise
                disp('w-next image, s-previous image, q-quit');
        end
    else
        disp('w-next image, s-previous image, q-quit');
    end
end

end

function currMatchesTestBox = displayNow( visualAttnData, imageI, windowRect )
%DISPLAYNOW Redraw all figures based on user options

numImages = visualAttnData.params.numImages;
numFixations = length(visualAttnData.distributionData.dataPointCheck{imageI});

imageFileName = sprintf('%s/%s',visualAttnData.fileInfo.foldername, visualAttnData.fileInfo.filename{imageI});
% subplot(121)
subplot('Position',[0.05 0.5 0.4 0.4]);
imshow(imageFileName);

hold on
for scallopI=1:visualAttnData.statData.groundTruth(imageI).numScallops
    colStart = visualAttnData.statData.groundTruth(imageI).loc(scallopI,1) ...
                - visualAttnData.statData.groundTruth(imageI).loc(scallopI,3);
    rowStart = visualAttnData.statData.groundTruth(imageI).loc(scallopI,2) ...
                - visualAttnData.statData.groundTruth(imageI).loc(scallopI,3);
            dotDia = 2 * visualAttnData.statData.groundTruth(imageI).loc(scallopI,3);
    rectangle('Position',[colStart rowStart dotDia dotDia], 'Curvature',[1 1], ...
        'LineWidth',2, 'EdgeColor','green');    
end
hold off

title(sprintf('Image %d of %d', imageI, numImages));
xlim ([1 visualAttnData.params.imageSize(2)]);
ylim ([1 visualAttnData.params.imageSize(1)]);

% subplot(122)
subplot('Position',[0.05 0.05 0.4 0.4]);
imshow(imageFileName);

currMatchString = sprintf('Scallop Distributions Satisfied\n');

hold on
for fixI=1:numFixations
    
    % Edge
    numObj = length(visualAttnData.distributionData.dataPointCheck{imageI}{fixI});
    
    for objI=1:numObj
        colStart = windowRect{imageI}(fixI,1) - 1 + visualAttnData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,1) ...
                    -visualAttnData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,3);
        rowStart = windowRect{imageI}(fixI,2) - 1 + visualAttnData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,2) ...
                    -visualAttnData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,3);
        dotDia = 2*visualAttnData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,3);
        
        [scallopVerdict, scallopMatchPoints] = checkScallop( visualAttnData.distributionData.dataPointCheck,...
                                                    visualAttnData.classData.threshold, imageI, fixI, objI );
        if scallopVerdict
            if (visualAttnData.statData.category(imageI).fixations{fixI}(objI) == 1)
                rectangle('Position',[colStart rowStart dotDia dotDia], 'Curvature',[1 1], ...
                    'LineWidth',2, 'EdgeColor','green');
            end
            if (visualAttnData.statData.category(imageI).fixations{fixI}(objI) == 0)
                rectangle('Position',[colStart rowStart dotDia dotDia], 'Curvature',[1 1], ...
                    'LineWidth',2, 'EdgeColor','magenta');
            end

        else
            if (visualAttnData.statData.category(imageI).fixations{fixI}(objI) == 0)
                rectangle('Position',[colStart rowStart dotDia dotDia], 'Curvature',[1 1], ...
                    'LineWidth',2, 'EdgeColor','red');
            end
        end
        
        currMatchString = sprintf('%s%d \n', currMatchString, scallopMatchPoints );
        
    end
end
hold off

currMatchesTestBox = annotation(gcf,'textbox',...
    [0.75 0.05 0.2 0.8],...
    'String',{currMatchString},...
    'FitBoxToText','on');

title('Detected scallops');
xlim ([1 visualAttnData.params.imageSize(2)]);
ylim ([1 visualAttnData.params.imageSize(1)]);

end

%% Check scallop function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [scallopVerdict, scallopMatchPoints] = checkScallop( dataPointCheck, threshold, imageI, fixI, objI )

if dataPointCheck{imageI}{fixI}{objI}.scallopMatchPoints >= threshold
    scallopVerdict = true;
else
    scallopVerdict = false;
end
scallopMatchPoints = dataPointCheck{imageI}{fixI}{objI}.scallopMatchPoints;

end

