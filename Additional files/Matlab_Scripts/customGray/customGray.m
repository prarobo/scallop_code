function adjfighandle = customGray(imgin)
% CUSTOMGRAY: UI for selecting non-default combination of R,G,and B
% Syntax: CUSTOMGRAY(IMGIN)
%         h = CUSTOMGRAY(IMGIN); (Outputs handle to the GUI figure.)
%
% CUSTOMGRAY launches an interactive, uicontrolled figure
% for creating a "custom RGB2GRAY" image by modifying the linear
% combination of R,G,B.
%
% The function will display two versions of the input image; the version of
% the left will be the original, un-adjusted image. The version on the
% right will change interactively when the slider controls are moved,
% updating the multipliers for R,G,B.
%
% NOTES:
% Function |rgb2gray| creates a grayscale image as a weighted sum of R,G,B,
% given by: GRAY = 0.2989 * R + 0.5870 * G + 0.1140 * B;
% These values were designed to provide a "visually pleasing" grayscale
% representation of the RGB image, and is weighted to reflect "normal"
% human visual acuity. However, there are other models available for
% grayscale conversion, and often other reasons (e.g., facilitating
% segmentation) for converting to grayscale.
%
% This user interface allows you to try different pre-built combinations,
% or to create your own. Note that multipliers are, by design, permitted to
% range beyond [0, 1]; this allows you to saturate colors, if it makes
% sense to do so, or to subtract colorplanes. To visualize a wider dynamic
% range of intensities, all images are converted to type double. 
%
% OUTPUT IMAGES ARE TYPE DOUBLE!
%
% *Class Support* The input must be an RGB image of any class supported by
% IMREAD. The output image I (generated on export) is of the same class as
% the input image. When the "DONE/EXPORT" button is pressed, the output
% image will be written to the base workspace (AS TYPE DOUBLE) along with
% the parameters used to create it, and the text of the command that will
% recreate it independent of customGray.
%
% EXAMPLE:
% %1) Default (opens with default image; you can browse to load a new one):
%    customGray
% %2) Specify image:
%    customGray('peppers.png')
%
% Written by Brett Shoelson, Ph.D.
% brett.shoelson@mathworks.com
% 08/09/2013
% Comments and suggestions welcome!
%
% Copyright 2013 MathWorks, Inc.
%
% SEE ALSO: RGB2GRAY, EXPLORERGB

% Modifications:

bgc = [0.553 0.659 0.678];
highlightColor = [0.85 0.9 0.9];

adjfig = figure('NumberTitle','off',...
    'name','Create Custom Grayscale Image from RGB',...
    'units','normalized',...
    'position',[0.1 0.1 0.8 0.85],...
    'tag','intensityadjfig',...
    'menubar','none',...
    'windowstyle','normal',...
    'color',bgc);
set(adjfig,'defaultuicontrolunits','normalized',...
    'defaultuicontrolbusyaction','cancel',...
    'defaultuicontrolinterruptible','off');

ht                       = uitoolbar(adjfig);
icon                      = im2double(imread('file_open.png'));
icon(icon==0)              = NaN;
uitoggletool(ht,...
    'CData',               icon,...
    'oncallback',          @GetNewFile,...
    'offcallback',         '',...
    'Tooltipstring',       'Load new image.',...
    'Tag',                 'loadImageTool');

icon = imread('ExportIcon.png');
icon = icon(3:end-3,4:end-2,:);
%icon = imresize(icon,[16 16],'method','bicubic');
uitoggletool(ht,...
    'CData',               icon,...
    'oncallback',          @finish,...
    'offcallback',         '',...
    'Tooltipstring',       'Export Results!',...
    'Tag',                 'exportResults');

if nargin == 0
    imgin = 'autumn.tif';
end
if ischar(imgin)
    imname = imgin;
    imgin = iptImread(imname);
else
    imname = 'Original';
    imgin = im2double(imgin);
end
%
[objpos,objdim] = distributeObjects(2,0.025,0.975,0.025);
ax(1) = axes('parent',adjfig,...
    'position',[objpos(1) 0.3125 objdim 0.615],...
    'xtick',[],'ytick',[]);
