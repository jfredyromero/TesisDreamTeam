%% Importación de funciones

addpath('../../Utilidades/');
addpath('../../Mediciones/');


%% Limpieza de variables

clear;
close all;


%% Definicion de variables

%---------------------------FAMILIA WAVELET--------------------------------
fw = "db1";
%--------------------------FILTROS LIFTING---------------------------------
lsc = liftingScheme('Wavelet', fw);
%--------------------NÚMERO DE NIVELES DE DESCOMPOSICIÓN-------------------
n = 6;
%--------------------NÚMERO DE NIVELES DE CUANTIFICACIÓN-------------------
q = 8;


%% Lectura de la señal de voz

[x, Fs] = audioread('../../Grabaciones/Mujeres/Veronica Lopez/9. Veronica Lopez.m4a');
Ts = 1 / Fs;


%% Muestreo de la señal a 16KHz

%---------------------------FACTOR DE SUBMUESTREO------------------------------
i = 3; % Ya que así se muestreará a una frecuencia de 16KHz --> 48KHz/3
l = i * floor(length(x) / i);
x = x(1:l);
t = 0:Ts:length(x) / Fs - Ts;
%---------------------------SEÑAL SUBMUESTREADA------------------------------
xn = downsample(x, i);
fs = Fs/i;


%% División de la señal en tramas

%--------------------LONGITUD DE TRAMA EN SEGUNDOS----------------------
tramaDuration = 0.064; % 64 milisegundos
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


%% Transformada Wavelet con algoritmo Mallat

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


%% Cuantificación de los coeficientes totales

%---------------MATRIZ DE LOS COEFICIENTES CUANTIFICADOS-------------------
totalCoefQuant = cell([n + 1, numTramas]);
for i = 1:numel(totalCoef)
    if mod(i, n + 1) == 0
        qIndex = n + 1;
    else
        qIndex = mod(i, n + 1);
    end
    totalCoefQuant{qIndex, floor((i - 1) / (n + 1)) + 1} = cuantUniVNew(totalCoef{i}, q);
end


%% Reconstrucción de las tramas y de la señal original

senalReconst = 1:numel(tramas);
for i = 1:numTramas
    senalReconst(((i - 1) * tramaSamples) + 1:tramaSamples * i) = ilwt(totalCoefQuant{n + 1, i}, totalCoefQuant(1:n, i), 'LiftingScheme', lsc)'; 
end

pesq = ((medirPESQ(xn(1:length(senalReconst)), senalReconst')) + 0.5) / 5;
nmse = medirNMSE(xn(1:length(senalReconst)), senalReconst');
(pesq + nmse) / 2


%% Reproducción de la señal reconstruida

sound(senalReconst, fs);

