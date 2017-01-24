function displayGroundTruthScallop( visualAttnData )
%DISPLAYGROUNDTRUTHSCALLOP Displays each scallop and related processing

%% User Interface to toggle between images
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numImages = visualAttnData.params.numImages;
topMatchesNum = 5;

windowRect = calcRect( visualAttnData.fixationData.fixations, ...
    visualAttnData.params.imageSize, visualAttnData.params.fixationWindowSize );

figure;
% set(gcf, 'Position', get(0,'Screensize'));
% annotation(gcf,'textbox',...
%     [0.1 0.96 0.5 0.03],...
%     'String',{sprintf(' w-next image \t\t s-previous image \t\t q-quit')},...
%     'FitBoxToText','on');
% 
% 
% currMatchesTestBox = annotation(gcf,'textbox',...
%     [0.75 0.05 0.2 0.8],...
%     'String',{'Scallop Distributions Satisfied' },...
%     'FitBoxToText','on');

for imageI=1:numImages
     if (visualAttnData.statData.groundTruth(imageI).numScallops ~= 0)
         scallopI = 1;
         break;
     end
end

if visualAttnData.statData.groundTruth(imageI).numScallops == 0
    error('No scallops in dataset');
end

while true
%     delete(currMatchesTestBox);
    displayNow( visualAttnData, imageI, scallopI, windowRect, topMatchesNum );
    
    ch = waitforbuttonpress;
    if ch == 1
        key = get(gcf,'CurrentCharacter');
        switch key
            case 's'
                if scallopI > 1
                    scallopI = scallopI-1;
                else
                    nextImage = true;
                    iterImageNum = 0;
                    while nextImage
                        if imageI ~=1
                            imageI=imageI-1;
                        else
                            imageI = numImages;
                        end
                        if( visualAttnData.statData.groundTruth(imageI).numScallops ~= 0 )
                            scallopI = 1;
                            nextImage = false;
                        else
                            iterImageNum = iterImageNum + 1;
                            if iterImageNum>visualAttnData.params.numImages
                                error('No scallops in dataset');
                            end
                        end                            
                    end
                end
            case 'w'                
                if scallopI < visualAttnData.statData.groundTruth(imageI).numScallops && ...
                        scallopI ~= 0
                    scallopI = scallopI+1;
                else
                    nextImage = true;
                    iterImageNum = 0;
                    while nextImage
                        if imageI ~= numImages
                            imageI=imageI+1;
                        else
                            imageI = 1;
                        end
                        if( visualAttnData.statData.groundTruth(imageI).numScallops ~= 0 )
                            scallopI = 1;
                            nextImage = false;
                        else
                            iterImageNum = iterImageNum + 1;
                            if iterImageNum>visualAttnData.params.numImages
                                error('No scallops in dataset');
                            end
                        end                            
                    end
                end
            case 'q'
                close(gcf);
                break;
            otherwise
                disp('w-next scallop, s-previous scallop, q-quit');
        end
    else
        disp('w-next scallop, s-previous scallop, q-quit');
    end
end

end

%% Display Now function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displayNow( visualAttnData, imageI, scallopI, windowRect, topMatchesNum )

clf
numImages = visualAttnData.params.numImages;
numFixations = length(visualAttnData.distributionData.dataPointCheck{imageI});

imageFileName = sprintf('%s/%s',visualAttnData.fileInfo.foldername, visualAttnData.fileInfo.filename{imageI});
% subplot(121)
imagePlot = subplot('Position',[0.05 0.5 0.4 0.4]);
imshow(imageFileName);

hold on
colStart = visualAttnData.statData.groundTruth(imageI).loc(scallopI,1) ...
    - visualAttnData.statData.groundTruth(imageI).loc(scallopI,3);
rowStart = visualAttnData.statData.groundTruth(imageI).loc(scallopI,2) ...
    - visualAttnData.statData.groundTruth(imageI).loc(scallopI,3);
dotDia = 2 * visualAttnData.statData.groundTruth(imageI).loc(scallopI,3);
rectangle('Position',[colStart rowStart dotDia dotDia], 'Curvature',[1 1], ...
    'LineWidth',2, 'EdgeColor','green');
hold off

title(sprintf('Image %d of %d', imageI, numImages));
xlim ([1 visualAttnData.params.imageSize(2)]);
ylim ([1 visualAttnData.params.imageSize(1)]);

circlePlot = subplot('Position',[0.05 0.05 0.4 0.4]);
imshow(imageFileName);

displayCircles( visualAttnData, circlePlot, imageI, scallopI, windowRect, topMatchesNum );

title(sprintf('Circles'));
xlim ([1 visualAttnData.params.imageSize(2)]);
ylim ([1 visualAttnData.params.imageSize(1)]);

end

%% Display different circles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displayCircles( visualAttnData, circlePlot, imageI, scallopI, windowRect, topMatchesNum )

numCirc = size( visualAttnData.statData.detection(imageI).scallop{scallopI}.circList );
subplot(circlePlot)
hold on
for circI = 1:numCirc
    fixI = visualAttnData.statData.detection(imageI).scallop{scallopI}.circList(circI,7);
    objI = visualAttnData.statData.detection(imageI).scallop{scallopI}.circList(circI,8);
    colStart = windowRect{imageI}(fixI,1) - 1 + visualAttnData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,1) ...
        -visualAttnData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,3);
    rowStart = windowRect{imageI}(fixI,2) - 1 + visualAttnData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,2) ...
        -visualAttnData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,3);
    dotDia = 2*visualAttnData.segmentData.reducedCircList(imageI).fixation{fixI}(objI,3);
    
    [scallopVerdict, scallopMatchPoints] = checkScallop( visualAttnData.distributionData.dataPointCheck{imageI}{fixI}{objI} );
    if scallopVerdict
        rectangle('Position',[colStart rowStart dotDia dotDia], 'Curvature',[1 1], ...
            'LineWidth',2, 'EdgeColor','magenta');
    elseif circI < topMatchesNum
        rectangle('Position',[colStart rowStart dotDia dotDia], 'Curvature',[1 1], ...
            'LineWidth',2, 'EdgeColor','green');
    else
        rectangle('Position',[colStart rowStart dotDia dotDia], 'Curvature',[1 1], ...
            'LineWidth',2, 'EdgeColor','red');        
    end

    if circI <= topMatchesNum
        currStr = sprintf('Center error = %d \nRadius error = %d \nMatch Val = %d \nDistance = %d', ...
            visualAttnData.statData.detection(imageI).scallop{scallopI}.circList(circI,4), ...
            visualAttnData.statData.detection(imageI).scallop{scallopI}.circList(circI,5), ...
            scallopMatchPoints, ...
            visualAttnData.statData.detection(imageI).scallop{scallopI}.circList(circI,5));
        
        annotation(gcf,'textbox',...
            [0.6 0.95-circI*0.15 0.2 0.15],...
            'String',{sprintf(currStr)},...
            'FitBoxToText','on');
    end
    
end
hold off

end

%% Check scallop function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [scallopVerdict, scallopMatchPoints] = checkScallop( scallopStat )

if( scallopStat.scallopMatchPoints > scallopStat.scallopFailPoints + scallopStat.scallopSkippedPoints )
    scallopVerdict = true;
else
    scallopVerdict = false;
end
scallopMatchPoints = scallopStat.scallopMatchPoints;

end