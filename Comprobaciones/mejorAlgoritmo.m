% Importación de funciones
addpath('../Grabaciones/');
addpath('../Mediciones/');
addpath('../Src/Tiempo/Tradicional/Functions/');
addpath('../Utilidades/');

% Limpieza de variables
clear;
close all;
clc;

% Cargar datos de los audios previamente almacenados
load("audioCell.mat");

% Tipos de algoritmo
mallat = "Mallat";
lifting = "Lifting";
tiempo = "Tiempo";

% Establezco el algoritmo
algoritmo = tiempo;

% Añado el path del algoritmo
if algoritmo ~= tiempo
    addpath('../Src/' + algoritmo + '/Adaptativo/Functions/');
end

% Establezco el numero de niveles de descomposición
n = 2;

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
    switch algoritmo
        case mallat
            [ha, ga, hs, gs] = wfilters(fw{i});
            lsc{i} = [ha; ga; hs; gs];
        case lifting
            lsc{i} = liftingScheme('Wavelet', fw{i});
        case tiempo
            continue;
        otherwise
            error("ERROR: No valid option");
    end
    
end

% Matriz de resultados de las pruebas
audioResults = zeros(length(audioCell), length(q));

for f = 1:length(lsc) % Wavelets madre
    disp("===============================================");
    disp("Inicio de pruebas de Wavelet " + fw{f});
    for i = 1:length(audioCell) % Audios
        tic;
        for j = 1:length(q) % Niveles de cuantificación
            try
                switch algoritmo
                    case mallat
                        [~, quality] = quantByPerception(audioCell{i, 2}, n, q(j), td, cama(j), lsc{f}(1, :), lsc{f}(2, :), lsc{f}(3, :), lsc{f}(4, :));
                    case lifting
                        [~, quality] = quantByPerception(audioCell{i, 2}, n, q(j), td, cama(j), lsc{f});
                    case tiempo
                        [~, quality] = quantByTime(audioCell{i, 2}, q(j), td);
                    otherwise
                        error("ERROR: No valid option");
                end
                audioResults(i, j) = quality;
            catch
                warning('Problem using function.  Assigning a value of NaN');
                audioResults(i, j) = NaN;
            end
        end
        disp("===============================================");
        disp("Wavelet " + fw{f} + ": Audio #" + i + " finalizado. Time elapsed: " + toc);
        disp("===============================================");
    end
    resultados = mean(audioResults, 'omitnan');
    save("../Resultados/Comparacion/Mejor Algoritmo/" + algoritmo + "/wavelet-" + fw{f} + "-results.mat", "resultados");
    disp("Final de pruebas de Wavelet " + fw{f} + ".");
    disp("===============================================")
end

algoritmos = [mallat, lifting, tiempo];
totalResults = zeros(6, length(q), length(algoritmos));

for algo = 1:length(algoritmos)
    % Carga los archivos de resultados
    archivos = dir('../Resultados/Comparacion/Mejor Algoritmo/' + algoritmos(algo) + '/*.mat');
    
    waveletResults = zeros(length(lsc), length(q));
    
    for i = 1:numel(archivos)
        % Nombre del archivo actual
        archivo = archivos(i).name;
    
        % Nombre del parent folder
        folder = archivos(i).folder;
    
        % Carga los datos del archivo .mat
        datos = load(fullfile(folder, archivo)); 
        
        % Guarda los datos en una dimension del siguiente vector
        waveletResults(i, :) = datos.resultados;
    end
    
    % Almacena todos los resultados en una sola matriz para analizar su
    %       varianza y desviacion estandar
    totalResults(:, :, algo) = waveletResults;
end

columnsNames = cell(1, length(q));
for i = 1:length(q)
    columnsNames{i} = "M = " + q(i);
end

rowsNames = cell(1, numel(archivos));
for i = 1:numel(archivos)
    rowsNames{i} = archivos(i).name;
end

% Resultados en un archivo .mat
resultados = cell(1, length(algoritmos));

% Grafica los resultados
title('Comparación entre Algoritmos');
grid on;
grid minor;
set(gca, 'XScale', 'log');
set(gca,'xtick', q);
hold on;
for i = 1:length(algoritmos)
    errorbar(q, mean(totalResults(:, :, i)), mean(totalResults(:, :, i)) - min(totalResults(:, :, i)), max(totalResults(:, :, i)) - mean(totalResults(:, :, i)), 'LineWidth', 2.5, 'DisplayName', rowsNames{i});
    resultados{i} = array2table(totalResults(:, :, i),  'VariableNames', string(columnsNames), 'RowNames', string(rowsNames));
end
ax = gca;
ax.FontSize = 14;
xlabel('Nivel de Cuantificación');
ylabel('Calidad');
legend(algoritmos);
hold off;

% Guarda resultados en un archivo .mat
save("../Resultados/Comparacion/Mejor Algoritmo/MejorAlgoritmo.mat", "resultados");

