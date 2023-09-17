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
n = 2;

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
waveletResults = zeros(length(audioCell), 3);
scalingResults = zeros(length(audioCell), 3);

for f = 1:length(lsc) % Wavelets madre
    disp("===============================================");
    disp("Inicio de pruebas de Wavelet " + fw{f});
    for i = 1:length(audioCell) % Audios
        tic;    
        
        signal = audioCell{i, 2};
        %-----------------------FACTOR DE MUESTREO Y PERIODO---------------------------
        Fs = 48000;
        %---------------------------FACTOR DE SUBMUESTREO------------------------------
        fsm = 3; % Ya que así se muestreará a una frecuencia de 16KHz --> 48KHz/3
        l = fsm * floor(length(signal) / fsm);
        signal = signal(1:l);
        %---------------------------SEÑAL SUBMUESTREADA------------------------------
        xn = downsample(signal, fsm);
        fs = Fs / fsm;
        
        %--------------------LONGITUD DE TRAMA EN MUESTRAS----------------------
        tramaSamples = round(fs * td);
        %---------------------------NUMERO DE TRAMAS----------------------------
        numTramas = floor(length(xn) / tramaSamples);
        %---------------------------MATRIZ DE TRAMAS----------------------------
        tramas = zeros(numTramas, tramaSamples);
        for j = 1:numTramas
            inicio = (j - 1) * tramaSamples + 1;
            fin = j * tramaSamples;
            tramas(j, :) = xn(inicio:fin);
        end

        % -----------------------COEFICIENTES SCALING------------------------------
        scalingCoef = cell([1, numTramas]);
        %------------------------COEFICIENTES WAVELET------------------------------
        waveletCoef = cell([n, numTramas]);
        for j = 1:numTramas
            [tramaScalingCoef, tramaWaveletCoef] = lwt(tramas(j, :), 'LiftingScheme', lsc{f}, 'Level', n); 
            % Se guardan los coeficientes Scaling de la trama
            scalingCoef{j} = tramaScalingCoef;
            % Se guardan los coeficientes Wavelet de cada uno de los n niveles de descomposición trama
            for k = 1:n
                waveletCoef{k, j} = tramaWaveletCoef{k};
            end
        end
        %------------------------COEFICIENTES TOTALES------------------------------
        totalCoef = [waveletCoef; scalingCoef];

        % Maximos y minimos de todos los coeficientes
        maxTotalCoef = cellfun(@(x) max(max(x)), totalCoef);
        minTotalCoef = cellfun(@(x) min(min(x)), totalCoef);

        % Dispersion, varianza y desviacion estandar
        dispTotalCoef = maxTotalCoef - minTotalCoef;
        varTotalCoef = cellfun(@(x) var(x), totalCoef);
        stdTotalCoef = cellfun(@(x) std(x), totalCoef);

        dispersion = mean(dispTotalCoef, 2);
        varianza = mean(varTotalCoef, 2);
        desviacion = mean(stdTotalCoef, 2);

        % Almacenamiento de resultados
        waveletResults(i, 1) = mean(dispersion(1:end - 1));
        waveletResults(i, 2) = mean(varianza(1:end - 1));
        waveletResults(i, 3) = mean(desviacion(1:end - 1));
        
        scalingResults(i, 1) = dispersion(end);
        scalingResults(i, 2) = varianza(end);
        scalingResults(i, 3) = desviacion(end);
        
        disp("===============================================");
        disp("Wavelet " + fw{f} + ": Audio #" + i + " finalizado. Time elapsed: " + toc);
        disp("===============================================");
    end

    waveletTable = array2table(mean(waveletResults),  'VariableNames', string({"Dispersion", "Varianza", "Desviacion"}));
    scalingTable = array2table(mean(scalingResults),  'VariableNames', string({"Dispersion", "Varianza", "Desviacion"}));

    save("../Resultados/Lifting/Comprobaciones/Mejor Familia/" + fw{f} + "/wavelet-results.mat", "waveletTable");
    save("../Resultados/Lifting/Comprobaciones/Mejor Familia/" + fw{f} + "/scaling-results.mat", "scalingTable");

    disp("Final de pruebas de Wavelet " + fw{f} + ".");
    disp("===============================================")
end

