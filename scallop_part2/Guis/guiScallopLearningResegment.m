function varargout = guiScallopLearningResegment(varargin)
% GUISCALLOPLEARNINGRESEGMENT MATLAB code for guiScallopLearningResegment.fig
%      GUISCALLOPLEARNINGRESEGMENT, by itself, creates a new GUISCALLOPLEARNINGRESEGMENT or raises the existing
%      singleton*.
%
%      H = GUISCALLOPLEARNINGRESEGMENT returns the handle to a new GUISCALLOPLEARNINGRESEGMENT or the handle to
%      the existing singleton*.
%
%      GUISCALLOPLEARNINGRESEGMENT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUISCALLOPLEARNINGRESEGMENT.M with the given input arguments.
%
%      GUISCALLOPLEARNINGRESEGMENT('Property','Value',...) creates a new GUISCALLOPLEARNINGRESEGMENT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before guiScallopLearningResegment_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to guiScallopLearningResegment_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help guiScallopLearningResegment

% Last Modified by GUIDE v2.5 05-Jan-2015 02:12:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @guiScallopLearningResegment_OpeningFcn, ...
                   'gui_OutputFcn',  @guiScallopLearningResegment_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before guiScallopLearningResegment is made visible.
function guiScallopLearningResegment_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to guiScallopLearningResegment (see VARARGIN)

% Choose default command line output for guiScallopLearningResegment
handles.output = hObject;

% Clear up
clc

switch nargin
    case 3
        % Disable some controls
        set(handles.btnPrev, 'Enable', 'inactive');
        set(handles.btnNext, 'Enable', 'inactive');        
        guidata(hObject, handles);
    case 4
        temp = load(varargin{1});
        handles.scallopLearning = temp.scallopLearning;
        handles.scallopI = 1;
        guidata(hObject, handles);
        updateGUI(hObject, handles);
    otherwise
        error('Incompatible inputs');
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes guiScallopLearningResegment wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = guiScallopLearningResegment_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in btnPrev.
function btnPrev_Callback(hObject, eventdata, handles)
% hObject    handle to btnPrev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.scallopI > 1
    handles.scallopI = handles.scallopI - 1;
else
    handles.scallopI = handles.scallopLearning.params.numScallops;
end
guidata(hObject, handles);
updateGUI(hObject, handles);


% --- Executes on button press in btnNext.
function btnNext_Callback(hObject, eventdata, handles)
% hObject    handle to btnNext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.scallopI < handles.scallopLearning.params.numScallops
    handles.scallopI = handles.scallopI + 1;
else
    handles.scallopI = 1;
end
guidata(hObject, handles);
updateGUI(hObject, handles);

% --- Executes on button press in btnData.
function btnData_Callback(hObject, eventdata, handles)
% hObject    handle to btnData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

temp = load(uigetfile);
handles.scallopLearning = temp.scallopLearning;
set(handles.btnPrev, 'Enable', 'on');
set(handles.btnNext, 'Enable', 'on');
handles.scallopI = 1;
guidata(hObject, handles);
updateGUI(hObject, handles);

% Function to redraw gui
function updateGUI(hObject, handles)

axes(handles.axesImage); cla;
axes(handles.axesSegmentFG); cla;
axes(handles.axesSegmentBG); cla;
axes(handles.axesFG); cla;
axes(handles.axesBG); cla;
axes(handles.axesRep); cla;
axes(handles.axesRepThresh); cla;

% Skipping scallops with no resegmentation data
if ~handles.scallopLearning.resegmentData.resegAvailable(handles.scallopI)
    return
end

% Loading current image
currX = round(handles.scallopLearning.groundTruth.X(handles.scallopI));
currY = round(handles.scallopLearning.groundTruth.Y(handles.scallopI));
currRadius = round(handles.scallopLearning.groundTruth.radius(handles.scallopI));
currImageName = handles.scallopLearning.groundTruth.ImageName{handles.scallopI};

if handles.scallopLearning.params.useSmoothImages
    filename = sprintf('%s/%s', handles.scallopLearning.params.imageFolder, currImageName);
else                                            
    filename = sprintf('%s/%s', handles.scallopLearning.params.imageFolderUnsmooth, currImageName);
end

currImage = imread(filename);
resegmentWindowSize = handles.scallopLearning.params.resegmentWindowSize;
imageWidth = handles.scallopLearning.params.imageSize(2);
imageHeight = handles.scallopLearning.params.imageSize(1);

                                                
% Compute BB and crop image
bb = computeBB(currX, currY, resegmentWindowSize, resegmentWindowSize, imageWidth, imageHeight);
cropImage = imcrop(currImage, bb);
cropX = currX-bb(1)+1;
cropY = currY-bb(2)+1;
cropWindowWidth = size(cropImage, 2);
cropWindowHeight = size(cropImage, 1);

% FG
[~, fgMask, ~, repScallop, repThresh] = generateFGMask(currX, currY, cropX, cropY, cropWindowWidth, cropWindowHeight, currRadius, ...
                                                        handles.scallopLearning.scallopPosition, ...
                                                        handles.scallopLearning.groundTruth, ...
                                                        handles.scallopLearning.params.resegRadiusExtnPercent, ...
                                                        handles.scallopLearning.params.scallopMaskThickness, ...
                                                        handles.scallopLearning.params.crescentAngle, ...
                                                        handles.scallopLearning.params.imageFolderUnsmooth);
% BG
bgMask = generateBGMask(cropWindowWidth, cropWindowHeight, handles.scallopLearning.params.bgRadiusPercent, fgMask);


% Applying masks
segmentImageFG = cropImage;
segmentImageBG = cropImage;
fgImage = cropImage;
bgImage = cropImage;
repThreshImage = cropImage;

for i=1:3
    segmentImageFG(:,:,i) = segmentImageFG(:,:,i).*uint8(handles.scallopLearning.resegmentData.segmentMask{handles.scallopI});
    segmentImageBG(:,:,i) = segmentImageBG(:,:,i).*uint8(imcomplement(handles.scallopLearning.resegmentData.segmentMask{handles.scallopI}));
    fgImage(:,:,i) = fgImage(:,:,i).*uint8(fgMask);
    bgImage(:,:,i) = bgImage(:,:,i).*uint8(bgMask);
    repThreshImage(:,:,i) = repThreshImage(:,:,i).*uint8(repThresh);
end

% Display
axes(handles.axesImage); imshow(cropImage);
axes(handles.axesSegmentFG); imshow(segmentImageFG);
axes(handles.axesSegmentBG); imshow(segmentImageBG);
axes(handles.axesFG); imshow(fgImage);
axes(handles.axesBG); imshow(bgImage);
axes(handles.axesRep); imshow(repScallop);
axes(handles.axesRepThresh); imshow(repThreshImage);

