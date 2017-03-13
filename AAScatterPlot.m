function varargout = AAScatterPlot(varargin)
% AASCATTERPLOT MATLAB code for AAScatterPlot.fig
%      AASCATTERPLOT, by itself, creates a new AASCATTERPLOT or raises the existing
%      singleton*.
%
%      H = AASCATTERPLOT returns the handle to a new AASCATTERPLOT or the handle to
%      the existing singleton*.
%
%      AASCATTERPLOT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AASCATTERPLOT.M with the given input arguments.
%
%      AASCATTERPLOT('Property','Value',...) creates a new AASCATTERPLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AAScatterPlot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AAScatterPlot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AAScatterPlot

% Last Modified by GUIDE v2.5 09-Mar-2017 08:19:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AAScatterPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @AAScatterPlot_OutputFcn, ...
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

function AAScatterPlot_OpeningFcn(hObject, eventdata, handles, varargin)
%Make sure to add the Font paths
Mpath = mfilename('fullpath');
SlashLoc = regexpi(Mpath,'\\|\/');
Mpath = Mpath(1:SlashLoc(end));
FontPath = [Mpath 'Font'];
addpath(FontPath);

%Initialize file variables
handles.Data(1).FileName = [];
handles.Data(1).PathName = [];

%Initialize the Weblogo & Locator
imshow([1],'Parent',handles.axes_WebLogo);

%Empty the data table
set(handles.Table_1,'Data',{});
set(handles.Table_1,'ColumnName',{'1','2','3'});

%Initialize the graphs
h1 = scatter(handles.axes_ScatterPlot,1,1,1);
set(h1,'XData',[],'YData',[],'SizeData',[]);
SetPlotAxis(handles.axes_ScatterPlot,handles);
SetPlotYLabel(handles.axes_ScatterPlot,handles);
SetPlotXLabel(handles.axes_ScatterPlot,handles);
SetPlotTitle(handles.axes_ScatterPlot,handles)

%Reset components
set(handles.checkbox_FirstRowHeader,'Value',0); %Reset the checkbox.
set(handles.edit_CurPos,'String','1'); %Reset the CurPos
set(handles.edit_StartPos,'String','1'); %Reset the StartPos
set(handles.edit_EndPos,'String','1'); %Reset the EndPos
set(handles.edit_SearchSeqName,'String',''); %Reset searches
set(handles.edit_SearchNT,'String',''); %Reset NT searches
set(handles.edit_SearchAA,'String',''); %Reset AA searches
set(handles.text_FileName,'String',''); %Reset the file name
set(handles.text_NumOfSeq,'String',''); %Reset the Seq Num Count

%Initialize the codon plots
set(handles.axes_CodonPlot,'XTickLabel','','YTickLabel','');
delete(get(handles.axes_CodonPlot,'Children'));

%Output handle, just in case?
handles.output = hObject;

%Update handles structure
guidata(hObject, handles);

function varargout = AAScatterPlot_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

%==========================================================================
%Opening and Saving Plots or Settings
%==========================================================================
function pushbutton_OpenSeq_Callback(hObject, eventdata, handles)
[FileName, FilePath] = uigetfile('*.xls;*.xlsx;*.fa;*.csv;*.txt;*.tsv','MultiSelect','off');

if isempty(FileName) == 0
    AAScatterPlot_OpeningFcn(hObject, eventdata, handles); %Refresh everything
    
    DotLoc = find(FileName == '.');
    FileExt = FileName(DotLoc:end);

    switch FileExt
        case '.csv'
            RawData = readDlmFile([FilePath FileName],'delimiter',',');
        case '.txt'
            RawData = readDlmFile([FilePath FileName],'delimiter',',');
        case '.tsv'
            RawData = readDlmFile([FilePath FileName],'delimiter','\t');
        case '.xlsx'
            [~,~,RawData] = xlsread([FilePath FileName]);
        case '.xls'
            [~,~,RawData] = xlsread([FilePath FileName]);
        case '.fa'
            RawStruct = fastaread([FilePath FileName]);
            RawData = struct2cell(RawStruct)';
    end

    %Remove NaN Row
    DelRow = zeros(size(RawData,1),1)>1;
    for jrow = 1:size(RawData,1)
        DelCheck = 0;
        for jcol = 1:size(RawData,2)
            if isnan(RawData{jrow,jcol}) == 1
                DelCheck = DelCheck+1;
            end
        end
        if DelCheck == size(RawData,2)
            DelRow(jrow) = 1;
        end
    end
    RawData(DelRow,:) = [];

    %Remove NaN Col
    DelCol = zeros(1,size(RawData,2),1)>1;
    for jcol = 1:size(RawData,2)
        DelCheck = 0;
        for jrow = 1:size(RawData,1)
            if isnan(RawData{jrow,jcol}) == 1
                DelCheck = DelCheck+1;
            end
        end
        if DelCheck == size(RawData,1)
            DelCol(jcol) = 1;
        end
    end
    RawData(:,DelCol) = [];
    
    %Search to see if which one is the name, nt, aa columns
    NameCol = 1;
    NTcol = 0;
    AAcol = 0;
    for c = 1:size(RawData,2)
        if ischar(RawData{end,c})
            NotNT = ~isempty(regexpi(RawData{end,c},'[^ACGTUN\*]')); %Only assume first one is NameCol
            NotAA = ~isempty(regexpi(RawData{end,c},['[^' int2aa(1:24) ']']));
            if NameCol == 1 && NotNT && NotAA
                NameCol = c; 
                continue;
            end
            if NTcol == 0 && ~NotNT
                NTcol = c;
                continue
            end
            if AAcol == 0 && ~NotAA
                AAcol = c;
                continue
            end
        end
    end
    
    %If there is no AA col, need to translate
    if AAcol == 0 && NTcol > 0
        AddData = nt2aa(RawData(:,NTcol),'acgtonly','false');
        RawData = [RawData AddData];
        AAcol = size(RawData,2);
    elseif AAcol == 0 && NTcol == 0
        error('Could not detect NT or AA data')
    end
    
    %Make sure all columns have equal length
    MaxNTlen = 0;
    MaxAAlen = 0;
    for r = 1:size(RawData,1)
        NTlen = length(RawData{r,NTcol});
        if NTlen > MaxNTlen; MaxNTlen = NTlen; end
        
        AAlen = length(RawData{r,AAcol});
        if AAlen > MaxAAlen; MaxAAlen = AAlen; end
    end
    for r = 1:size(RawData,1)
        NTlen = length(RawData{r,NTcol});
        if NTlen < MaxNTlen;
            RawData{r,NTcol} = [RawData{r,NTcol} repmat('N',1,MaxNTlen-NTlen)];
        end
        
        AAlen = length(RawData{r,AAcol});
        if AAlen < MaxAAlen;
            RawData{r,AAcol} = [RawData{r,AAcol} repmat('X',1,MaxAAlen-AAlen)];
        end
    end
        
    %Set the GUI components
    set(handles.Table_1,'Data',RawData);
    set(handles.edit_SelectNameCol,'string',num2str(NameCol));
    set(handles.edit_SelectNTCol,'string',num2str(NTcol));
    set(handles.edit_SelectAACol,'string',num2str(AAcol));
    set(handles.text_FileName,'String',FileName);
    set(handles.text_NumOfSeq,'String',num2str(size(RawData,1)));
    
    %Save certain information
    handles.FileName = FileName;
    handles.PathName = FilePath;
    handles.RawData = RawData;
    handles.Header = {};
    
    %Update handles structure
    guidata(hObject, handles);    
