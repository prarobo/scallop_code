function displayGraphFilter( visualAttnData, filterData )
%DISPLAYGRAPHFILTER Displays graph cut based filters

%% User Interface to toggle between images and fixations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imageI = 1;
fixI = 1;
numImages = visualAttnData.params.numImages;
numFixations = visualAttnData.fixationData.fixationsVar(imageI);

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

while true
    %     delete(currMatchesTestBox);
    %     currMatchesTestBox = 
    displayNow( visualAttnData.fileInfo, visualAttnData.fixationData, visualAttnData.segmentData, ...
        filterData, imageI, fixI, windowRect{imageI}(fixI,:) );
    
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
                numFixations = visualAttnData.fixationData.fixationsVar(imageI);
                fixI = 1;
            case 'w'                
                if imageI ~= numImages
                    imageI = imageI+1;
                else
                    imageI = 1;
                end
                numFixations = visualAttnData.fixationData.fixationsVar(imageI);
                fixI = 1;
            case 'a'               
                if fixI ~=1
                    fixI=fixI-1;
                else
                    fixI = numFixations;
                end
            case 'd'                
                if fixI ~= numFixations
                    fixI = fixI+1;
                else
                    fixI = 1;
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

function displayNow( fileInfo, fixationData, segmentData, filterData, imageI, fixI, rect)

origImage = imread( fullfile(fileInfo.foldername, fileInfo.filename{imageI}) );
filterImage = filterData(imageI).fixation{fixI}.filterImage;
labelImage = filterData(imageI).fixation{fixI}.labelImage;
origCircList = filterData(imageI).fixation{fixI}.origCircList;
filterCircList = filterData(imageI).fixation{fixI}.filterCircList;
reducedCircList = filterData(imageI).fixation{fixI}.reducedCircList;

subplot('Position',[0.05 0.5 0.4 0.4]);
imshow( origImage );
rectangle('Position', rect, 'LineWidth', 2, 'EdgeColor','red');

subplot('Position',[0.5 0.5 0.4 0.4]);
fixationWindow = imcrop( origImage, rect );
imshow( fixationWindow );

hold on

for circI=1:size(origCircList,1)
    t=0:.01:2*pi;
    plot(origCircList(circI,1)+origCircList(circI,3)*sin(t),origCircList(circI,2)+origCircList(circI,3)*cos(t), 'red');
end

for circI=1:size(filterCircList,1)
    t=0:.01:2*pi;
    plot(filterCircList(circI,1)+filterCircList(circI,3)*sin(t),filterCircList(circI,2)+filterCircList(circI,3)*cos(t), 'magenta');
end

for circI=1:size(reducedCircList,1)
    t=0:.01:2*pi;
    plot(reducedCircList(circI,1)+reducedCircList(circI,3)*sin(t),reducedCircList(circI,2)+reducedCircList(circI,3)*cos(t), 'green');
end

hold off


bwImage = zeros(size(filterImage,1), size(filterImage,2), 3);
bwImage(:,:,1) = filterImage.*255;
bwImage(:,:,2) = filterImage.*255;
bwImage(:,:,3) = filterImage.*255;
bwImage = im2uint8( bwImage );

subplot('Position',[0.02 0.05 0.3 0.3]);
imshow(bwImage);
hold on

for circI=1:size(origCircList,1)
    t=0:.01:2*pi;
    plot(origCircList(circI,1)+origCircList(circI,3)*sin(t),origCircList(circI,2)+origCircList(circI,3)*cos(t), 'red');
end

for circI=1:size(filterCircList,1)
    t=0:.01:2*pi;
    plot(filterCircList(circI,1)+filterCircList(circI,3)*sin(t),filterCircList(circI,2)+filterCircList(circI,3)*cos(t), 'magenta');
end

for circI=1:size(reducedCircList,1)
    t=0:.01:2*pi;
    plot(reducedCircList(circI,1)+reducedCircList(circI,3)*sin(t),reducedCircList(circI,2)+reducedCircList(circI,3)*cos(t), 'green');
end

hold off

% bwImage = zeros(size(graphImage,1), size(graphImage,2), 3);
% bwImage(:,:,1) = graphImage.*255;
% bwImage(:,:,2) = graphImage.*255;
% bwImage(:,:,3) = graphImage.*255;
% bwImage = im2uint8( bwImage );

subplot('Position',[0.35 0.05 0.3 0.3]);
imshow(label2rgb(labelImage));
hold on

for circI=1:size(origCircList,1)
    t=0:.01:2*pi;
    plot(origCircList(circI,1)+origCircList(circI,3)*sin(t),origCircList(circI,2)+origCircList(circI,3)*cos(t), 'red');
end

for circI=1:size(filterCircList,1)
    t=0:.01:2*pi;
    plot(filterCircList(circI,1)+filterCircList(circI,3)*sin(t),filterCircList(circI,2)+filterCircList(circI,3)*cos(t), 'magenta');
end

for circI=1:size(reducedCircList,1)
    t=0:.01:2*pi;
    plot(reducedCircList(circI,1)+reducedCircList(circI,3)*sin(t),reducedCircList(circI,2)+reducedCircList(circI,3)*cos(t), 'green');
end

hold off

% subplot('Position',[0.7 0.05 0.3 0.3]);
% imshow(bwImage);
% hold on

% for circI=1:size(reducedCircListGraph,1)
%     t=0:.01:2*pi;
%     plot(reducedCircListGraph(circI,1)+reducedCircListGraph(circI,3)*sin(t),reducedCircListGraph(circI,2)+reducedCircListGraph(circI,3)*cos(t), 'green');
% end
% hold off

end
