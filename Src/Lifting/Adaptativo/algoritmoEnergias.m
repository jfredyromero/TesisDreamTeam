%% Importación de funciones

addpath('../../../Utilidades/');
addpath('../../../Mediciones/');


%% Limpieza de variables

clear;
close all;
clc;


%% Definicion de variables

%---------------------------FAMILIA WAVELET--------------------------------
fw = "db1";
%--------------------------FILTROS LIFTING---------------------------------
lsc = liftingScheme('Wavelet', fw);
%--------------------NÚMERO DE NIVELES DE DESCOMPOSICIÓN-------------------
n = 9;
%--------------------NÚMERO DE NIVELES DE CUANTIFICACIÓN-------------------
q = 8;
%--------------------CAMA INICIAL DE BITS POR MUESTRA----------------------
cama = log2(q) - 1;


%% Lectura de la señal de voz

[x, Fs] = audioread('../../../Grabaciones/Mujeres/Veronica Lopez/9. Veronica Lopez.m4a');
Ts = 1 / Fs;


%% Muestreo de la señal a 16KHz

%---------------------------FACTOR DE SUBMUESTREO------------------------------
i = 3; % Ya que así se muestreará a una frecuencia de 16KHz --> 48KHz/3
l = i * floor(length(x) / i);
x = x(1:l);
%---------------------------SEÑAL SUBMUESTREADA------------------------------
xn = downsample(x, i);
fs = Fs / i;


%% División de la señal en tramas

%--------------------LONGITUD DE TRAMA EN SEGUNDOS----------------------
tramaDuration = 0.032; % 32 milisegundos
%--------------------LONGITUD DE TRAMA EN MUESTRAS----------------------
tramaSamples = round(fs * tramaDuration);
%---------------------------NUMERO DE TRAMAS----------------------------
numTramas = floor(length(xn) / tramaSamples);
%---------------------------MATRIZ DE TRAMAS----------------------------
tramas = zeros(numTramas, tramaSamples);
for i = 1:numTramas
    inicio = (i - 1) * tramaSamples + 1;
    fin = i * tramaSamples;
    tramas(i, :) = xn(inicio:fin);
end


%% Transformada Wavelet con algoritmo Lifting

% -----------------------COEFICIENTES SCALING------------------------------
scalingCoef = cell([1, numTramas]);
%------------------------COEFICIENTES WAVELET------------------------------
waveletCoef = cell([n, numTramas]);
for i = 1:numTramas
    [tramaScalingCoef, tramaWaveletCoef] = lwt(tramas(i, :), 'LiftingScheme', lsc, 'Level', n); 
    % Se guardan los coeficientes Scaling de la trama
    scalingCoef{i} = tramaScalingCoef;
    % Se guardan los coeficientes Wavelet de cada uno de los n niveles de descomposición trama
    for j = 1:n
        waveletCoef{j, i} = tramaWaveletCoef{j};
    end
end
%------------------------COEFICIENTES TOTALES------------------------------
totalCoef = [waveletCoef; scalingCoef];


%% Asignación de bits y niveles de cuantificación

%---------------------BITS A UTILIZAR POR MUESTRA--------------------------
bitsPerSample = log2(q);
%------------------BITS A UTILIZAR POR TRAMA DEL AUDIO---------------------
bitsMaximosPerTrama = bitsPerSample * tramaSamples;
%--------------MATRIZ DE BITS ASIGNADOS POR COEFICIENTES-------------------
coefBits = ones(n + 1, numTramas) * cama;
%--------------MATRIZ DE TAMAÑO DE CADA GRUPO DE COEFICIENTES--------------
tamanosCoeficientes = cellfun(@(x) x(1), cellfun(@size, totalCoef(:, 1), 'UniformOutput', false));
coefBits = tamanosCoeficientes .* coefBits;
%------------------------------SEÑAL FINAL---------------------------------
senalReconst = 1:numel(tramas);


for i = 1:numTramas
    
    %% Cálculo de la energía de los coeficientes
    
    tic;
    energiaCoef = zeros(n + 1, 1);
    for j = 1:n + 1
        energiaCoef(j) = sum(totalCoef{j, i}.^2);
    end

    %------------------------PORCENTAJES DE ENERGIA----------------------------
    porcentajesEnergia = energiaCoef / sum(energiaCoef);

    tramaCoefBits = ones(n + 1, 1) * cama;          
    tramaCoefBits = tamanosCoeficientes .* tramaCoefBits;
    
    %----------CANTIDAD DE BITS ASIGNADOS PARA CADA TRAMA DEL AUDIO------------
    bitsAsignadosPerTrama = sum(tramaCoefBits);

    % Si se asignan más de (1024 * cama) bits hay un error
    if(bitsAsignadosPerTrama ~=  tramaSamples * cama)
        error("ERROR: Se asignaron como cama más bits de los esperados");
    end

    %----------CANTIDAD DE BITS RESTANTES PARA CADA TRAMA DEL AUDIO------------
    bitsRestantesPerTrama = bitsMaximosPerTrama - bitsAsignadosPerTrama;
    
    if(bitsAsignadosPerTrama > bitsMaximosPerTrama)
        error("ERROR: Se asignaron más bits de los disponibles");
    end

    % Distribución inteligente de bits para que no sobre ninguno
    tramaCoefBits = bitDistributor(tramaCoefBits, porcentajesEnergia, tamanosCoeficientes, bitsMaximosPerTrama);
    coefBits(:, i) = tramaCoefBits;

    % Si se han asignado más de la totalidad de bits hay un error
    bitsAsignadosPerTrama = sum(tramaCoefBits);
    if(bitsAsignadosPerTrama > bitsMaximosPerTrama)
        error("ERROR: Se asignaron más bits de los disponibles");
    end

    %-------------------BITS A UTILIZAR POR CADA MUESTRA-----------------------
    bitsPerMuestra = floor(tramaCoefBits ./ tamanosCoeficientes);
    %----------------------BITS SOBRANTES POR MUESTRA--------------------------
    bitsDesperdiciadosPerNivel = mod(tramaCoefBits, tamanosCoeficientes);
    
    % Si la suma de bits desperdiciados por nivel es mayor a cero significa que
    % no se estan asignando la totalidad de bits.
    if sum(bitsDesperdiciadosPerNivel) ~= 0
        error("ERROR: Se han desperdiciado bits");
    end

    %---------------------MATRIZ NIVELES DE CUANTIFICACION---------------------
    qPerNivelDescomp = 2.^(bitsPerMuestra);


    %% Cuantificación de los coeficientes totales
        
    %---------------MATRIZ DE LOS COEFICIENTES CUANTIFICADOS-------------------
    tramaCoefQuant = cell([n + 1, 1]);
    for j = 1:n + 1
        tramaCoefQuant{j} = cuantUniV(totalCoef{j, i}, qPerNivelDescomp(j));
    end


    %% Reconstrucción de las tramas y de la señal original
    
    tramaCoefReconst = ilwt(tramaCoefQuant{n + 1}, tramaCoefQuant(1:n), 'LiftingScheme', lsc)';
    senalReconst(((i - 1) * tramaSamples) + 1:tramaSamples * i) = tramaCoefReconst;
    disp("Trama #" + i + " procesada. Time elapsed: " + toc);
end


%% Calculo de la calidad

pesq = ((medirPESQ(xn(1:length(senalReconst)), senalReconst')) + 0.5) / 5;
nmse = medirNMSE(xn(1:length(senalReconst)), senalReconst');
calidadTotal = (pesq + nmse) / 2


%% Reproducción de la señal reconstruida

sound(senalReconst, fs);

