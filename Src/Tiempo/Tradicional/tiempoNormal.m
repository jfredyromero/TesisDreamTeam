%% Importación de funciones

addpath('../../../Utilidades/');
addpath('../../../Mediciones/');
addpath('../../Mallat/');


%% Limpieza de variables

clear;
close all;
clc;


%% Definicion de variables

%--------------------NÚMERO DE NIVELES DE CUANTIFICACIÓN-------------------
q = 8;


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

%------------------------------SEÑAL FINAL---------------------------------
senalReconst = 1:numel(tramas);

for i = 1:numTramas
    %% Cuantificación de las tramas
        
    tic;
    tramaCoefReconst = cuantUniV(tramas(i, :), q)';

    %% Reconstrucción de las tramas y de la señal original
    
    senalReconst(((i - 1) * tramaSamples) + 1:tramaSamples * i) = tramaCoefReconst;
    disp("Trama #" + i + " procesada. Time elapsed: " + toc);
end

pesq = ((medirPESQ(xn(1:length(senalReconst)), senalReconst')) + 0.5) / 5;
nmse = medirNMSE(xn(1:length(senalReconst)), senalReconst');
calidadTotal = (pesq + nmse) / 2


%% Reproducción de la señal reconstruida

sound(senalReconst, fs);

