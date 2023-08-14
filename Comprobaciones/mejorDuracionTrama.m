% Importación de funciones
addpath('../Grabaciones/');
addpath('../Mediciones/');
addpath('../Src/Mallat/');
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
td = [0.008, 0.016, 0.032, 0.064];

% Familias Wavelet por analizar
fw = {'db1', 'db7', 'sym6', 'bior5.5', 'bior6.8', 'rbio4.4'};
fw = {'bior5.5'};

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
audioResults = zeros(length(td), length(q), length(audioCell));

for f = 1:length(lsc) % Wavelets madre
    disp("===============================================");
    disp("Inicio de pruebas de Wavelet " + fw{f});
    for i = 1:length(audioCell) % Audios
        tic;
        for j = 1:length(q) % Niveles de cuantificación
            for k = 1:length(td)
                try
                    switch algoritmo
                        case mallat
                            [~, quality] = quantByPerception(audioCell{i, 2}, n, q(j), td(k), cama(j), lsc{f}(1, :), lsc{f}(2, :), lsc{f}(3, :), lsc{f}(4, :));
                        case lifting
                            [~, quality] = quantByPerception(audioCell{i, 2}, n, q(j), td(k), cama(j), lsc{f});
                        case tiempo
                            [~, quality] = quantByTime(audioCell{i, 2}, q(j), td(k));
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
    save("../Resultados/Comparacion/Mejor Duracion Trama/" + algoritmo + "/wavelet-" + fw{f} + "-results.mat", "resultados");
    disp("Final de pruebas de Wavelet " + fw{f} + ".");
    disp("===============================================")
end

% Carga los archivos de resultados
archivos = dir('../Resultados/Comparacion/Mejor Duracion Trama/' + algoritmo + '/*.mat');

waveletResults = zeros(length(td), length(q), length(lsc));

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

rowsNames = cell(length(td), 1);
for i = 1:length(td)
    rowsNames{i} = "td = " + td(i);
end

% Guarda resultados en un archivo .mat
resultados = array2table(totalResults,  'VariableNames', string(columnsNames), 'RowNames', string(rowsNames));
save("../Resultados/Comparacion/Mejor Duracion Trama/" + algoritmo + ".mat", "resultados");

% Grafica los resultados
title('Calidad Según el Tiempo de Duración de la Trama ' + algoritmo);
grid minor;
set(gca, 'XScale', 'log');
set(gca,'xtick', q);
hold on;
plot(q, totalResults, 'linewidth', 3);
ax = gca;
ax.FontSize = 18;
xlabel('Nivel de Cuantificación');
ylabel('Calidad');
legend(rowsNames);
hold off;