end

function pushbutton_SavePlots_Callback(hObject, eventdata, handles)
%Determine the GUI and axes size to calculate figure position.
GuiUnits = get(handles.figure1,'Units'); %Should be points
if strcmpi(GuiUnits,'Points') == 0
    set(handles.figure1,'Units','Points');
end
GuiPos = get(handles.figure1,'Position');

%Creating popup figure the duplicates the plot
F1 = figure;
set(F1,'Units','Points');
set(F1,'Position',GuiPos);
H1 = copyobj(handles.axes_ScatterPlot,F1); %Note: Does not copy colors. Need to do this next.
CData1 = get(handles.figure1,'ColorMap');
set(F1,'ColorMap',CData1);

set(H1,'Units','Points'); %To prevent autoresizing issues if using normalized.
set(F1,'Color',[1 1 1]) %Set to white background

%Calculating figure and axes positions 
FigPos = get(F1,'Position');
PadPos = get(H1,'TightInset');
AxiPos = get(H1,'Position');
NewFigPos = [FigPos(1)+AxiPos(1)-PadPos(1),FigPos(2)+AxiPos(2)-PadPos(2),AxiPos(3)+PadPos(1)+PadPos(3),AxiPos(4)+PadPos(2)+PadPos(4)];
NewAxiPos = [PadPos(1),PadPos(2),AxiPos(3),AxiPos(4)];

%Setting figure positions
set(F1,'Position',NewFigPos); %Reposition figure relative
set(H1,'Position',NewAxiPos); %Reposition axes relative to figure

%Saving files as a EPS file
set(F1, 'PaperUnits', get(F1,'Units'), 'PaperPosition', get(F1,'Position'));

[SaveName SavePath] = uiputfile('*.eps;*.emf;*.png;*.tif;*.jpg');
saveas(F1,[SavePath SaveName])
close(F1);

%Saving the WebLogo
DotLoc = find(SaveName == '.');
if isempty(DotLoc)
    SaveNamePre = SaveName;
    SaveNameExt = '.png';
else
    SaveNamePre = SaveName(1:DotLoc(end)-1);
    SaveNameExt = SaveName(DotLoc:end);
end
if strcmp(SaveNameExt,'.eps') || strcmp(SaveNameExt,'.emf')
    SaveNameExt = '.png';
end
SaveName2 = [SaveNamePre '_WebLogo' SaveNameExt];
ImageFile = get(get(handles.axes_WebLogo,'Children'),'CData');
imwrite(ImageFile,[SavePath SaveName2]);

function pushbutton_SaveMultPlots_Callback(hObject, eventdata, handles)
%Determine the GUI and axes size to calculate figure position.
GuiUnits = get(handles.figure1,'Units'); %Should be points
if strcmpi(GuiUnits,'Points') == 0
    set(handles.figure1,'Units','Points');
end
GuiPos = get(handles.figure1,'Position');

%Extract the start and end positions
StartPos = str2double(get(handles.edit_StartPos,'string'));
EndPos = str2double(get(handles.edit_EndPos,'string'));
CurPos = get(handles.edit_CurPos,'string');

%Establish the save name prefix
[SaveName, PathName] = uiputfile('*.eps;*.png;*.tif;*.emf;*.jpg','Save file as');
DotLoc = find(SaveName == '.');
if ~isempty(DotLoc)
    SaveNameFmt = SaveName(DotLoc(end):end);
    SaveName = SaveName(1:DotLoc(end)-1);
else
    SaveNameFmt = '.tif'; %By default
end

%See if Y-axis is disabled, as then you would also remove the 2nd y axis
%labels
YaxisOn = get(handles.Radio_YAxis,'Value');

