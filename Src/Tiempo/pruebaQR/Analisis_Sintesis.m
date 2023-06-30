clear
close all
%% Definicion de variables

%---------------------------FAMILIA WAVELET--------------------------------
fw = "db4";
%--------------------------FILTROS LIFTING---------------------------------
%lsc =customLiftingScheme(fw);
lsc = liftingScheme('Wavelet', fw);
%--------------------NÚMERO DE NIVELES DE DESCOMPOSICIÓN-------------------
n = 1;


%% lectura de los archivos de audio
[x,Fs]=audioread("audio1.m4a");

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
k=1/8;
tramaDuration = k*0.064; % 64 milisegundos
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
if mod(numTramas,1/k)~=0
    tramas=tramas(1:end-mod(numTramas,1/k),:);
    numTramas = numTramas-mod(numTramas,1/k);
end

%% Transformada Wavelet con algoritmo Lifting

% -----------------------COEFICIENTES SCALING------------------------------
scalingCoef = cell([1, numTramas]);
%------------------------COEFICIENTES WAVELET------------------------------
waveletCoef = cell([n, numTramas]);
for i = 1:numTramas
    %[tramaScalingCoef, tramaWaveletCoef] = lwt(tramas(i, :), 'LiftingScheme', lsc, 'Level', n,'Extension','periodic'); 
    [tramaScalingCoef, tramaWaveletCoef] = lwt(tramas(i, :), 'LiftingScheme', lsc, 'Level', n,'Extension','symmetric'); 
    %[tramaScalingCoef, tramaWaveletCoef] = lwt(tramas(i, :), 'LiftingScheme', lsc, 'Level', n,'Extension','zeropad'); 
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
porcentajes = promedioEnergia/totalEnergia;


%% Cuantificación

q = 32;

%asignación de niveles de cuantificación
bulk = log2(q)*tramaSamples;
numCoef = n+1; %grupos decoeficientes
q_coef = 2*ones(1, numCoef); %inicia cada grupo de ecoeficientes con dos niveles de cuantificación

remBulk = bulk - tramaSamples;

for i = numCoef:-1:1
    qi=ceil((porcentajes(i)*remBulk)/(length(totalCoef{i,1})));
    q_coef(i) = q_coef(i) + 2^qi;
    remBulk = remBulk - qi*length(totalCoef{i,1});
    if remBulk == 0
        break
    elseif remBulk < 0
        print("error sobrepasa el número de bits")
    end
end

%% Cuantificación de los coeficientes 
quantCoef = cell(size(totalCoef));
wink = cell(size(totalCoef));
for j = 1:numTramas
    coef = totalCoef(:,j);
    for i = numCoef:-1:1
        [yc,C,S]=cuantUniNorm(coef{i},

        
        (i));
        quantCoef{i,j} = yc;
        wink{i,j} = [S C];
    end
end

%% promediar los valores de wink en grupos de 1/k tramas para no aumentar la
%señalización con respecto al tiempo 
wink2 = promSignal(wink,k);
%% Reconstrucción de las tramas y de la señal original
totalCoefRec = cell(size(totalCoef));
for j = 1:numTramas
    coef = quantCoef(:,j);
    scale = wink2(:,j);
    for i = numCoef:-1:1
        totalCoefRec{i,j} = unNorm(coef{i},scale{i});
    end
end



senalReconst = 1:numel(tramas);
for i = 1:numTramas
    %senalReconst(((i - 1) * tramaSamples) + 1:tramaSamples * i) = ilwt(totalCoefRec{n + 1, i}, totalCoefRec(1:n, i), 'LiftingScheme', lsc, 'Extension','periodic')';
    senalReconst(((i - 1) * tramaSamples) + 1:tramaSamples * i) = ilwt(totalCoefRec{n + 1, i}, totalCoefRec(1:n, i), 'LiftingScheme', lsc, 'Extension','symmetric')'; 
    %senalReconst(((i - 1) * tramaSamples) + 1:tramaSamples * i) = ilwt(totalCoefRec{n + 1, i}, totalCoefRec(1:n, i), 'LiftingScheme', lsc, 'Extension','zeropad')'; 

end


sound(senalReconst, fs);