imshow(imgin,'parent',ax(1));
title(imname,'parent',ax(1),'interpreter','none','fontweight','bold');
ax(2) = axes('parent',adjfig,...
    'position',[objpos(2) 0.3125 objdim 0.615],...
    'xtick',[],'ytick',[]);
imgout = rgb2gray(imgin);
imgOutHandle = imshow(imgout,'parent',ax(2));
grayTitle = title(sprintf('Modified Image (RANGE: [%0.2f %0.2f])',min(imgout(:)),max(imgout(:))),'parent',ax(2),'interpreter','none','fontweight','bold');
expandAxes(ax);
set(ax,'handlevisibility','callback','climmode','auto','xlimmode','auto','ylimmode','auto');

annotation('textbox',[0.025 0.96 0.95 0.0225],...
    'string','CLICK ON ANY IMAGE TO VIEW IT IN A LARGER WINDOW; RIGHT-CLICK ON EXPANDED IMAGE TO EXPORT TO BASE WORKSPACE!',...
    'textcolor', 'k',...
    'horizontalalignment','c',...
    'fontweight','b',...
    'fontsize',9,...
    'backgroundcolor',bgc*1.2);

% Histograms
colors = [1 0 0; 0 1 0; 0 0 1; 0 0 0];
[hobjpos,hobjdim] = distributeObjects(3,objpos(1)+0.025,objdim+objpos(1)-0.025,0.0375);
histax = zeros(4,1);
for ii = 1:3
    histax(ii) = subplot(1,6,ii,...
        'parent',adjfig,...
        'position',[hobjpos(ii) 0.2 hobjdim 0.1],...
        'xtick',[],'ytick',[]);
    refreshHistogram(histax(ii),imgin(:,:,ii),ii);
end
[hobjpos,hobjdim] = distributeObjects(3,objpos(2)+0.025,objdim+objpos(2)-0.025,0.0375);
histax(4) = subplot(1,6,4,...
    'parent',adjfig,...
    'position',[hobjpos(1) 0.2 hobjdim 0.1],...
    'xtick',[],'ytick',[]);
refreshHistogram(histax(4),rgb2gray(imgin),4);
axes('parent',adjfig,...
    'position',[hobjpos(2) 0.2 0.9-hobjpos(2) 0.1],...
    'xlim',[0 1],...
    'ylim',[-2.1 2.1],...
    'xtick',[],'ytick',[-2:2],...
    'box','on');

[barpos,bardim] = distributeObjects(3,0.05,0.95,0.1);
redLevel = 0.2989;
redBar = patch([barpos(1) barpos(1)+bardim barpos(1)+bardim barpos(1)],...
    [0 0 redLevel redLevel],...
    [1 0 0]);
greenLevel = 0.5870;
greenBar = patch([barpos(2) barpos(2)+bardim barpos(2)+bardim barpos(2)],...
    [0 0 greenLevel greenLevel],...
    [0 1 0]);
blueLevel = 0.1140;
blueBar = patch([barpos(3) barpos(3)+bardim barpos(3)+bardim barpos(3)],...
    [0 0 blueLevel blueLevel],...
    [0 0 1]);
uicontrol('style','text',...
    'units','normalized',...
    'position',[hobjpos(2) 0.305 0.9-hobjpos(2) 0.035],...
    'fontweight','bold',...
    'fontsize',10,...
    'backgroundcolor',bgc,...
    'string',{'';'Red/Green/Blue Levels'});

line(xlim,[0 0],'color',[0.5 0.5 0.5],'linewidth',2);
refreshBarGraph;
axes(...
    'parent',adjfig,...
    'position',[0.925 0.2 0.05 0.1],...
    'xlim',[0 1],...
    'ylim',[0 1],...
    'xtick',[],'ytick',[],...
    'box','on');
uicontrol('style','text',...
    'units','normalized',...
    'position',[0.925 0.305 0.05 0.035],...
    'fontweight','bold',...
    'fontsize',10,...
    'backgroundcolor',bgc,...
    'string',{'Saturation';'Indicator'},...
    'tooltipstring',sprintf('Indicates the closeness of the (+/-) magnitude\nof the output grayscale image to 1.'));
