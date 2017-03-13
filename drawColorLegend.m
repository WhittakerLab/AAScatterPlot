%drawColorLegend will draw the scatter plot tool's color code legend on to
%a blank plotting area of size 270 x 270 pixels.
%
%  drawColorLegend
%
%  drawColorLegend(FigNum)
%
%  Gx = drawColorLegend(FigNum)
%
%  [Gx, Ax] = drawColorLegend(FigNum)
%
%  INPUT
%    FigNum: the figure number to assign for the drawn color legend
%
%  OUTPUT
%    Gx: figure handle
%    Ax: axes handle

function varargout = drawColorLegend(varargin)
FigNum = 0;
if ~isempty(varargin)
    FigNum = varargin{1};
end

%Get the color code
[AAprop, AAclr] = getAATable;
[AAprop, SortIdx] = sortrows(AAprop,5); %Sort by property
AAclr = AAclr(SortIdx,:);
[~,UnqPropIdx,~] = unique(cell2mat(AAprop(:,5)));
UnqAAclr = AAclr(UnqPropIdx,:);

%Get the text
TextLabel{1,1} = 'Polar Posistive';
TextLabel{2,1} = 'Polar Negative';
TextLabel{3,1} = 'Polar Neutral';
TextLabel{4,1} = 'NonPolar Aliphatic';
TextLabel{5,1} = 'NonPolar Aromatic';
TextLabel{6,1} = 'Unique';
TextLabel{7,1} = 'Cysteine Bond';

%Setup the figure
if FigNum <= 0
    Gx = figure;
else
    Gx = figure(FigNum);
end
Ax = axes;
set(Ax,'box','on','XTickLabel','','YTIckLabel','','YTick',[],'XTick',[]);
set(Gx,'units','pixel');
set(Gx,'Position',[400,200,300,300]);
set(Ax,'units','pixel');
set(Ax,'Position',[15 15 270 270]);
set(Ax,'Xlim',[0 270],'Ylim',[0 270]);

%Add the text
Xpos = 20;
Yincr = 270/length(TextLabel);
for j = 1:length(TextLabel)
    Ypos = Yincr * (j-1)+5;
    text(Xpos,Ypos,TextLabel{j},'FontName','Arial','FontSize',20,'FontWeight','bold','Color',UnqAAclr(j,:),'VerticalAlignment','bottom','HorizontalAlignment','Left')
end

if nargout >= 1
    varargout{1} = Gx;
    if nargout >= 2
        varargout{2} = Ax;
    end
end