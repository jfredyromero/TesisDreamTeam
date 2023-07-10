% Importación de funciones
addpath('../Grabaciones/');
addpath('../Mediciones/');
addpath('../Src/Lifting/Adaptativo/Functions/');
addpath('../Utilidades/');

% Limpieza de variables
clear;
close all;
clc;

% Cargar datos de los audios previamente almacenados
load("audioCell.mat");

% Establezco el numero de niveles de descomposición
n = 10;

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
audioResults = zeros(log2(q(end)) + 1, length(q));

waveletResults = zeros(log2(q(end)) + 1, length(q), length(lsc));

for f = 1:length(lsc) % Wavelets madre
    disp("===============================================");
    disp("Inicio de pruebas de Wavelet " + fw{f});
    for i = 1:length(audioCell) % Audios
        tic;
        for j = 1:length(q) % Niveles de cuantificación
            for cama = 0:log2(q(j)) % Valor de la cama inicial
                [~, quality] = quantByPerception(audioCell{i, 2}, n, q(j), td, cama, lsc{f});
                audioResults(cama + 1, j, i) = quality;
            end                        
        end
        disp("===============================================");
        disp("Wavelet " + fw{f} + ": Audio #" + i + " finalizado. Time elapsed: " + toc);
        disp("===============================================");
    end
    waveletResults(:, :, f) = mean(audioResults, 3);
    disp("Final de pruebas de Wavelet " + fw{f} + ".");
    disp("===============================================")
end

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
save("../Resultados/Lifting/Comprobaciones/Mejor Cama/Percepcion.mat", "resultados");

% Grafica los resultados
title('Performance Algoritmo Percepción');
hold on;
markers = ['-+'; '-*'; '-x'; '-^'; '-o'; '-s'];
for i = 1:length(q)
    plot(1:log2(q(end)) + 1, totalResults(:, i), markers(i, :), 'linewidth', 2, 'DisplayName', columnsNames{i});
end
xlabel('Calidad') 
ylabel('Cama') 
legend;
hold off;