maxval = max(imgout(:));
saturationMap = flipud([autumn(128);flipud(summer(128))]);
satcolor = saturationMap(round(maxval*255),:);
saturationBar = patch([0 1 1 0],[0 0 maxval maxval],satcolor);
set(adjfig,'handlevisibility','callback');

processPanel = uipanel('parent',adjfig,...
    'backgroundcolor',highlightColor,...
    'position',[0.025 0.025 0.95 0.15],...
    'visible','on');
%
[objpos,objdim] = distributeObjects(3,0.025,0.6,0.025);
% [sliderHandle,panelHandle,editHandle] =
%     sliderPanel(parent,PanelPVs,SliderPVs,EditPVs,LabelPVs,numFormat);

% rgb2gray (default) converts RGB values to grayscalevalues by forming a
% weighted sum of the R, G,and B components:
%  0.2989 * R + 0.5870 * G + 0.1140 * B
uicontrol('style','text',...
    'string','Adjustment Parameters/Multipliers; Right-click sliders to set to 0.',...
    'parent',processPanel,...
    'position',[0.025 0.75 0.6 0.2],...
    'fontsize',11,...
    'backgroundcolor', highlightColor,...
    'fontweight','bold');
[redLevelSlider,~,redLevelText] = sliderPanel(processPanel,...
    {'Position', [objpos(1), 0.155, objdim, 0.55],'Title', 'Red Multiplier','Backgroundcolor', highlightColor},...
    {'Min', -2, 'Max', 2, 'Value', 0,'tag','redLevel','callback',@update,'Backgroundcolor', bgc,'SliderStep',[0.1/4 1/4]},...
    {'backgroundcolor', highlightColor},...
    {'Backgroundcolor', highlightColor},...
    '%0.2f');
set(redLevelSlider,'value',0.2989);
set(redLevelText,'string',0.2989);
[greenLevelSlider,~,greenLevelText] = sliderPanel(processPanel,...
    {'Position', [objpos(2), 0.155, objdim, 0.55],'Title', 'Green Multiplier','Backgroundcolor', highlightColor},...
    {'Min', -2, 'Max', 2, 'Value', 0,'tag','greenLevel','callback',@update,'Backgroundcolor', bgc,'SliderStep',[0.1/4 1/4]},...
    {'backgroundcolor', highlightColor},...
    {'Backgroundcolor', highlightColor},...
    '%0.2f');
set(greenLevelSlider,'value',0.5870);
set(greenLevelText,'string',0.5870);
[blueLevelSlider,~,blueLevelText] = sliderPanel(processPanel,...
    {'Position', [objpos(3), 0.155, objdim, 0.55],'Title',  'Blue Multiplier','Backgroundcolor', highlightColor},...
    {'Min', -2, 'Max', 2, 'Value', 0,'tag','blueLevel','callback',@update,'Backgroundcolor', bgc,'SliderStep',[0.1/4 1/4]},...
    {'backgroundcolor', highlightColor},...
    {'Backgroundcolor', highlightColor},...
    '%0.2f');
set(blueLevelSlider,'value',0.1140);
set(blueLevelText,'string',0.1140);
[objpos,objdim] = distributeObjects(2,0.025,0.975,0.025);
prebuiltOptions = uibuttongroup('parent',processPanel,...
    'units','normalized','position',[0.65 0.155 0.25 0.55],...
    'title','Pre-Defined Combinations','Backgroundcolor', highlightColor);
uicontrol('Style','radiobutton','String','RGB2GRAY ("Luminosity 1")',...
    'units','normalized','Backgroundcolor', highlightColor,...
    'pos',[objpos(1) 0.6 objdim 0.3],'parent',prebuiltOptions,...
    'HandleVisibility','off',...
    'tooltipstring',sprintf('This is a "normalized-luminosity" approach that uses a weighted average targeted to human visual acuity;\nuses default values internal to RGB2GRAY.\n[ 0.2989 0.5870 0.1140 ]'));