for k = StartPos:EndPos
    disp(num2str(k))
    set(handles.edit_CurPos,'string',num2str(k));
    pushbutton_Plot_Callback(hObject, eventdata, handles);
    
    %Creating popup figure the duplicates the plot
    F1 = figure;
    set(F1,'Units','Points');
    set(F1,'Position',GuiPos);           
    H1 = copyobj(handles.axes_ScatterPlot,F1); %Note: Does not copy colors. Need to do this next.
    CData1 = get(handles.figure1,'ColorMap');
    
    if YaxisOn == 0 && k ~= StartPos%Remove the Y tick label
        set(H1,'YTickLabel','');
    end

    set(F1,'ColorMap',CData1);
    set(H1,'Units','Points'); %To prevent autoresizing issues if using normalized.
    set(F1,'Color',[1 1 1]) %Set to white background

    %Calculating figure and axes positions 
    FigPos = get(F1,'Position');
    PadPos = get(H1,'TightInset');
    AxiPos = get(H1,'Position');
    NewFigPos = [FigPos(1)+AxiPos(1)-PadPos(1),FigPos(2)+AxiPos(2)-PadPos(2),AxiPos(3)+PadPos(1)+PadPos(3),AxiPos(4)+PadPos(2)+PadPos(4)];
    NewAxiPos = [PadPos(1),PadPos(2),AxiPos(3),AxiPos(4)];

    %Setting figure positions
    set(F1,'Position',NewFigPos); %Reposition figure relative
    set(H1,'Position',NewAxiPos); %Reposition axes relative to figure
    set(F1, 'PaperUnits', get(F1,'Units'), 'PaperPosition', get(F1,'Position'));

    %Saving individual files
    saveas(F1,[PathName SaveName '_' num2str(k) SaveNameFmt]);
    close(F1)
end

%Reset back to previous current position
set(handles.edit_CurPos,'string',CurPos);

%==========================================================================
%Plot Label Modification
%==========================================================================
function Radio_RenumberByCleave_Callback(hObject, eventdata, handles)
pushbutton_Plot_Callback(hObject, eventdata, handles)

function Radio_Title_Callback(hObject, eventdata, handles)
pushbutton_Plot_Callback(hObject, eventdata, handles)

function edit_TitleFont_Callback(hObject, eventdata, handles)
pushbutton_Plot_Callback(hObject, eventdata, handles);
function edit_TitleFont_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_TitleSize_Callback(hObject, eventdata, handles)
pushbutton_Plot_Callback(hObject, eventdata, handles);
function edit_TitleSize_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton_TitleFont_Callback(hObject, eventdata, handles)
SetFont = uisetfont;
set(handles.edit_TitleFont,'string',SetFont.FontName);
set(handles.edit_TitleSize,'string',num2str(SetFont.FontSize));
pushbutton_Plot_Callback(hObject, eventdata, handles);

function Radio_XAxis_Callback(hObject, eventdata, handles)
pushbutton_Plot_Callback(hObject, eventdata, handles);

function edit_XAxisFont_Callback(hObject, eventdata, handles)
pushbutton_Plot_Callback(hObject, eventdata, handles);
function edit_XAxisFont_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_XAxisSize_Callback(hObject, eventdata, handles)
pushbutton_Plot_Callback(hObject, eventdata, handles);
function edit_XAxisSize_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton_XAxisFont_Callback(hObject, eventdata, handles)
SetFont = uisetfont;
set(handles.edit_XAxisFont,'string',SetFont.FontName);
set(handles.edit_XAxisSize,'string',num2str(SetFont.FontSize));
pushbutton_Plot_Callback(hObject, eventdata, handles);

function Radio_YAxis_Callback(hObject, eventdata, handles)
pushbutton_Plot_Callback(hObject, eventdata, handles);

function edit_YAxisFont_Callback(hObject, eventdata, handles)
pushbutton_Plot_Callback(hObject, eventdata, handles);
function edit_YAxisFont_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_YAxisSize_Callback(hObject, eventdata, handles)
pushbutton_Plot_Callback(hObject, eventdata, handles);
function edit_YAxisSize_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton_YAxisFont_Callback(hObject, eventdata, handles)
SetFont = uisetfont;
set(handles.edit_YAxisFont,'string',SetFont.FontName);
set(handles.edit_YAxisSize,'string',num2str(SetFont.FontSize));
pushbutton_Plot_Callback(hObject, eventdata, handles);

function Radio_Legend_Callback(hObject, eventdata, handles)
pushbutton_Plot_Callback(hObject, eventdata, handles);

function edit_LegendFont_Callback(hObject, eventdata, handles)
pushbutton_Plot_Callback(hObject, eventdata, handles);
function edit_LegendFont_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_LegendSize_Callback(hObject, eventdata, handles)
pushbutton_Plot_Callback(hObject, eventdata, handles);
function edit_LegendSize_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton_LegendFont_Callback(hObject, eventdata, handles)
SetFont = uisetfont;
set(handles.edit_LegendFont,'string',SetFont.FontName);
set(handles.edit_LegendSize,'string',num2str(SetFont.FontSize));
pushbutton_Plot_Callback(hObject, eventdata, handles);

function Radio_Grid_Callback(hObject, eventdata, handles)
pushbutton_Plot_Callback(hObject, eventdata, handles);

function edit_Area_Callback(hObject, eventdata, handles)
Value = str2double(get(hObject,'string'));
Value = round(Value);
MinValue = 1;
MaxValue = Inf;
if Value < MinValue; Value = MinValue; end
if Value > MaxValue; Value = MaxValue; end
if isnan(Value); Value = MinValue; end
set(hObject,'string',num2str(Value));
pushbutton_Plot_Callback(hObject, eventdata, handles);
function edit_Area_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton_AreaShrink_Callback(hObject, eventdata, handles)
AreaSize = str2double(get(handles.edit_Area,'string'));
AreaSize = round(AreaSize*0.95);
if AreaSize <= 0; AreaSize = 0; end
set(handles.edit_Area,'string',num2str(AreaSize));
pushbutton_Plot_Callback(hObject, eventdata, handles);

function pushbutton_AreaGrow_Callback(hObject, eventdata, handles)
AreaSize = str2double(get(handles.edit_Area,'string'));
AreaSize = round(AreaSize*1.05);
set(handles.edit_Area,'string',num2str(AreaSize));
pushbutton_Plot_Callback(hObject, eventdata, handles);

%==========================================================================
%Position Setting
%==========================================================================

