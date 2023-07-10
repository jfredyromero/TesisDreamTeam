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

% Establezco el numero de niveles de descomposición
n = 9;

% Establezco el numero de niveles de cuantificación
q = [4 8 16 32 64];

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
audioResults = zeros(log2(q(end)) + 1, length(q), length(audioCell));

for f = 1:length(lsc) % Wavelets madre
    disp("===============================================");
    disp("Inicio de pruebas de Wavelet " + fw{f});
    for i = 1:length(audioCell) % Audios
        tic;
        for j = 1:length(q) % Niveles de cuantificación
            for cama = 0:log2(q(j)) % Valor de la cama inicial
                try
                    % [~, quality] = quantByPerception(audioCell{i, 2}, n, q(j), td, cama, lsc{f});
                    [~, quality] = quantByEnergy(audioCell{i, 2}, n, q(j), td, cama, lsc{f});
                    % [~, quality] = quantByHeuristic(audioCell{i, 2}, n, q(j), td, cama, lsc{f});
                    audioResults(cama + 1, j, i) = quality;
                catch
                    warning('Problem using function.  Assigning a value of NaN');
                    audioResults(cama + 1, j, i) = NaN;
                end
            end                        
        end
        disp("===============================================");
        disp("Wavelet " + fw{f} + ": Audio #" + i + " finalizado. Time elapsed: " + toc);
        disp("===============================================");
    end
    resultados = mean(audioResults, 3, 'omitnan');
    % save("../Resultados/Lifting/Comprobaciones/Mejor Cama/Percepcion/" + "wavelet-" + fw{f} + "-results.mat", "resultados");
    % save("../Resultados/Lifting/Comprobaciones/Mejor Cama/Energia/" + "wavelet-" + fw{f} + "-results.mat", "resultados");
    save("../Resultados/Lifting/Comprobaciones/Mejor Cama/Heuristico/" + "wavelet-" + fw{f} + "-results.mat", "resultados");
    disp("Final de pruebas de Wavelet " + fw{f} + ".");
    disp("===============================================")
end

% Carga los archivos de resultados
% archivos = dir('../Resultados/Lifting/Comprobaciones/Mejor Cama/Percepcion/*.mat');
% archivos = dir('../Resultados/Lifting/Comprobaciones/Mejor Cama/Energia/*.mat');
archivos = dir('../Resultados/Lifting/Comprobaciones/Mejor Cama/Heuristico/*.mat');

waveletResults = zeros(log2(q(end)) + 1, length(q), length(lsc));

for i = 1:numel(archivos)
    % Nombre del archivo actual
    archivo = archivos(i).name;

    % Carga los datos del archivo .mat
    datos = load(fullfile(archivo)); 
    
    % Guarda los datos en una dimension del siguiente vector
    waveletResults(:, :, i) = datos.resultados;
end

% Promedia los resultados y cambia los ceros por NaN
totalResults = mean(waveletResults, 3);
totalResults(totalResults == 0) = NaN;

columnsNames = cell(1, length(q));
for i = 1:length(q)
    columnsNames{i} = "q = " + q(i);
end

rowsNames = cell(log2(q(end)), 1);
for i = 0:log2(q(end))
    rowsNames{i + 1} = "cama = " + i;
end

% Guarda resultados en un archivo .mat
resultados = array2table(totalResults,  'VariableNames', string(columnsNames), 'RowNames', string(rowsNames));
% save("../Resultados/Lifting/Comprobaciones/Mejor Cama/Percepcion.mat", "resultados");
% save("../Resultados/Lifting/Comprobaciones/Mejor Cama/Energia.mat", "resultados");
save("../Resultados/Lifting/Comprobaciones/Mejor Cama/Heuristico.mat", "resultados");

% Grafica los resultados
% title('Performance Algoritmo Percepción');
% title('Performance Algoritmo Energía');
title('Performance Algoritmo Heuristico');
hold on;
markers = ['-+'; '-*'; '-x'; '-^'; '-o'; '-s'];
for i = 1:length(q)
    plot(0:log2(q(end)), totalResults(:, i), markers(i, :), 'linewidth', 2, 'DisplayName', columnsNames{i});
end
xlabel('Cama');
ylabel('Calidad');
legend;
hold off;
