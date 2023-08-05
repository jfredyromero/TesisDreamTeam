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
title('Calidad Según la Distribución de Bits CRR E')
xlabel('Bits de reserva')
ylabel('Bits disponibles')

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
title('Calidad Según la Distribución de Bits CRR P')
xlabel('Bits de reserva')
ylabel('Bits disponibles')

%%  resultados heurístico
rh = load("Percepcion.mat");
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
title('Calidad Según la Distribución de Bits CRR H')
xlabel('Bits de reserva')
ylabel('Bits disponibles')