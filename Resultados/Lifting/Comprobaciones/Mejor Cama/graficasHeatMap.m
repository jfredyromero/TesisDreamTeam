% resultados energía
re = load("Energia.mat");
re = re.resultados;
re = table2array(re); %se deja la tabla como una matriz
re = re'; 
% heatmap 
figure,
h = heatmap(re,'MissingDataColor','[1 1 1]','ColorScaling','log');
colormap(parula(10)) 
set(gcf,'color','w');
h.XDisplayLabels = {'0','1','2','3','4','5','6'};
h.YDisplayLabels = {'2','3','4','5','6'};
h.FontSize = 14;
title('Calidad Según la Distribución de Bits CRR Energía');
xlabel('Bits de Reserva')
ylabel('Bits Disponibles por Muestra')

%%  resultados percepción
rp = load("Percepcion.mat");
rp = rp.resultados;
rp = table2array(rp); %se deja la tabla como una matriz
rp = rp'; 
% heatmap 
figure,
h = heatmap(rp,'MissingDataColor','[1 1 1]','ColorScaling','log');
colormap(parula(10)) 
set(gcf,'color','w');
h.XDisplayLabels = {'0','1','2','3','4','5','6'};
h.YDisplayLabels = {'2','3','4','5','6'};
h.FontSize = 14;
title('Calidad Según la Distribución de Bits CRR Percepción')
xlabel('Bits de Reserva')
ylabel('Bits Disponibles por Muestra')

%%  resultados heurístico
rh = load("Heuristico.mat");
rh = rh.resultados;
rh = table2array(rh); %se deja la tabla como una matriz
rh = rh'; 
% heatmap 
figure,
h = heatmap(rh,'MissingDataColor','[1 1 1]','ColorScaling','log');
colormap(parula(10)) 
set(gcf,'color','w');
h.XDisplayLabels = {'0','1','2','3','4','5','6'};
h.YDisplayLabels = {'2','3','4','5','6'};
h.FontSize = 14;
title('Calidad Según la Distribución de Bits CRR Heurístico')
xlabel('Bits de Reserva')
ylabel('Bits Disponibles por Muestra')