function edit_StartPos_Callback(hObject, eventdata, handles)
Value = round(str2double(get(hObject,'string')));
MinValue = 1;
MaxValue = Inf;
if Value < MinValue; Value = MinValue; end
if Value > MaxValue; Value = MaxValue; end
if isnan(Value); Value = MinValue; end
set(hObject,'string',num2str(Value));

%Adjust the EndPos if needed
EndPos = str2double(get(handles.edit_EndPos,'string'));
if Value > EndPos
    set(handles.edit_EndPos,'string',num2str(Value));
end

%Adjust the CurPos if needed
CurPos = str2double(get(handles.edit_CurPos,'string'));
if Value > CurPos
    set(handles.edit_CurPos,'string',num2str(Value));
end
%Update the plot
pushbutton_Plot_Callback(hObject, eventdata, handles);
DrawLogo(hObject,handles)
function edit_StartPos_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_EndPos_Callback(hObject, eventdata, handles)
Value = round(str2double(get(hObject,'string')));
MinValue = 1;
MaxValue = Inf;
if Value < MinValue; Value = MinValue; end
if Value > MaxValue; Value = MaxValue; end
if isnan(Value); Value = MinValue; end
set(hObject,'string',num2str(Value));

%Adjust the StartPos if needed
StartPos = str2double(get(handles.edit_EndPos,'string'));
if Value < StartPos
    set(handles.edit_StartPos,'string',num2str(Value));
end

%Adjust the CurPos if needed
CurPos = str2double(get(handles.edit_CurPos,'string'));
if Value < CurPos
    set(handles.edit_CurPos,'string',num2str(Value));
end
%Update the plot
pushbutton_Plot_Callback(hObject, eventdata, handles);
DrawLogo(hObject,handles)
function edit_EndPos_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_CleavePos_Callback(hObject, eventdata, handles)
Value = str2double(get(hObject,'string'));
Value = round(Value);
MinValue = 0;
MaxValue = Inf;
if Value < MinValue; Value = MinValue; end
if Value > MaxValue; Value = MaxValue; end
if isnan(Value); Value = MinValue; end
set(hObject,'string',num2str(Value));
%Update the plot
pushbutton_Plot_Callback(hObject, eventdata, handles);
function edit_CleavePos_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_CurPos_Callback(hObject, eventdata, handles)
Value = str2double(get(hObject,'string'));
Value = round(Value);
MinValue = 1;
MaxValue = Inf;
if Value < MinValue; Value = MinValue; end
if Value > MaxValue; Value = MaxValue; end
if isnan(Value); Value = MinValue; end
set(hObject,'string',num2str(Value));

%Adjust the StartPos if needed
StartPos = str2double(get(handles.edit_StartPos,'string'));
if Value < StartPos
    set(handles.edit_StartPos,'string',num2str(Value));
    DrawLogo(hObject,handles)
end

%Adjust the EndPos if needed
EndPos = str2double(get(handles.edit_EndPos,'string'));
if Value > EndPos
    set(handles.edit_EndPos,'string',num2str(Value));
    DrawLogo(hObject,handles)
end

%Update the plot
pushbutton_Plot_Callback(hObject, eventdata, handles);
function edit_CurPos_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton_GoLeft_Callback(hObject, eventdata, handles)
CurPos = str2double(get(handles.edit_CurPos,'string'))-1;
if CurPos < 1; CurPos = 1; end
set(handles.edit_CurPos,'string',num2str(CurPos));
pushbutton_Plot_Callback(hObject, eventdata, handles);

function pushbutton_GoRight_Callback(hObject, eventdata, handles)
CurPos = str2double(get(handles.edit_CurPos,'string'))+1; %CurPos will be set to max using PlotData Callback.
set(handles.edit_CurPos,'string',num2str(CurPos));
pushbutton_Plot_Callback(hObject, eventdata, handles);

function edit_SelectAACol_Callback(hObject, eventdata, handles)
Value = round(str2double(get(hObject,'String')));
set(hObject,'string',num2str(Value));
function edit_SelectAACol_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%==========================================================================
%Plotting Functions
%==========================================================================

function SetPlotAxis(AX,handles)
GridOn = get(handles.Radio_Grid,'value');
if GridOn == 1; 
    GridStatus = 'on';
else
    GridStatus = 'off';
end
set(AX,'XGrid',GridStatus);
set(AX,'YGrid',GridStatus);
set(AX,'GridLineStyle','-');
set(AX,'XLim',[-7 7]);
set(AX,'YLim',[0 180]);
set(AX,'XTick',[-6:2:6]);
set(AX,'YTick',[0:20:180]);
set(AX,'Xcolor',[0 0 0]);
set(AX,'Ycolor',[0 0 0]);
set(AX,'LineWidth',1.5);
set(AX,'Box','On');
set(AX,'Units','normalized');

function SetPlotTitle(AX,handles)
AxisOn = get(handles.Radio_Title,'value');
SearchText = get(handles.edit_SearchSeqName,'string');
DataNum = size(get(handles.Table_1,'Data'),1);

if AxisOn == 1;
    %Write the position location
    Renumber = get(handles.Radio_RenumberByCleave,'value');
    PosNum = str2double(get(handles.edit_CurPos,'string'));
    if Renumber == 1
        CleavageNum = str2double(get(handles.edit_CleavePos,'string'));
        PthPos = CleavageNum - PosNum + 1;
        if PthPos <= 0; %AA residue is on right side of cleavage site
            PthPos = abs(PthPos)+1;    
            AxisName = sprintf('P %0.0f''',PthPos);
        else %AA residue is on left side of cleavage site
            AxisName = sprintf('P %0.0f',PthPos);
        end   
    else
        AxisName = sprintf('P %0.0f',PosNum);        
    end
    %Append the other information, like DataNum and Search Text
    if ~isempty(SearchText)
        FullName = sprintf('%s, N = %0.0f, [%s]',AxisName, DataNum, SearchText);
    else
        FullName = sprintf('%s, N = %0.0f',AxisName, DataNum);
    end
