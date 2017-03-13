function varargout = SeqAlignTool(varargin)
% SEQALIGNTOOL MATLAB code for SeqAlignTool.fig
%      SEQALIGNTOOL, by itself, creates a new SEQALIGNTOOL or raises the existing
%      singleton*.
%
%      H = SEQALIGNTOOL returns the handle to a new SEQALIGNTOOL or the handle to
%      the existing singleton*.
%
%      SEQALIGNTOOL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SEQALIGNTOOL.M with the given input arguments.
%
%      SEQALIGNTOOL('Property','Value',...) creates a new SEQALIGNTOOL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SeqAlignTool_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SeqAlignTool_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SeqAlignTool

% Last Modified by GUIDE v2.5 15-Feb-2017 23:37:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SeqAlignTool_OpeningFcn, ...
                   'gui_OutputFcn',  @SeqAlignTool_OutputFcn, ...
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

function SeqAlignTool_OpeningFcn(hObject, eventdata, handles, varargin)
%Get the variables
SeqNT = varargin{1};
SeqAA = varargin{2};

%Save them to table
UserData = [SeqNT SeqAA];
set(handles.uitable_SeqData,'Data',UserData);

handles.output = hObject;
guidata(hObject, handles);
uiwait;

function varargout = SeqAlignTool_OutputFcn(hObject, eventdata, handles) 
%Extracting the table, minus the first 2 columns.
OutputData = get(handles.uitable_SeqData,'Data');
if size(OutputData,2) < 4 %Nothing was done
    OutputData = cell(1,4);
end
varargout{1} = OutputData(:,3); %NT
varargout{2} = OutputData(:,4); %AA
delete(handles.figure1);

function edit_ReadFrame_Callback(hObject, eventdata, handles)
function edit_ReadFrame_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function listbox_Algorithm_Callback(hObject, eventdata, handles)
function listbox_Algorithm_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_RefSeq_Callback(hObject, eventdata, handles)
RefSeq = upper(get(hObject,'String'));
BadChar = regexp(RefSeq,['[^' int2aa([1:20]) ']']);
RefSeq(BadChar) = 'X';
set(hObject,'string',RefSeq);
refreshRefSeq(hObject, eventdata, handles);
function edit_RefSeq_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function listbox_SeqType_Callback(hObject, eventdata, handles)
CurValue = get(hObject,'Value');
if CurValue == 1 %AA option, so not need to include read frame info
    set(handles.uipanel_RF,'Visible','off');
else
    set(handles.uipanel_RF,'Visible','on');
end
refreshRefSeq(hObject, eventdata, handles);

function listbox_SeqType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton_Accept_Callback(hObject, eventdata, handles)
uiresume;

function pushbutton_Cancel_Callback(hObject, eventdata, handles)
set(handles.uitable_SeqData,'Data',{});
uiresume;

function pushbutton_Align_Callback(hObject, eventdata, handles)
SeqType = get(handles.listbox_SeqType,'value');
if SeqType == 1 %AA
    Alphabet = 'aa';
    SeqLoc = 2;
elseif SeqType == 2 %NT
    Alphabet = 'nt';
    SeqLoc = 1;
end

%Get the sequence data that needs to be aligned
SeqData = get(handles.uitable_SeqData,'Data');
Seq = SeqData(:,SeqLoc);

%Begin the alignment
RefSeq = get(handles.edit_RefSeq,'String');
[AlignedSeq, StartAt] = alignMultSeq(RefSeq,Seq,Alphabet,0);
SeqData(:,SeqLoc+2) = AlignedSeq;

%Collect and translate, if needed
switch Alphabet
    case 'nt'
        %Need to translate NT to AA
        RFvals = zeros(1,3);
        RFvals(1) = get(handles.radiobutton_RF1,'value');
        RFvals(2) = get(handles.radiobutton_RF2,'value');
        RFvals(3) = get(handles.radiobutton_RF3,'value');        
        ReadingFrame = find(RFvals == 1);
        AAseq = cell(size(AlignedSeq));
        for j = 1:size(AlignedSeq,1)
            %Convert a dash into triple dash
            CurSeq = strrep(AlignedSeq{j},'-','N');
            AAseq{j} = nt2aa(CurSeq,'ACGTonly','false','Frame',ReadingFrame);
        end
        SeqData(:,3) = AlignedSeq;
        SeqData(:,4) = AAseq;
    case 'aa'
        StartAt(StartAt<0) = StartAt(StartAt<0) + 1;%Need to shift by 1 for negative, due to convention of starting -2 -1 1 2.
        StartPos = 3*(StartAt-1) + 1;
        EndPos = StartPos + length(RefSeq)*3 - 1;
        for j = 1:size(SeqData,1)
            %Need to extract NT from position
            if StartPos(j) < 0
                PadLeft = repmat('N',1,abs(StartPos(j)));
                StartPos(j) = 1;
            else 
                PadLeft = '';
            end
            if EndPos(j) > length(SeqData{j,1});
                PadRight = repmat('N',1,length(SeqData{j,1}) - EndPos(j));
                EndPos(j) = length(SeqData{j,1});
            else
                PadRight = '';
            end
            SeqData{j,3} = [PadLeft SeqData{j,1}(StartPos(j):EndPos(j)) PadRight];
        end
end
set(handles.uitable_SeqData,'Data',SeqData);

function radiobutton_RF1_Callback(hObject, eventdata, handles)
handleButtons(hObject, eventdata, handles);

function radiobutton_RF2_Callback(hObject, eventdata, handles)
handleButtons(hObject, eventdata, handles);

function radiobutton_RF3_Callback(hObject, eventdata, handles)
handleButtons(hObject, eventdata, handles);
%Ensure only 1 radio button is selected
function handleButtons(hObject, eventdata, handles)
CurValue = get(hObject,'Value');
ButtonHandles = {handles.radiobutton_RF1;
                 handles.radiobutton_RF2;
                 handles.radiobutton_RF3};
if CurValue == 1 %Set the other to 0
    for j = 1:length(ButtonHandles)
        if ButtonHandles{j} ~= hObject
            set(ButtonHandles{j},'Value',0);
        end
    end    
elseif CurValue == 0 %Reset to 1 since you can't turn off the one you chose
    set(hObject,'Value',1);
end

%Will refresh the GUI to fill in the RefSeq and the translated AA
function refreshRefSeq(hObject, eventdata, handles)
%Translate RefSeq to AA, if RefSeq is NT
RefSeq = get(handles.edit_RefSeq,'String');
SeqType = get(handles.listbox_SeqType,'value');
if SeqType == 1 %AA 
    SeqRF1 = '';
    SeqRF2 = '';
    SeqRF3 = '';
elseif SeqType == 2 %NT
    SeqRFall = nt2aa(RefSeq,'Frame','all','ACGTonly','false');
    [SeqRF1, SeqRF2, SeqRF3] = deal(SeqRFall{:});
end

%Fill in the text boxes
set(handles.text_RF1,'String',SeqRF1);
set(handles.text_RF2,'String',SeqRF2);
set(handles.text_RF3,'String',SeqRF3);
