%makeLogoFont generates the letter images needed for creating weblogos.
%This just needs to be run once. To change font colors, need modify
%getAATable.m
function makeLogoFont

[AAprop AAclr] = GetAATable();
AAletter = cell2mat(AAprop(:,2));

%Make sure to add the Font paths
Mpath = mfilename('fullpath');
SlashLoc = regexpi(Mpath,'\\|\/');
SlashType = Mpath(SlashLoc(1));
Mpath = Mpath(1:SlashLoc(end));
SavePath = [Mpath 'Font' SlashType];

%Generate fig
gx1 = figure();
set(gx1,'position',[100 100 350 300]);
set(gx1,'units','points');
gx1pos = get(gx1,'position');
set(gx1, 'PaperUnits', 'points','PaperPosition', gx1pos);

ax1 = axes();
set(ax1,'units','normalized');
set(ax1,'position',[0 0 1 1]);
set(ax1,'XTickLabel','');
set(ax1,'YTickLabel','');
set(ax1,'XTick',[]);
set(ax1,'YTick',[]);
set(ax1,'XColor',[1 1 1]);
set(ax1,'YColor',[1 1 1]);
set(ax1,'XLim',[0 1]);
set(ax1,'YLim',[0 1]);

for j = 1:length(AAletter)
    tx1 = text(0.5,0.49,AAletter(j),'FontSize',300,'Color',AAclr(j,:),'HorizontalAlignment','Center');
    saveas(gcf,[SavePath AAletter(j) '.jpg'],'jpg');    
    delete(tx1)
end