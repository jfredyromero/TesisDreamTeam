%% Importación de funciones

addpath('../../Utilidades/');
addpath('../../Mediciones/');


%% Limpieza de variables

clear;
close all;


%% Definicion de variables

%---------------------------FAMILIA WAVELET--------------------------------
fw = "db1";
%---------------------------FILTROS MALLAT---------------------------------
[ha, ga, hs, gs] = wfilters(fw);
%--------------------NÚMERO DE NIVELES DE DESCOMPOSICIÓN-------------------
n = 1;
%--------------------NÚMERO DE NIVELES DE CUANTIFICACIÓN-------------------
q = 32;
%--------------------CAMA INICIAL DE BITS POR MUESTRA----------------------
cama = 5;


%% Lectura de la señal de voz

[x, Fs] = audioread('../../Grabaciones/Mujeres/Veronica Lopez/9. Veronica Lopez.m4a');
Ts = 1 / Fs;


%% Muestreo de la señal a 16KHz

%---------------------------FACTOR DE SUBMUESTREO------------------------------
i = 3; % Ya que así se muestreará a una frecuencia de 16KHz --> 48KHz/3
l = i * floor(length(x) / i);
x = x(1:l);
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
    [tramaScalingCoef, tramaWaveletCoef] = m_dwt(tramas(i, :), ha, ga, n); 
    % Se guardan los coeficientes Scaling de la trama
    scalingCoef{i} = tramaScalingCoef;
    % Se guardan los coeficientes Wavelet de cada uno de los n niveles de descomposición trama
    for j = 1:n
        waveletCoef{j, i} = tramaWaveletCoef{j};
    end
end
%------------------------COEFICIENTES TOTALES------------------------------
totalCoef = [waveletCoef; scalingCoef];


%% Cálculo de la energía de los coeficientes

%------------------MATRIZ DE ENERGIA DE LOS COEFICIENTES-------------------
energiaCoef = zeros(n + 1, numTramas);
for i = 1:numel(totalCoef)
    if mod(i, n + 1) == 0
        indexX = n + 1;
    else
        indexX = mod(i, n + 1);
    end
    energiaCoef(indexX, floor((i - 1) / (n + 1)) + 1) = sum(totalCoef{i}.^2);
    % energiaCoef(indexX, floor((i - 1) / (n + 1)) + 1) = (1 / length(totalCoef{i})) * sum(totalCoef{i}.^2);
end
promedioEnergia = (1/numTramas) * sum(energiaCoef, 2);
totalEnergia = sum(promedioEnergia);


%% Asignación de bits y niveles de cuantificación

%---------------------BITS A UTILIZAR POR MUESTRA--------------------------
bitsPerSample = log2(q);
%------------------BITS A UTILIZAR POR TRAMA DEL AUDIO---------------------
bitsMaximosPerTrama = bitsPerSample * tramaSamples; 
%----------------------PORCENTAJES DE ENERGÍA------------------------------
porcentajesEnergia = promedioEnergia / totalEnergia;
%--------------MATRIZ DE BITS ASIGNADOS POR COEFICIENTES-------------------
coefBits = ones(1, n + 1)' * cama;

aux = totalCoef(:, 1);
for i = 1:n + 1
    coefBits(i) = length(aux{i}) * coefBits(i);
end

%----------CANTIDAD DE BITS ASIGNADOS PARA CADA TRAMA DEL AUDIO------------
bitsAsignadosPerTrama = sum(coefBits);

% Si se asignan más de (1024 * cama) bits hay un error
if(bitsAsignadosPerTrama ~=  tramaSamples * cama)
    disp("===============================================")
    disp("ERROR: Se asignaron como cama más bits de los esperados");
    disp("===============================================")
    return;
end

%----------CANTIDAD DE BITS RESTANTES PARA CADA TRAMA DEL AUDIO------------
bitsRestantesPerTrama = bitsMaximosPerTrama - bitsAsignadosPerTrama;
% Se asignan los bits en base al aporte de energia de cada coeficiente
coefBits = coefBits + floor(bitsRestantesPerTrama * porcentajesEnergia);

% Si se han asignado más de la totalidad de bits hay un error
bitsAsignadosPerTrama = sum(coefBits);
bitsDesperdiciadosPerTrama = bitsMaximosPerTrama - bitsAsignadosPerTrama;
if(bitsAsignadosPerTrama > bitsMaximosPerTrama)
    disp("===============================================")
    disp("ERROR: Se asignaron más bits de los disponibles");
    disp("===============================================")
    return;
end

%-------------------BITS A UTILIZAR POR CADA MUESTRA-----------------------
bitsPerMuestra = zeros(n + 1, 1);
%----------------------BITS SOBRANTES POR MUESTRA--------------------------
bitsDesperdiciadosPerNivel = zeros(n + 1, 1);
for i = 1:n + 1
    bitsPerMuestra(i) = floor(coefBits(i) / length(aux{i}));
    bitsDesperdiciadosPerNivel(i) = mod(coefBits(i), length(aux{i}));
end
%---------------------MATRIZ NIVELES DE CUANTIFICACION---------------------
qPerNivelDescomp = 2.^(bitsPerMuestra);


%% Cálculo de bits usados y desperdiciados por trama

bitsDesperdiciadosPerTrama = bitsDesperdiciadosPerTrama + sum(bitsDesperdiciadosPerNivel);
bitsUsadosPerNivel = coefBits - bitsDesperdiciadosPerNivel;
bitsUsadosPerTrama = sum(bitsUsadosPerNivel);

% Si la suma de los bits usados y los bits desperdiciados es diferente de
% la cantidad maxima de bits a usar hay un error
if (bitsUsadosPerTrama + bitsDesperdiciadosPerTrama) ~= bitsMaximosPerTrama
    disp("===============================================")
    disp("ERROR: Ocurrio un error en la asignación de bits");
    disp("===============================================")
    return;
end

bitsDesperdiciados = bitsDesperdiciadosPerTrama * 100 / bitsMaximosPerTrama;
bitsUsados = bitsUsadosPerTrama * 100 / bitsMaximosPerTrama;


%% Cuantificación de los coeficientes totales

%---------------MATRIZ DE LOS COEFICIENTES CUANTIFICADOS-------------------
totalCoefQuant = cell([n + 1, numTramas]);
for i = 1:numel(totalCoef)
    if mod(i, n + 1) == 0
        qIndex = n + 1;
    else
        qIndex = mod(i, n + 1);
    end
    totalCoefQuant{qIndex, floor((i - 1) / (n + 1)) + 1} = cuantUniV(totalCoef{i}, qPerNivelDescomp(qIndex));
end


%% Reconstrucción de las tramas y de la señal original

senalReconst = 1:numel(tramas);
for i = 1:numTramas
    lastScalingCoef = totalCoefQuant{end, i};
    for j = 1:n
        lastWaveletCoef = totalCoefQuant{end - j, i};
        lastScalingCoef = p_idwt(lastScalingCoef, lastWaveletCoef, hs, gs);
    end
    senalReconst(((i - 1) * tramaSamples) + 1:tramaSamples * i) = lastScalingCoef;
end

medirPESQ(xn(1:length(senalReconst)), senalReconst')
medirNMSE(xn(1:length(senalReconst)), senalReconst')


%% Reproducción de la señal reconstruida

sound(senalReconst, fs);