else
    FullName = '';    
end

H = get(AX,'Title');
FontName = get(handles.edit_TitleFont,'string');
FontSize = str2double(get(handles.edit_TitleSize,'string'));
FontUnits = 'points';
set(H,'FontName',FontName);
set(H,'FontSize',FontSize);
set(H,'FontUnits',FontUnits);
set(H,'String',FullName);

function SetPlotXLabel(AX,handles)
AxisOn = get(handles.Radio_XAxis,'value');
if AxisOn == 1; 
    AxisName = 'Hydropathy Index';
else
    AxisName = '';
end
H = get(AX,'XLabel');
FontName = get(handles.edit_XAxisFont,'string');
FontSize = str2double(get(handles.edit_XAxisSize,'string'));
FontUnits = 'points';
set(H,'FontName',FontName);
set(H,'FontSize',FontSize);
set(H,'FontUnits',FontUnits);
set(H,'String',AxisName);

function SetPlotYLabel(AX,handles)
AxisOn = get(handles.Radio_YAxis,'value');
if AxisOn == 1; 
    AxisName = 'Van der Waals Volume (A^3)';
else
    AxisName = '';
end
H = get(AX,'YLabel');
FontName = get(handles.edit_YAxisFont,'string');
FontSize = str2double(get(handles.edit_YAxisSize,'string'));
FontUnits = 'points';
set(H,'FontName',FontName);
set(H,'FontSize',FontSize);
set(H,'FontUnits',FontUnits);
set(H,'String',AxisName);

function AAFreqData = GetAAFreqData(Seq)
%Make sure this is a column of sequences (no numbers, symbols)
Pattern = ['[^abcdefghijklmnopqrstuvwxyz]'];
for j = 1:size(Seq,1)
    if iscell(Seq)
        CheckText = regexp(lower(Seq{j}),Pattern);
    elseif ischar(Seq)
        CheckText = regexp(lower(Seq(j,:)),Pattern);
    end
    if isempty(CheckText) == 0;
       ErrorMsg = sprintf('ERROR: There is a non-character symbol in name in row %d',j);
       error(ErrorMsg);
       break;
    end
end
AAFreqData = seqprofile(Seq);

function DrawLogo(AX,handles)
%Getting data
SelCol = str2double(get(handles.edit_SelectAACol,'string'));
Seq = cell2mat(handles.RawData(:,SelCol));

%Making sure PosNum, StartPos, EndPos makes sense.
PosNum = str2double(get(handles.edit_CurPos,'string'));
if PosNum < 1
    PosNum = 1;
    handles.CurPos = 1;
    set(handles.edit_CurPos,'string',num2str(PosNum));
elseif PosNum > size(Seq,2)
    PosNum = size(Seq,2);
    handles.CurPos = PosNum;
    set(handles.edit_CurPos,'string',num2str(PosNum));
end

StartPos = str2double(get(handles.edit_StartPos,'string'));
if StartPos < 1
    StartPos = 1;
    set(handles.edit_StartPos,'string',num2str(StartPos));
end

EndPos = str2double(get(handles.edit_EndPos,'string'));
if EndPos > size(Seq,2);
    EndPos = size(Seq,2);
    set(handles.edit_EndPos,'string',num2str(EndPos));
end

%If the PosNum is outside bounds of the start and end, then move the start
%and end sequence to chase after PosNum!
if PosNum < StartPos
    StartPos = PosNum;
    set(handles.edit_StartPos,'string',num2str(StartPos));    
end
if PosNum > EndPos
    EndPos = PosNum;
    set(handles.edit_EndPos,'string',num2str(EndPos));
end

%Determine if there is any changes
if isfield(handles,'PastLogoRange')
    PastLogoRange = handles.PastLogoRange;
else
    PastLogoRange = [0 0];
end
CurrLogoRange = [StartPos EndPos];
if sum(PastLogoRange-CurrLogoRange)~=0
    %Making WEBLOGO
    [LogoImage, LogoMap] = drawWebLogo(Seq,StartPos:EndPos);
    handles.LogoMap = LogoMap + StartPos-1;
    handles.PastLogoRange = [StartPos EndPos];
    guidata(AX,handles)

    h = imshow(LogoImage,'Parent',handles.axes_WebLogo);
    set(h,'ButtonDownFcn',{@axes_WebLogo_ButtonDownFcn,handles});
end

function DrawCodonPlot(AX,handles)
%Getting data
RawData = get(handles.Table_1,'Data');
NTColNum = str2double(get(handles.edit_SelectNTCol,'string'));

%Getting residue position and codons
CurPos = str2double(get(handles.edit_CurPos,'string'));
CurPosNT = (CurPos-1)*3+1:CurPos*3;

%Get the codon count
SeqNT = cell(size(RawData,1),1);
DeleteThis = zeros(size(RawData,1),1) > 1;
for j = 1:length(SeqNT)
    if length(RawData{j,NTColNum}) >= CurPosNT(end)
        SeqNT{j} = RawData{j,NTColNum}(CurPosNT);
    else
        DeleteThis(j) = 1;
    end
end
SeqNT(DeleteThis) = [];
CodonSeq = cell2mat(SeqNT);
%SeqNT = cell2mat(RawData(:,NTColNum));
%CodonSeq = SeqNT(:,CurPosNT);

%Looking for the residue and corresponding codon of interest
Residue = handles.Residue;
AA = nt2aa(CodonSeq,'ACGTOnly','false');
MatchedAA = ones(size(AA))==1; %Assume all residue for now
if ~isempty(Residue)
    MatchedAA = MatchedAA<1;
    for j = 1:length(Residue)
        MatchedAA = MatchedAA | (AA == Residue(j));
    end
end
CodonSeq = CodonSeq(MatchedAA,:);

