clear all;
close all;

load('output.dat');

t = output(:,1);
freq = output(:,2); 
amp = output(:,3);
dur = output(:,4);
inst = output(:,5);

scrsz = get(0,'ScreenSize'); %for fullscreen
figure1 = figure('Position',[1 scrsz(4) scrsz(3) scrsz(4)]);

axes1 = axes('Parent',figure1);
box(axes1,'on');
hold(axes1,'all');
grid(axes1,'off');
axes2 = axes('Parent',figure1,'YTick',[0 1 2 3 4],'YAxisLocation','right',...
        'YColor',[1 0.2 0],'Color','none');
hold(axes2,'all');

xlabel('Time (seconds)');
ylabel(axes2,'Instrument Number','VerticalAlignment','cap','Color',[1 0.2 0]);

title('Output');

plot(t,freq,'Parent',axes1,'Marker','square','MarkerSize',10,'LineWidth',2,'LineStyle',':',...
     'Color',[0.0431372560560703 0.517647087574005 0.780392169952393]);
plot(t,amp,'Parent',axes1,'Marker','square','MarkerSize',10,'LineWidth',2,'LineStyle',':',...
    'Color',[0.87058824300766 0.490196079015732 0]);
plot(t,dur,'Parent',axes1,'Marker','^','MarkerSize',10,'LineWidth',2,'LineStyle',':',...
    'Color',[0.5 0.5 0]);

plot(t,inst,'Parent',axes2,'Color',[1 0.2 0],'Marker','o','MarkerSize',10,'MarkerFaceColor',[1 0.2 0]);


legend(axes1,'Pitch (scaled)','Amplitude (scaled)','Duration (scaled)');
legend(axes2,'Instrument','Location','SouthEast');

