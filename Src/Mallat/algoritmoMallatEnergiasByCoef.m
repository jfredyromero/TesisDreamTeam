%% Limpieza de variables

clear;
close all;


%% Definicion de variables

%---------------------------FAMILIA WAVELET--------------------------------
fw = "db8";
%---------------------------FILTROS MALLAT---------------------------------
[ha, ga, hs, gs] = wfilters(fw);
%--------------------NÚMERO DE NIVELES DE DESCOMPOSICIÓN-------------------
n = 2;
%--------------------NÚMERO DE NIVELES DE CUANTIFICACIÓN-------------------
q = 256;


%% Lectura de la señal de voz

[x, Fs] = audioread('Grabaciones/Hombres/Fredy Andres Dorado/1. Andres Dorado.m4a');
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
totalEnergia = sum(sum(energiaCoef));


%% Asignación de bits y niveles de cuantificación

%---------------------BITS A UTILIZAR POR MUESTRA--------------------------
bitsPerSample = log2(q);
%------------------BITS A UTILIZAR POR TODO EL AUDIO-----------------------
bitsMaximos = bitsPerSample * tramaSamples * numTramas; 
%----------------------PORCENTAJES DE ENERGÍA------------------------------
porcentajesEnergia = energiaCoef / totalEnergia;
%--------------MATRIZ DE BITS ASIGNADOS POR COEFICIENTES-------------------
coefBits = zeros(n + 1, numTramas);
for i = 1:numel(totalCoef)
    if mod(i, n + 1) == 0
        indexX = n + 1;
    else
        indexX = mod(i, n + 1);
    end
    % Se asigna un bit a cada muestra como minimo
    coefBits(indexX, floor((i - 1) / (n + 1)) + 1) = length(totalCoef{i});
end

% Si se asignan más de 1024 bits hay un error
bitsAsignados = sum(sum(coefBits));
if(bitsAsignados ~= numTramas * tramaSamples)
    disp("===============================================")
    disp("ERROR: Se asignaron más bits de los esperados");
    disp("===============================================")
    return;
end

%--------------CANTIDAD DE BITS RESTANTES PARA TODO EL AUDIO---------------
bitsRestantes = bitsMaximos - bitsAsignados;
% Se asignan los bits en base al aporte de energia de cada coeficiente
coefBits = coefBits + floor(bitsRestantes * porcentajesEnergia);

% Si se han asignado más de la totalidad de bits hay un error
bitsAsignados = sum(sum(coefBits));
bitsDesperdiciados = bitsMaximos - bitsAsignados;
if(bitsAsignados > bitsMaximos)
    disp("===============================================")
    disp("ERROR: Se asignaron más bits de los disponibles");
    disp("===============================================")
    return;
end

%-------------------BITS A UTILIZAR POR CADA MUESTRA-----------------------
bitsPerMuestraCoef = zeros(n + 1, numTramas);
%----------------------BITS SOBRANTES POR MUESTRA--------------------------
bitsDesperdiciadosPerCoef = zeros(n + 1, numTramas);
aux = totalCoef(:, 1);
for i = 1:n + 1
    bitsPerMuestraCoef(i, :) = floor(coefBits(i, :) / length(aux{i}));
    bitsDesperdiciadosPerCoef(i, :) = mod(coefBits(i, :), length(aux{i}));
end
%---------------------MATRIZ NIVELES DE CUANTIFICACION---------------------
qPerCoef = 2.^(bitsPerMuestraCoef);


%% Cálculo de bits usados y desperdiciados por trama

bitsDesperdiciados = bitsDesperdiciados + sum(sum(bitsDesperdiciadosPerCoef));
bitsUsadosPerCoef = coefBits - bitsDesperdiciadosPerCoef;
bitsUsados = sum(sum(bitsUsadosPerCoef));

% Si la suma de los bits usados y los bits desperdiciados es diferente de
% la cantidad maxima de bits a usar hay un error
if (bitsUsados + bitsDesperdiciados) ~= bitsMaximos
    disp("===============================================")
    disp("ERROR: Ocurrio un error en la asignación de bits");
    disp("===============================================")
    return;
end


%% Cuantificación de los coeficientes totales

%---------------MATRIZ DE LOS COEFICIENTES CUANTIFICADOS-------------------
totalCoefQuant = cell([n + 1, numTramas]);
for i = 1:numel(totalCoef)
    if mod(i, n + 1) == 0
        qIndex = n + 1;
    else
        qIndex = mod(i, n + 1);
    end    
    totalCoefQuant{i} = cuantUniV(totalCoef{i}, qPerCoef(qIndex, floor((i - 1) / (n + 1)) + 1));
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