%Go through the CodonStat and get unique AA and freq.
CodonSeqL = char(zeros(1,length(CodonSeq(:))));
CodonSeqL(1:3:end) = CodonSeq(:,1);
CodonSeqL(2:3:end) = CodonSeq(:,2);
CodonSeqL(3:3:end) = CodonSeq(:,3);

CodonStat = codoncount(CodonSeqL);
BarFreq = cell2mat(struct2cell(CodonStat));
BarName = fieldnames(CodonStat);
BarName = BarName(BarFreq>0);
BarFreq = BarFreq(BarFreq>0);

%Plot the data
Bx = barh(AX,BarFreq);
set(AX,'FontSize',16);
set(AX,'YTickLabel',BarName);

%========================================
%Predict AA from point mutations
AAmutStat = zeros(20,1);
for k = 1:length(BarName)
    [AAPred, AAFreq] = predictMutation(CodonSeq(1,:));
    AAPredIdx = aa2int(AAPred);
    AAmutStat(AAPredIdx,1) = AAmutStat(AAPredIdx,1) + AAFreq * BarFreq(k) / sum(AAFreq);
end
AAloc = (AAmutStat > 0);
AAFreq = AAmutStat(AAloc);

%Get the amino acid properties
AATable = getAATable;
AATable = AATable(AAloc,:);
FullData = sortrows([cell2mat(AATable(:,3:4)) AAFreq],-3);

%Perform a sort by size so that larger scatter plots are drawn
%first, and smaller ones are drawn over them.
HPY = FullData(:,1);
VDW = FullData(:,2);
%Make sure scatterplot area is greater than 1
AAsizefactor = str2double(get(handles.edit_Area,'string'));
if AAsizefactor < 1; 
    AAsizefactor = 1; 
    set(handles.edit_Area,'string',num2str(AAsizefactor));
end
AAsize = FullData(:,3)*AAsizefactor/sum(FullData(:,3)); %Normalize size
hold(handles.axes_ScatterPlot,'on');
AXp = scatter(handles.axes_ScatterPlot,HPY,VDW,AAsize,[0 0 0]);
set(AXp,'ButtonDownFcn',{@axes_ScatterPlot_ButtonDownFcn,handles});  %Make all scatter plot dots clickable
hold(handles.axes_ScatterPlot,'off');

function PlotData(AX,handles) %This one plots the data
%Select the sequence data
SelCol = str2double(get(handles.edit_SelectAACol,'string'));

Seq = get(handles.Table_1,'Data');
Seq = cell2mat(Seq(:,SelCol));

[AATable, AAColor] = getAATable;

%Make sure scatterplot area is greater than 1
AAsizefactor = str2double(get(handles.edit_Area,'string'));
if AAsizefactor < 1; 
    AAsizefactor = 1; 
    set(handles.edit_Area,'string',num2str(AAsizefactor));
end

%Make sure PosNum does not exceed 1 or size(Seq,2)
PosNum = str2double(get(handles.edit_CurPos,'string'));
if PosNum < 1
    PosNum = 1;
    handles.CurPos = 1;
    set(handles.edit_CurPos,'string',num2str(PosNum));
elseif PosNum > size(Seq,2)
    PosNum = size(Seq,2);
    handles.CurPos = PosNum;
    set(handles.edit_CurPos,'string',num2str(PosNum));
end

%Read in the data from specified column
if isempty(Seq)
    delete(get(handles.axes_ScatterPlot,'Children'));
    delete(get(handles.axes_CodonPlot,'Children'));
    return
else
    AAFreq = cell2mat(struct2cell(aacount(Seq(:,PosNum))));
end

