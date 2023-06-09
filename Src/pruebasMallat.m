% Importación de funciones
addpath('../Grabaciones/');
addpath('../Utilidades/');
addpath('../Mediciones/');
addpath('Mallat/');
addpath('Lifting/');

% Limpieza de variables
clear;
close all;

% Cargar datos de los audios previamente almacenados
load("audioCell.mat");

% Establezco el numero de niveles de descomposición
n = 5;

% Establezco el numero de niveles de cuantificación
q = [4 8 16 32 64 128 256];

% Familias Wavelet en común entre Lifting y Mallat 
fw = {'db1', 'db2', 'db3', 'db4', 'db5', 'db6', 'db7', 'db8', 'sym2', 'sym3', 'sym4', 'sym5', 'sym6', 'sym7', 'sym8', ...
    'coif2', 'bior1.1', 'bior1.3', 'bior1.5', 'bior2.2', 'bior2.4', 'bior2.6', 'bior2.8', 'bior3.1', 'bior3.3', ...
    'bior3.5', 'bior3.7', 'bior3.9', 'bior4.4', 'bior5.5', 'bior6.8', 'rbio1.1', 'rbio1.3', 'rbio1.5', 'rbio2.2', ...
    'rbio2.4', 'rbio2.6', 'rbio2.8', 'rbio3.1', 'rbio3.3', 'rbio3.5', 'rbio3.7', 'rbio3.9', 'rbio4.4', 'rbio5.5', 'rbio6.8'};

% Cama inicial de bits por muestra
cama = 4;

% Creación de los filtros para cada familia Wavelet
msc = cell(1, length(fw));
filters = cell(1, 4);
for i = 1:length(fw) 
    [filters{1}, filters{2}, filters{3}, filters{4}] = wfilters(fw{i});
    msc{i} = filters;
end

% Obtengo los nombres de las columnas para las tablas de resultados
columnsNames = getColumnsNames(n, q);

% Matriz de resultados de las pruebas
audioResults = cell(length(audioCell), 4 * n * length(q) + 1);
audioResults(:, 1) = audioCell(:, 1);

for f = 1:length(msc) % Wavelets madre
    tic;
    disp("===============================================")
    disp("Inicio de pruebas de Wavelet " + fw{f});
    for i = 1:length(audioCell) % Audios
        indexer = 2;
        for j = 1:n % Niveles de descomposición
            for k = q % Niveles de cuantificación
                [ha, ga, hs, gs] = msc{f}{:};
                % [processedSignal, bitsUsados, bitsDesperdiciados] = algoritmoMallatEnergiasByCoefFunction(audioCell{i, 2}, j, k, cama, ha, ga, hs, gs);
                [processedSignal, bitsUsados, bitsDesperdiciados] = algoritmoMallatEnergiasByNivelFunction(audioCell{i, 2}, j, k, cama, ha, ga, hs, gs);
                originalSignal = downsample(audioCell{i, 2}, 3);
                originalSignal = originalSignal(1:length(processedSignal))'; % Corto la señal original al tamaño de la procesada y la transpongo
                pesq = medirPESQ(originalSignal, processedSignal);
                audioResults{i, indexer} = pesq;
                indexer = indexer + 1;
                nmse = medirNMSE(originalSignal, processedSignal);
                audioResults{i, indexer} = nmse;
                indexer = indexer + 1;
                audioResults{i, indexer} = bitsUsados + "%";
                indexer = indexer + 1;
                audioResults{i, indexer} = bitsDesperdiciados + "%";
                indexer = indexer + 1;
            end
        end        
    end
    saveResults(audioResults, columnsNames, fw{f}, "Mallat");
    disp("Tardó " + toc + " segundos");
    disp("Final de pruebas de Wavelet " + fw{f});
    disp("===============================================")
end    