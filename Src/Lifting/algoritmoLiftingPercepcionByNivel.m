%% Importación de funciones

addpath('../../Utilidades/');
addpath('../../Mediciones/');
addpath('../../Resultados/Lifting/Caracterizacion');


%% Limpieza de variables

clear;
close all;


%% Cargar datos de los porcentajes

load("porcentajes.mat");


%% Definicion de variables

%---------------------------FAMILIA WAVELET--------------------------------
fw = "db1";
%--------------------------FILTROS LIFTING---------------------------------
lsc = liftingScheme('Wavelet', fw);
%--------------------NÚMERO DE NIVELES DE DESCOMPOSICIÓN-------------------
n = 10;
%--------------------NÚMERO DE NIVELES DE CUANTIFICACIÓN-------------------
q = 16;
%--------------------CAMA INICIAL DE BITS POR MUESTRA----------------------
cama = 3;


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
coefBits = ones(1, n + 1)' * cama;

tamanosCoeficientes = cellfun(@(x) x(1), cellfun(@size, totalCoef(:, 1), 'UniformOutput', false));
for i = 1:n + 1
    coefBits(i) = tamanosCoeficientes(i) * coefBits(i);
end

%----------------------PORCENTAJES DE ENERGÍA------------------------------
porcentajesPercepcion = table2array(porcentajes)';
porcentajesPercepcion = [porcentajesPercepcion(1:length(coefBits) - 1); sum(porcentajesPercepcion(length(coefBits):end))];

%----------CANTIDAD DE BITS ASIGNADOS PARA CADA TRAMA DEL AUDIO------------
bitsAsignadosPerTrama = sum(coefBits);

% Si se asignan más de (1024 * cama) bits hay un error
if(bitsAsignadosPerTrama ~=  tramaSamples * cama)
    error("ERROR: Se asignaron como cama más bits de los esperados");
end

%----------CANTIDAD DE BITS RESTANTES PARA CADA TRAMA DEL AUDIO------------
bitsRestantesPerTrama = bitsMaximosPerTrama - bitsAsignadosPerTrama;

if(bitsAsignadosPerTrama > bitsMaximosPerTrama)
    error("ERROR: Se asignaron más bits de los disponibles");
end

% Se asignan los bits en base al aporte de calidad en la percepcion de cada coeficiente
coefBits = coefBits + floor(bitsRestantesPerTrama * porcentajesPercepcion);
coefBits = floor(coefBits ./ tamanosCoeficientes) .* tamanosCoeficientes;
bitsRestantesPerTrama = bitsMaximosPerTrama - sum(coefBits);

[valoresOrdenados, ubicacionesOrdenadas] = sort(porcentajesPercepcion, 'descend');
i = 1; 
while bitsRestantesPerTrama ~= 0
    % Antes de asignar se verifica si alcanza para el numero de muestras que
    % tiene el coeficiente, sino no se asigna 
    if bitsRestantesPerTrama >= tamanosCoeficientes(ubicacionesOrdenadas(i))
        coefBits(ubicacionesOrdenadas(i)) = coefBits(ubicacionesOrdenadas(i)) + tamanosCoeficientes(ubicacionesOrdenadas(i));
        bitsRestantesPerTrama = bitsRestantesPerTrama - tamanosCoeficientes(ubicacionesOrdenadas(i));
        i = i + 1;
        if i == n + 1
            i = 1;
        end
    % Asignación de ultimos bits 
    else
        valoresCercanos = tamanosCoeficientes(tamanosCoeficientes <= bitsRestantesPerTrama);
        valorMasCercano = max(valoresCercanos);
        indexValorMasCercano = find(tamanosCoeficientes == valorMasCercano);
        coefBits(indexValorMasCercano(1)) = coefBits(indexValorMasCercano(1)) + tamanosCoeficientes(indexValorMasCercano(1));
        bitsRestantesPerTrama = bitsRestantesPerTrama - tamanosCoeficientes(indexValorMasCercano(1));
    end
end


% Si se han asignado más de la totalidad de bits hay un error
bitsAsignadosPerTrama = sum(coefBits);
bitsDesperdiciadosPerTrama = bitsMaximosPerTrama - bitsAsignadosPerTrama;
if(bitsAsignadosPerTrama > bitsMaximosPerTrama)
    error("ERROR: Se asignaron más bits de los disponibles");
end

%-------------------BITS A UTILIZAR POR CADA MUESTRA-----------------------
bitsPerMuestra = floor(coefBits ./ tamanosCoeficientes);
%----------------------BITS SOBRANTES POR MUESTRA--------------------------
bitsDesperdiciadosPerNivel = mod(coefBits, tamanosCoeficientes);

% Si la suma de bits desperdiciados por nivel es mayor a cero significa que
% no se estan asignando la totalidad de bits.
if sum(bitsDesperdiciadosPerNivel) ~= 0
    error("ERROR: Se han desperdiciado bits");
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
    error("ERROR: Ocurrio un error en la asignación de bits");
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
    senalReconst(((i - 1) * tramaSamples) + 1:tramaSamples * i) = ilwt(totalCoefQuant{n + 1, i}, totalCoefQuant(1:n, i), 'LiftingScheme', lsc)'; 
end

medirPESQ(xn(1:length(senalReconst)), senalReconst')
medirNMSE(xn(1:length(senalReconst)), senalReconst')


%% Reproducción de la señal reconstruida

sound(senalReconst, fs);