%Keep AA and color data for AA that is present
KeepStuff = (AAFreq > 0);
PlotData = [cell2mat(AATable(:,3:4)) AAFreq [1:20]'];
PlotData = PlotData(KeepStuff,:);
CMapData = AAColor(KeepStuff,:);

%Perform a sort by size so that larger scatter plots are drawn
%first, and smaller ones are drawn over them.
FullData = sortrows([PlotData CMapData],-3);
HPY = FullData(:,1);
VDW = FullData(:,2);
AAsize = FullData(:,3)*AAsizefactor/sum(FullData(:,3)); %Normalize size
AAlist = int2aa(FullData(:,4));
CMapData = FullData(:,5:end);

%Clear children first
delete(get(AX,'children'));

%Plot the data onto the axes
colormap(AX,CMapData);
AXc = scatter(AX,HPY,VDW,AAsize,[1:length(HPY)]','fill');
handles.AXc = AXc;
set(AXc,'ButtonDownFcn',{@axes_ScatterPlot_ButtonDownFcn,handles});  %Make all scatter plot dots clickable
set(AX,'XLim',[-7 7]);
set(AX,'YLim',[0 180]);
set(AX,'FontSize',16);

%Add labels to figure or not
RadioOn = get(handles.Radio_Legend,'value');
if RadioOn == 1
    axes(AX);
    FSlabel = str2double(get(handles.edit_LegendSize,'string'));

    %Calculate the scaling factor, in points
    currentunits = get(AX,'Units');
    set(AX, 'Units', 'points');
    axpos = get(AX,'Position');
    set(AX, 'Units', currentunits);
    XscaleFactor = abs(diff(get(AX,'xlim')))/axpos(3); %Xvalue per points
    YscaleFactor = abs(diff(get(AX,'ylim')))/axpos(4); %Yvalue per points

    %Label the dot residue name
    for j = 1:length(AAlist)
        AreaSize = AAsize(j);
        Radius = sqrt(AreaSize/pi);               

        %Determine where to add label
        %N
        if sum(AAlist(j) == 'TPFL') > 0
            Deg = 0;
            Align = 'center';
            VAlign = 'bottom';
            Xshift = (Radius)*XscaleFactor*sind(Deg); 
            Yshift = (Radius)*YscaleFactor*cosd(Deg)*0.99; 
        %NE
        elseif sum(AAlist(j) == 'HR') > 0
            Deg = 45;
            Align = 'left';
            VAlign = 'bottom';
            Xshift = (Radius)*XscaleFactor*sind(Deg)*1.01; 
            Yshift = (Radius)*YscaleFactor*cosd(Deg)*0.99; 
        %E
        elseif sum(AAlist(j) == 'WYIVCEK') > 0
            Deg = 90;
            Align = 'left';
            VAlign = 'middle';
            Xshift = (Radius)*XscaleFactor*sind(Deg); 
            Yshift = (Radius)*YscaleFactor*cosd(Deg); 
        %SE 
        elseif sum(AAlist(j) == 'A') > 0
            Deg = 135;
            Align = 'left';
            VAlign = 'top';
            Xshift = (Radius)*XscaleFactor*sind(Deg)*0.99; 
            Yshift = (Radius)*YscaleFactor*cosd(Deg)*1.01; 
        %S
        elseif sum(AAlist(j) == 'GD') > 0
            Deg = 180;
            Align = 'center';
            VAlign = 'top';
            Xshift = (Radius)*XscaleFactor*sind(Deg); 
            Yshift = (Radius)*YscaleFactor*cosd(Deg)*1.01; 
        %SW
        elseif sum(AAlist(j) == '') > 0
            Deg = 225;
            Align = 'right';
            VAlign = 'top';
            Xshift = (Radius)*XscaleFactor*sind(Deg)*1.01; 
            Yshift = (Radius)*YscaleFactor*cosd(Deg)*1.01; 
        %W
        elseif sum(AAlist(j) == 'QNSM') > 0
            Deg = 270;
            Align = 'right';
            VAlign = 'middle';
            Xshift = (Radius)*XscaleFactor*sind(Deg); 
            Yshift = (Radius)*YscaleFactor*cosd(Deg); 
        %NW
        else
            Deg = 315;
            Align = 'right';
            VAlign = 'bottom';
            Xshift = (Radius)*XscaleFactor*sind(Deg)*1.01; 
            Yshift = (Radius)*YscaleFactor*cosd(Deg)*0.99; 
        end                
        ht = text(HPY(j)+Xshift,VDW(j)+Yshift,AAlist(j));
        set(ht,'HorizontalAlignment',Align,'VerticalAlignment',VAlign,'FontSize',FSlabel,'Color',CMapData(j,:));
    end
end

guidata(AX,handles);
    
function pushbutton_Plot_Callback(hObject, eventdata, handles)
%Refresh Plot
DrawLogo(handles.axes_WebLogo,handles);
PlotData(handles.axes_ScatterPlot,handles);
SetPlotAxis(handles.axes_ScatterPlot,handles);
SetPlotYLabel(handles.axes_ScatterPlot,handles);
SetPlotXLabel(handles.axes_ScatterPlot,handles);
SetPlotTitle(handles.axes_ScatterPlot,handles);

%Make sure to reset the codon plot;
AXcodonchild = get(handles.axes_CodonPlot,'Children');
delete(AXcodonchild);
set(handles.axes_CodonPlot,'YTickLabel','');

function axes_WebLogo_ButtonDownFcn(hObject, eventdata, handles)
LogoMap = handles.LogoMap;

ClickPos = get(handles.axes_WebLogo,'CurrentPoint');
Xloc = round(ClickPos(1,1));
Yloc = round(ClickPos(1,2));
PosNum = LogoMap(Yloc,Xloc);

%Setting new positions
set(handles.edit_CurPos,'string',num2str(PosNum));
pushbutton_Plot_Callback(hObject, eventdata, handles)

function axes_ScatterPlot_ButtonDownFcn(hObject, eventdata, handles)
ClickPos = get(handles.axes_ScatterPlot,'CurrentPoint');
Xloc = ClickPos(1,1); %Gives position in the X units, HPI .
Yloc = ClickPos(1,2); %Gives position in the Y units, VDWV. But Dot area is in pt^2.

%Determine which scatter plot dot is closest to click
AXc = handles.AXc;
Xpt = get(AXc,'XData')';
Ypt = get(AXc,'YData')';
Distance = sqrt((Xloc-Xpt).^2+(Yloc-Ypt).^2);
PotentialDots = [Xpt Ypt Distance];
PotentialDots = sortrows(PotentialDots,3);

if ~isempty(PotentialDots)
    AA_HPI = PotentialDots(1,1);
    AA_VDWV = PotentialDots(1,2);

    %Determining AA based on HPY and VDW reverse lookup
    AAlookup = lookupAATable(AA_HPI,AA_VDWV);
    handles.Residue = AAlookup;
    guidata(hObject,handles);

    if str2double(get(handles.edit_SelectNTCol,'String')) > 0
        DrawCodonPlot(handles.axes_CodonPlot,handles);
    end
end

function edit_SelectNTCol_Callback(hObject, eventdata, handles)
function edit_SelectNTCol_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_FirstRowHeader_Callback(hObject, eventdata, handles)
Status = get(hObject,'Value');
if Status == 1 %Takes the 1st row of raw data, and uses it header
    handles.Header = handles.RawData(1,:);
    handles.RawData = handles.RawData(2:end,:);
    set(handles.Table_1,'ColumnName',handles.Header);
    set(handles.Table_1,'Data',handles.RawData);
else
    handles.RawData = [handles.Header; handles.RawData];
    GeneralHeader = num2cell([1:size(handles.RawData,2)]);
    set(handles.Table_1,'ColumnName',GeneralHeader);
    set(handles.Table_1,'Data',handles.RawData);
end
set(handles.text_NumOfSeq,'String',num2str(size(handles.RawData,1)));
guidata(hObject,handles);

function edit_SaveNamePrefix_Callback(hObject, eventdata, handles)
function edit_SaveNamePrefix_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_SelectNameCol_Callback(hObject, eventdata, handles)
function edit_SelectNameCol_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pushbutton_AlignmentTool_Callback(hObject, eventdata, handles)
RawData = handles.RawData;
NTcol = str2double(get(handles.edit_SelectNTCol,'String'));
AAcol = str2double(get(handles.edit_SelectAACol,'String'));
[AlignNT, AlignAA] = SeqAlignTool(RawData(:,NTcol),RawData(:,AAcol));
if isempty(AlignNT{1}) %Nothing was done
    return
end

%Need to adjust everything now
CurData = handles.RawData;
CurData(:,NTcol) = AlignNT;
CurData(:,AAcol) = AlignAA;
set(handles.Table_1,'Data',CurData);
handles.RawData = CurData;
guidata(hObject,handles);

function pushbutton_ShowLegend_Callback(hObject, eventdata, handles)
drawColorLegend(10);

function edit_ReadingFrame_Callback(hObject, eventdata, handles)
Value = round(str2double(get(hObject,'String')));
if isnan(Value)
    Value = 1;
end
if Value < 1 
    Value = 1;
elseif Value > 3
    Value = 3;
end
set(hObject,'String',num2str(Value));

%Now retranslate the AA
NTcol = str2double(get(handles.edit_SelectNTCol,'String'));
AAcol = str2double(get(handles.edit_SelectAACol,'String'));
if NTcol > 0
    %Translate both the raw data and current data in the table
    handles.RawData(:,AAcol) = nt2aa(handles.RawData(:,NTcol),'acgtonly','false','frame',Value);    
    CurData = get(handles.Table_1,'Data');
    CurData(:,AAcol) = nt2aa(CurData(:,NTcol),'acgtonly','false','frame',Value);
    set(handles.Table_1,'Data',CurData)

    %Remaking WEBLOGO
    StartPos = str2double(get(handles.edit_StartPos,'string'));
    EndPos = str2double(get(handles.edit_EndPos,'string'));
    [LogoImage, LogoMap] = drawWebLogo(Seq,StartPos:EndPos);
    handles.LogoMap = LogoMap + StartPos-1;
    handles.PastLogoRange = [StartPos EndPos];

    h = imshow(LogoImage,'Parent',handles.axes_WebLogo);
    set(h,'ButtonDownFcn',{@axes_WebLogo_ButtonDownFcn,handles});
    guidata(hObject, handles);
end
function edit_ReadingFrame_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton_Clear_Callback(hObject, eventdata, handles)
AAScatterPlot_OpeningFcn(hObject, eventdata, handles);

function edit_SearchSeqName_Callback(hObject, eventdata, handles)
searchData(hObject, eventdata, handles)
% %If it is empty, restore rawdata
% SearchText = get(handles.edit_SearchSeqName,'string');
% RawData = handles.RawData;
% if isempty(SearchText)
%     set(handles.Table_1,'Data',RawData);
% else
%     %Filter stuff
%     HeaderLoc = str2double(get(handles.edit_SelectNameCol,'string'));
%     HeaderData = RawData(:,HeaderLoc);
%     KeepThis = zeros(size(HeaderData,1),1) > 0;
%     SearchExp = strrep(SearchText,',','|');
%     for j = 1:length(KeepThis)
%         if ~isempty(regexp(HeaderData{j},SearchExp,'once'))
%             KeepThis(j) = 1;
%         end
%     end
%     set(handles.Table_1,'Data',RawData(KeepThis,:));
% end
pushbutton_Plot_Callback(hObject, eventdata, handles);
function edit_SearchSeqName_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_SearchNT_Callback(hObject, eventdata, handles)
searchData(hObject, eventdata, handles)
function edit_SearchNT_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_SearchAA_Callback(hObject, eventdata, handles)
searchData(hObject, eventdata, handles)
function edit_SearchAA_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%This function will do the full search and return just sequences that match
function searchData(hObject, eventdata, handles)
RawData = handles.RawData;
GetIdx = zeros(size(RawData,1),3);

SeqNameLoc = str2double(get(handles.edit_SelectNameCol,'string'));
NTLoc = str2double(get(handles.edit_SelectNTCol,'string'));
AALoc = str2double(get(handles.edit_SelectAACol,'string'));

%If it is empty, restore rawdata
SearchSeqName = get(handles.edit_SearchSeqName,'string');
SearchNT = get(handles.edit_SearchNT,'string');
SearchAA = get(handles.edit_SearchAA,'string');

if isempty(SearchSeqName) && isempty(SearchNT) && isempty(SearchAA)
    set(handles.Table_1,'Data',RawData);
else
    MinMatch = 0;
    if ~isempty(SearchSeqName)
        SearchExp = strrep(SearchSeqName,',','|');
        for j = 1:size(RawData,1)
            if ~isempty(regexpi(RawData{j,SeqNameLoc},SearchExp,'once'))
                GetIdx(j,1) = 1;
            end
        end
        MinMatch = MinMatch+1;
    end
    if ~isempty(SearchNT)
        SearchExp = strrep(SearchNT,',','|');
        for j = 1:size(RawData,1)
            if ~isempty(regexpi(RawData{j,NTLoc},SearchExp,'once'))
                GetIdx(j,2) = 1;
            end
        end
        MinMatch = MinMatch+1;
    end
    if ~isempty(SearchAA)
        SearchExp = strrep(SearchAA,',','|');
        for j = 1:size(RawData,1)
            if ~isempty(regexpi(RawData{j,AALoc},SearchExp,'once'))
                GetIdx(j,3) = 1;
            end
        end
        MinMatch = MinMatch+1;
    end
    
    %Save into the table only those that are selected
    KeepThis = sum(GetIdx,2) >= MinMatch;    
    set(handles.Table_1,'Data',RawData(KeepThis,:));
end
%Redraw the plots
pushbutton_Plot_Callback(hObject, eventdata, handles);


function pushbutton_SaveTable_Callback(hObject, eventdata, handles)
TableData = get(handles.Table_1,'Data');
[FileName, FilePath] = uiputfile('*.csv','Save table as');
writeDlmFile(TableData,[FilePath FileName],',');