uicontrol('Style','radiobutton','String','Luminosity 2',...
    'units','normalized','Backgroundcolor', highlightColor,...
    'pos',[objpos(1) 0.2 objdim 0.3],'parent',prebuiltOptions,...
    'HandleVisibility','off',...
    'tooltipstring',sprintf('An alternate "normalized-luminosity" approach that uses a different standard\nthan that used by RGB2GRAY to optimize for human visual acuity.\n[ 0.21 0.71 0.08 ]'));
uicontrol('Style','radiobutton','String','Lightness Method',...
    'units','normalized','Backgroundcolor', highlightColor,...
    'pos',[objpos(2) 0.6 objdim 0.3],'parent',prebuiltOptions,...
    'HandleVisibility','off',...
    'tooltipstring',sprintf('For R,G,B, use average of strongest and weakest values:\n[ Max(R) + Min(R) / 2, Max(G) + Min(G) / 2, Max(B) + Min(B) / 2 ]'));
uicontrol('Style','radiobutton','String','Average Method',...
    'units','normalized','Backgroundcolor', highlightColor,...
    'pos',[objpos(2) 0.2 objdim 0.3],'parent',prebuiltOptions,...
    'HandleVisibility','off',...
    'tooltipstring',sprintf('Simple mean of R,G,B:\n[ Mean2(R) Mean2(G) Mean2(B) ])'));

% Initialize some button group properties.
set(prebuiltOptions,'SelectionChangeFcn',@selectPredefined);
set(findall(adjfig,'type','axes'),'handlevisibility','callback');
% 
if nargout > 0
    adjfighandle = adjfig;
else
    clear adjfighandle;
