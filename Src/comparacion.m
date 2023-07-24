% Importación de funciones
addpath('../Grabaciones/');
addpath('../Mediciones/');
addpath('../Resultados/Comparacion/');
addpath('../Src/Lifting/Tradicional/Functions/');
addpath('../Src/Mallat/');
addpath('../Src/Mallat/Tradicional/Functions/');
addpath('../Utilidades/');

% Limpieza de variables
clear;
close all;
clc;

% Cargar datos de los audios previamente almacenados
load("audioCell.mat");

% Tipo de algoritmo
mallat = "Mallat";
lifting = "Lifting";

% Establezco el algoritmo por correr
algoritmo = mallat;

% Establezco el numero de niveles de descomposición
n = 9;

% Establezco la duración de cada trama en segundos
td = 0.064;

% Familias Wavelet en común entre Lifting  
fw = {'db1', 'db2', 'db3', 'db4', 'db5', 'db6', 'db7', 'db8', 'sym2', 'sym3', 'sym4', 'sym5', 'sym6', 'sym7', 'sym8', ...
    'coif2', 'bior1.1', 'bior1.3', 'bior1.5', 'bior2.2', 'bior2.4', 'bior2.6', 'bior2.8', 'bior3.1', 'bior3.3', ...
    'bior3.5', 'bior3.7', 'bior3.9', 'bior4.4', 'bior5.5', 'bior6.8', 'rbio1.1', 'rbio1.3', 'rbio1.5', 'rbio2.2', ...
    'rbio2.4', 'rbio2.6', 'rbio2.8', 'rbio3.1', 'rbio3.3', 'rbio3.5', 'rbio3.7', 'rbio3.9', 'rbio4.4', 'rbio5.5', 'rbio6.8'};

% Creación de los filtros para cada familia Wavelet
lsc = cell(1, length(fw));
for i = 1:length(fw)
    switch algoritmo
        case mallat
            [ha, ga, hs, gs] = wfilters(fw{i});
            lsc{i} = [ha; ga; hs; gs];
        case lifting
            lsc{i} = liftingScheme('Wavelet', fw{i});
        otherwise
            error("ERROR: No valid option");
    end
    
end

% Matriz de resultados de las pruebas
audioResults = load(algoritmo + "-Checkpoint.mat").audioResults;

% Análisis y síntesis con diferentes familias wavelet
for f = 1:length(lsc) % Wavelets madre
    disp("===============================================");
    disp("Inicio de pruebas de Wavelet " + fw{f});
    for i = 1:length(audioCell) % Audios
        tic;
        for j = 1:n % Niveles de descomposicion
            try
                switch algoritmo
                    case mallat
                        [~, quality] = mallatNormal(audioCell{i, 2}, j, td, lsc{f}(1, :), lsc{f}(2, :), lsc{f}(3, :), lsc{f}(4, :));
                    case lifting
                        [~, quality] = liftingNormal(audioCell{i, 2}, j, td, lsc{f});
                    otherwise
                        error("ERROR: No valid option");
                end
                audioResults(j, f) = audioResults(j, f) + quality;
            catch
                warning('Problem using function.  Assigning a value of NaN');
            end
        end
        disp("===============================================");
        disp("Wavelet " + fw{f} + ": Audio #" + i + " finalizado. Time elapsed: " + toc);
        disp("===============================================");
    end
    disp("Final de pruebas de Wavelet " + fw{f} + ".");
    disp("===============================================")
    save("../Resultados/Comparacion/" + algoritmo + "-Checkpoint.mat", "audioResults");
end

columnsNames = cell(1, length(lsc));
for i = 1:length(lsc)
    columnsNames{i} = fw{i};
end

rowsNames = cell(n, 1);
for i = 1:n
    rowsNames{i} = "n = " + i;
end

% Promedia los resultados y cambia los ceros por NaN
totalResults = audioResults / length(audioCell);

% Guarda resultados en un archivo .mat
resultados = array2table(totalResults,  'VariableNames', string(columnsNames), 'RowNames', string(rowsNames));
save("../Resultados/Comparacion/" + algoritmo + ".mat", "resultados");

% Carga los archivos de resultados
resultadosMallat = table2array(load('../Resultados/Comparacion/' + mallat + '.mat').resultados);
resultadosLifting = table2array(load('../Resultados/Comparacion/' + lifting + '.mat').resultados);

% Promedia los resultados
totalResults = zeros(n, 2);
totalResults(:, 1) = mean(resultadosMallat, 2);
totalResults(:, 2) = mean(resultadosLifting, 2);

algorithmNames = cell(1, 2);
algorithmNames{1} = mallat;
algorithmNames{2} = lifting;

% Grafica los resultados
title('Mallat vs Lifting');
grid on;
grid minor;
hold on;
for i = 1:length(algorithmNames)
    plot(1:n, totalResults(:, i), 'linewidth', 2.5, 'DisplayName', algorithmNames{i});
end
xlabel('Niveles de Descomposición');
ylabel('Calidad');
legend;
hold off;
