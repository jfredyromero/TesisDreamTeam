% Importación de funciones

addpath('../Grabaciones/');
addpath('../Mediciones/');
addpath('Lifting/');

% Limpieza de variables
clear;
close all;

% Cargar datos de los audios previamente almacenados
load("audioCell.mat");

% Establezco el numero de niveles de descomposición
n = 10;

% Familias Wavelet en común entre Lifting y Mallat 
fw = {'db1', 'db2', 'db3', 'db4', 'db5', 'db6', 'db7', 'db8', 'sym2', 'sym3', 'sym4', 'sym5', 'sym6', 'sym7', 'sym8', ...
    'coif2', 'bior1.1', 'bior1.3', 'bior1.5', 'bior2.2', 'bior2.4', 'bior2.6', 'bior2.8', 'bior3.1', 'bior3.3', ...
    'bior3.5', 'bior3.7', 'bior3.9', 'bior4.4', 'bior5.5', 'bior6.8', 'rbio1.1', 'rbio1.3', 'rbio1.5', 'rbio2.2', ...
    'rbio2.4', 'rbio2.6', 'rbio2.8', 'rbio3.1', 'rbio3.3', 'rbio3.5', 'rbio3.7', 'rbio3.9', 'rbio4.4', 'rbio5.5', 'rbio6.8'};

% Creación de los filtros para cada familia Wavelet
lsc = cell(1, length(fw));
for i = 1:length(fw) 
    lsc{i} = liftingScheme('Wavelet', fw{i});
end

% Crea los nombres de las columnas
columnsNames = cell(1, n + 1);
columnsNames{1} = "Audio";
for i = 1:n
    columnsNames{i + 1} = "PESQ coeficiente Wavelet " + i + " eliminado";
end

% Matriz de resultados de las pruebas
audioResults = cell(length(audioCell), n + 1);
audioResults(:, 1) = audioCell(:, 1);

for f = 1:length(lsc) % Wavelets madre
    tic;
    disp("===============================================")
    disp("Inicio de pruebas de Wavelet " + fw{f});
    for i = 1:length(audioCell) % Audios
        for z = 1:n % Coeficientes removidos
            processedSignal = liftingCaracterizacionByCoefFunction(audioCell{i, 2}, n, z, lsc{f});
            originalSignal = downsample(audioCell{i, 2}, 3);
            originalSignal = originalSignal(1:length(processedSignal))'; % Corto la señal original al tamaño de la procesada y la transpongo
            pesq = medirPESQ(originalSignal, processedSignal) / 4.639;
            nmse = medirNMSE(originalSignal, processedSignal);
            audioResults{i, z + 1} = (pesq + nmse) / 2;
        end
    end
    resultTable = cell2table(audioResults,  'VariableNames', string(columnsNames));

    % Guarda la tabla con los resultados de las pruebas de los audios
    save("../Resultados/Lifting/Caracterizacion/wavelet-" + fw{f} + "-caracterization.mat", "resultTable");

    disp("Tardó " + toc + " segundos");
    disp("Final de pruebas de Wavelet " + fw{f});
    disp("===============================================")
end    