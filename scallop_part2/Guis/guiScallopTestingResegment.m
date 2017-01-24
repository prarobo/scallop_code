function varargout = guiScallopTestingResegment(varargin)
% GUISCALLOPTESTINGRESEGMENT MATLAB code for guiScallopTestingResegment.fig
%      GUISCALLOPTESTINGRESEGMENT, by itself, creates a new GUISCALLOPTESTINGRESEGMENT or raises the existing
%      singleton*.
%
%      H = GUISCALLOPTESTINGRESEGMENT returns the handle to a new GUISCALLOPTESTINGRESEGMENT or the handle to
%      the existing singleton*.
%
%      GUISCALLOPTESTINGRESEGMENT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUISCALLOPTESTINGRESEGMENT.M with the given input arguments.
%
%      GUISCALLOPTESTINGRESEGMENT('Property','Value',...) creates a new GUISCALLOPTESTINGRESEGMENT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before guiScallopTestingResegment_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to guiScallopTestingResegment_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help guiScallopTestingResegment

% Last Modified by GUIDE v2.5 07-Jan-2015 10:20:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @guiScallopTestingResegment_OpeningFcn, ...
                   'gui_OutputFcn',  @guiScallopTestingResegment_OutputFcn, ...
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


% --- Executes just before guiScallopTestingResegment is made visible.
function guiScallopTestingResegment_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to guiScallopTestingResegment (see VARARGIN)

% Choose default command line output for guiScallopTestingResegment
handles.output = hObject;

% Clear up
clc

switch nargin
    case 3
        % Disable some controls
        set(handles.btnPrevObject, 'Enable', 'inactive');
        set(handles.btnNextObject, 'Enable', 'inactive'); 
        set(handles.slidObject, 'Enable', 'inactive'); 
        guidata(hObject, handles);
    case 5
        temp = load(varargin{1});
        handles.scallopLearning = temp.scallopLearning;
        temp = load(varargin{2});
        handles.scallopTesting = temp.scallopTesting;
        handles.objectI = 1;
        guidata(hObject, handles);
        updateGUI(hObject, handles);
        set(handles.slidObject, 'Min', 1, 'Max', handles.scallopTesting.params.numObjects, 'Value',1);
    otherwise
        error('Incompatible inputs');
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes guiScallopTestingResegment wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = guiScallopTestingResegment_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in btnPrevObject.
function btnPrevObject_Callback(hObject, eventdata, handles)
% hObject    handle to btnPrevObject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.objectI = max(1,handles.objectI - 1);
guidata(hObject, handles);
updateGUI(hObject, handles);


% --- Executes on button press in btnNextObject.
function btnNextObject_Callback(hObject, eventdata, handles)
% hObject    handle to btnNextObject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.objectI = min(handles.objectI + 1,handles.scallopTesting.params.numObjects);
guidata(hObject, handles);
updateGUI(hObject, handles);

% --- Executes on button press in btnTestData.
function btnTestData_Callback(hObject, eventdata, handles)
% hObject    handle to btnTestData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

temp = load(uigetfile);
handles.scallopTesting = temp.scallopTesting;
if isfield(handles, 'scallopLearning')
    set(handles.btnPrevObject, 'Enable', 'on');
    set(handles.btnNextObject, 'Enable', 'on');
end
handles.objectI = 1;
guidata(hObject, handles);
updateGUI(hObject, handles);

% --- Executes on button press in btnLearnData.
function btnLearnData_Callback(hObject, eventdata, handles)
% hObject    handle to btnLearnData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

temp = load(uigetfile);
handles.scallopLearning = temp.scallopLearning;
if isfield(handles, 'scallopTesting')
    set(handles.btnPrevObject, 'Enable', 'on');
    set(handles.btnNextObject, 'Enable', 'on');
end
handles.objectI = 1;
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
if ~handles.scallopTesting.resegmentData.resegAvailable(handles.objectI)
    return
end

% Loading current image
currX = round(handles.scallopTesting.segmentData.objectList(handles.objectI,1));
currY = round(handles.scallopTesting.segmentData.objectList(handles.objectI,2));
currRadius = round(handles.scallopTesting.segmentData.objectList(handles.objectI,3));
currImageName = handles.scallopTesting.fileInfo.filename{handles.scallopTesting.segmentData.objectList(handles.objectI,6)};

if handles.scallopTesting.params.useSmoothImages
    filename = sprintf('%s/%s', handles.scallopTesting.params.imageFolder, currImageName);
else
    filename = sprintf('%s/%s', handles.scallopTesting.params.imageFolderUnsmooth, currImageName);
end

currImage = imread(filename);
resegmentWindowSize = handles.scallopTesting.params.resegmentWindowSize;
imageWidth = handles.scallopTesting.params.imageSize(2);
imageHeight = handles.scallopTesting.params.imageSize(1);

    
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
                                                        handles.scallopTesting.params.resegRadiusExtnPercent, ...
                                                        handles.scallopTesting.params.imageFolderUnsmooth);
% BG
bgMask = generateBGMask(cropWindowWidth, cropWindowHeight, handles.scallopTesting.params.bgRadiusPercent, fgMask);

% Applying masks
segmentImageFG = cropImage;
segmentImageBG = cropImage;
fgImage = cropImage;
bgImage = cropImage;
repThreshImage = cropImage;

for i=1:3
    segmentImageFG(:,:,i) = segmentImageFG(:,:,i).*uint8(handles.scallopTesting.resegmentData.segmentMask{handles.objectI});
    segmentImageBG(:,:,i) = segmentImageBG(:,:,i).*uint8(imcomplement(handles.scallopTesting.resegmentData.segmentMask{handles.objectI}));
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


% --- Executes on slider movement.
function slidObject_Callback(hObject, eventdata, handles)
% hObject    handle to slidObject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

handles.objectI = round(get(hObject,'Value'));
guidata(hObject, handles);
updateGUI(hObject, handles);

% --- Executes during object creation, after setting all properties.
function slidObject_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slidObject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
