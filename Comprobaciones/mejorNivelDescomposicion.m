% Importación de funciones
addpath('../Grabaciones/');
addpath('../Mediciones/');
addpath('../Src/Lifting/Adaptativo/Functions/');
addpath('../Resultados/Lifting/Comprobaciones/Mejor Cama/Energia/');
addpath('../Resultados/Lifting/Comprobaciones/Mejor Cama/Heuristico/');
addpath('../Resultados/Lifting/Comprobaciones/Mejor Cama/Percepcion/');
addpath('../Utilidades/');

% Limpieza de variables
clear;
close all;
clc;

% Cargar datos de los audios previamente almacenados
load("audioCell.mat");

% Tipo de algoritmo
energia = "Energia";
percepcion = "Percepcion";
heuristico = "Heuristico";

% Establezco el algoritmo por correr
algoritmo = heuristico;

% Establezco el numero de niveles de descomposición
n = 9;

% Establezco el numero de niveles de cuantificación
q = [4 8 16 32 64];

% Establezco la cama óptima
cama = log2(q) - 1;

% Establezco la duración de cada trama en segundos
td = 0.064;

% Familias Wavelet por analizar
fw = {'db1', 'db7', 'sym6', 'bior5.5', 'bior6.8', 'rbio4.4'};

% Creación de los filtros para cada familia Wavelet
lsc = cell(1, length(fw));
for i = 1:length(fw) 
    lsc{i} = liftingScheme('Wavelet', fw{i});
end

% Matriz de resultados de las pruebas
audioResults = zeros(n, length(q), length(audioCell));

for f = 1:length(lsc) % Wavelets madre
    disp("===============================================");
    disp("Inicio de pruebas de Wavelet " + fw{f});
    for i = 1:length(audioCell) % Audios
        tic;
        for j = 1:length(q) % Niveles de cuantificación
            for k = 1:n % Niveles de descomposición
                try
                    switch algoritmo
                        case energia
                            [~, quality] = quantByEnergy(audioCell{i, 2}, k, q(j), td, cama(j), lsc{f});
                        case percepcion
                            [~, quality] = quantByPerception(audioCell{i, 2}, k, q(j), td, cama(j), lsc{f});
                        case heuristico
                            [~, quality] = quantByHeuristic(audioCell{i, 2}, k, q(j), td, cama(j), lsc{f});
                        otherwise
                            error("ERROR: No valid option");
                    end
                    audioResults(k, j, i) = quality;
                catch
                    warning('Problem using function.  Assigning a value of NaN');
                    audioResults(k, j, i) = NaN;
                end
            end                        
        end
        disp("===============================================");
        disp("Wavelet " + fw{f} + ": Audio #" + i + " finalizado. Time elapsed: " + toc);
        disp("===============================================");
    end
    resultados = mean(audioResults, 3, 'omitnan');
    save("../Resultados/Lifting/Comprobaciones/Mejor Nivel Descomposicion/" + algoritmo + "/wavelet-" + fw{f} + "-results.mat", "resultados");
    disp("Final de pruebas de Wavelet " + fw{f} + ".");
    disp("===============================================")
end

% Carga los archivos de resultados
archivos = dir('../Resultados/Lifting/Comprobaciones/Mejor Nivel Descomposicion/' + algoritmo + '/*.mat');

waveletResults = zeros(n, length(q), length(lsc));

for i = 1:numel(archivos)
    % Nombre del archivo actual
    archivo = archivos(i).name;

    % Nombre del parent folder
    folder = archivos(i).folder;

    % Carga los datos del archivo .mat
    datos = load(fullfile(folder, archivo)); 
    
    % Guarda los datos en una dimension del siguiente vector
    waveletResults(:, :, i) = datos.resultados;
end

% Promedia los resultados y cambia los ceros por NaN
totalResults = mean(waveletResults, 3);
totalResults(totalResults == 0) = NaN;

columnsNames = cell(1, length(q));
for i = 1:length(q)
    columnsNames{i} = "M = " + q(i);
end

rowsNames = cell(log2(q(end)), 1);
for i = 1:n
    rowsNames{i} = "n = " + i;
end

% Guarda resultados en un archivo .mat
resultados = array2table(totalResults,  'VariableNames', string(columnsNames), 'RowNames', string(rowsNames));
save("../Resultados/Lifting/Comprobaciones/Mejor Nivel Descomposicion/" + algoritmo + ".mat", "resultados");

% Grafica los resultados
tiledlayout(1, 2);

nexttile;
title('Calidad Según el Nivel de Resolución CRR ' + algoritmo);
grid minor;
hold on;
for i = 1:length(q)
    plot(1:n, totalResults(:, i), 'linewidth', 3, 'DisplayName', columnsNames{i});
end
ax = gca;
ax.FontSize = 18;
xlabel('Nivel de Resolución');
ylabel('Calidad Absoluta');
legend;
hold off;

nexttile;
finalTable = zeros(5, 3);
M = max(totalResults); %valores máximos de cada fila
finalTable(:, 1) = M;
M = repelem(M, 9); 
M = reshape(M, 9, 5);
m = min(totalResults); %valores mínimos de cada fila
finalTable(:, 2) = m;
m = repelem(m, 9); 
m = reshape(m, 9, 5);
finalTable(:, 3) = std(totalResults);
rpn = (totalResults - m) ./ (M - m); %resultados normalizados por cada fila
plot(rpn, 'LineWidth', 3);
legend(columnsNames);
title('Calidad Según el Nivel de Resolución CRR ' + algoritmo);
grid minor;
ax = gca;
ax.FontSize = 18;
xlabel('Nivel de Resolución');
ylabel('Calidad Relativa');
set(gcf,'color','w');