end

    function finish(varargin)
        set(gcbo,'state','off');
        %[redLevel,greenLevel,blueLevel] = updateParameters;
        updateParameters;
        opt = get(get(prebuiltOptions,'selectedObject'),'string');
        %
        fprintf('\n\nCALLING SYNTAX:\n**************************\n');
        fprintf('rgb = im2double(rgb);\n');
        fprintf('grayscale = %0.3f*rgb(:,:,1) + %0.3f*rgb(:,:,2) + %0.3f*rgb(:,:,3);\n',redLevel,greenLevel,blueLevel);
        if strcmp(opt,'RGB2GRAY ("Luminosity 1")')
            fprintf('OR:\ngrayscale = rgb2gray(rgb);\n');
        end
        fprintf('\nTo display:\nimshow(grayscale,[]);');
        fprintf('\n**************************\n\n')
        varname = evalin('base','genvarname(''ImgOut'',who)');
        outputImage = get(imgOutHandle,'cdata');
        assignin('base',varname,outputImage);
        fprintf('Output image written to variable %s in the base workspace.\n\n',varname);
    end %finish

    function GetNewFile(varargin)
        set(gcbo,'state','off');
        [imgin,cmap,fname,~,userCanceled] = getNewRGBImage(true);
        if userCanceled
            return
        end
        if isempty(fname),fname = 'Original'; end
        imshow(imgin,cmap,'parent',ax(1));
        title(fname,'parent',ax(1),'interpreter','none','fontweight','bold');
        %imgOutHandle = imshow(imgin,cmap,'parent',ax(2));
        %title('Modified Image','interpreter','none','parent',ax(2));
        %set(ax,'handlevisibility','callback');
        set(ax,'handlevisibility','callback','climmode','auto','xlimmode','auto','ylimmode','auto');
        expandAxes(ax);
        update('all');
    end %GetNewFile

    function imout = iptImread(imname,varargin)
        [~,~,ext] = fileparts(imname);
        switch ext
            case '.dcm'
                imout = dicomread(imname);
            case {'.fits','.fts'}
                imout = fitsread(imname);
            case '.img'
                try
                    imout = analyze75read(imname);
                catch
                    try
                        imout = interfilered(imname);
                    catch
                        error('Unknown image format.');
                    end
                end
            case '.nitf'
                imout = nitfread(imname);
            case '.hdr'
                imout = hdrread(imname);
            otherwise
                imout = imread(imname);
        end
        imout = im2double(imout);
    end %iptImread

    function refreshBarGraph(varargin)
        set(redBar,'ydata',[0 0 redLevel redLevel]);
        set(greenBar,'ydata',[0 0 greenLevel greenLevel]);
        set(blueBar,'ydata',[0 0 blueLevel blueLevel]);
    end %refreshBarGraph

    function refreshHistogram(theAx,thePlane,ind,varargin)
        axes(theAx);
        %imhist(thePlane);
        hist(theAx,thePlane(:),256);
        fo = findall(theAx,'type','patch');
        %get(fo)
        set(fo,'facecolor',colors(ind,:),'edgecolor',colors(ind,:));
    end %refreshHistogram

    function refreshSaturationAx(varargin)
        minval = abs(min(imgout(:)));
        maxval = max(imgout(:));
        warnval = max(minval,maxval);
        warnval = max(1,min(256,round(warnval*256)));
        satcolor = saturationMap(warnval,:);
        warnval = warnval/256;
        set(saturationBar,'ydata',[0 0 warnval warnval],'facecolor',satcolor);
        set(grayTitle,'string',...
            sprintf('Modified Image (RANGE: [%0.2f %0.2f])',min(imgout(:)),max(imgout(:))));
    end %refreshSaturationAx

    function selectPredefined(varargin)
        opt = get(get(prebuiltOptions,'selectedObject'),'string');
        tmpim = im2uint16(imgin);
        R = tmpim(:,:,1);
        G = tmpim(:,:,2);
        B = tmpim(:,:,3);
        switch opt
            case 'RGB2GRAY ("Luminosity 1")'
                rgbVals = [0.2989 0.5870 0.1140];
            case 'Luminosity 2'
                rgbVals = [0.21 0.71 0.08];
            case 'Lightness Method'
                rgbVals = im2double([(max(R(:))+min(R(:)))/2,...
                    (max(G(:))+min(G(:)))/2,...
                    (max(B(:))+min(B(:)))/2]);
            case 'Average Method'
                rgbVals = mean([R(:),G(:),B(:)])/double(intmax('uint16'));
        end
        set(redLevelSlider,'value',rgbVals(1));
        set(greenLevelSlider,'value',rgbVals(2));
        set(blueLevelSlider,'value',rgbVals(3));
        drawnow;
        update('FromRadioButton');
    end %selectPredefined

    function ii = update(option,varargin)
        if ~nargin | ishandle(option) %#ok
            option = 'output';
        end
        % OPTION:
        %     'output': adjusts only output histograms
        %               (DEFAULT; no need to specify!)
        %     'all'   : adjusts all histograms (as on loading of new image)
        %[redLevel,greenLevel,blueLevel] = updateParameters
        updateParameters
        if ~ismember(option,{'all','FromRadioButton'})
            set(prebuiltOptions,'selectedObject',[]);
        end
        % ACTUAL ADJUSTMENT:
        imgout = imgin(:,:,1)*redLevel + imgin(:,:,2)*greenLevel + imgin(:,:,3)*blueLevel;
        if ~isa(imgout,'double')
            fprintf('\nNOTE: Display may be limited by class (%s) of working image.\nConsider converting to double...\n',class(imgout));
        end
        set(imgOutHandle,'cdata',imgout);
        set(ax(2),'climmode','auto','xlimmode','auto','ylimmode','auto');
        % REFRESH HISTOGRAMS
        % 'ALL'/'OUTPUT';
        if strcmp(option,'all')
            % Update input histograms:
            for ii = 1:3
                refreshHistogram(histax(ii),imgin(:,:,ii),ii);
            end
        end
        % ALWAYS refresh output histograms on update:
        refreshHistogram(histax(4),imgout,4);
        refreshBarGraph
        refreshSaturationAx
    end %update

    function updateParameters(varargin)
        redLevel = get(redLevelSlider,'value');
        greenLevel = get(greenLevelSlider,'value');
        blueLevel = get(blueLevelSlider,'value');
        set(redLevelText,'string',num2str(redLevel));
        set(greenLevelText,'string',num2str(greenLevel));
        set(blueLevelText,'string',num2str(blueLevel));
        drawnow
    end %updateParameters

end