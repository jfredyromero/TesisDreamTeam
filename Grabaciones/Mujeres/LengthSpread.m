%varianza vs longitud de trama 
clear
close all
%% Definicion de variables

%---------------------------FAMILIA WAVELET--------------------------------
fw = "db7";
%--------------------------FILTROS LIFTING---------------------------------
%lsc =customLiftingScheme(fw);
lsc = liftingScheme('Wavelet', fw);
%--------------------NÚMERO DE NIVELES DE DESCOMPOSICIÓN-------------------
n = 1;


%% lectura de los archivos de audio
[x,Fs]=audioread("Veronica Lopez/9. Veronica Lopez.m4a");

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
scalingSpread = zeros(1,9);
waveletSpread = zeros(1,9);

for kk = 0:8
        %--------------------LONGITUD DE TRAMA EN SEGUNDOS----------------------
        k=1/(2^kk);
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
        
        % dispersión coeficientes
        varScaling = zeros(1,numTramas);
        varWavelet = zeros(1,numTramas);
        meanScaling = zeros(1,numTramas);
        meanWavelet = zeros(1,numTramas);
        maxScaling = zeros(1,numTramas);
        maxWavelet = zeros(1,numTramas);
        minScaling = zeros(1,numTramas);
        minWavelet = zeros(1,numTramas);

        for i = 1:numTramas
            varScaling(i) = var(totalCoef{2,i});
            meanScaling(i) = mean(totalCoef{2,i});
            maxScaling(i) = max(totalCoef{2,i});
            minScaling(i) = min(totalCoef{2,i});
            varWavelet(i) = var(totalCoef{1,i});
            meanWavelet(i) = mean(totalCoef{1,i});
            maxWavelet(i) = max(totalCoef{1,i});
            minWavelet(i) = min(totalCoef{1,i});
        end
        % scalingSpread(kk+1) = mean(varScaling./abs(meanScaling));
        % waveletSpread(kk+1) = mean(varWavelet./abs(meanWavelet));
        % scalingSpread(kk+1) = mean((maxScaling-minScaling)./varScaling);
        % waveletSpread(kk+1) = mean((maxWavelet-minWavelet)./varWavelet);
        scalingSpread(kk+1) = mean((maxScaling-minScaling));
        waveletSpread(kk+1) = mean((maxWavelet-minWavelet));
end

kk=0:8;
k=ones(1,numel(kk))./(2.^kk);
figure, 
plot(k,waveletSpread,k,scalingSpread,'LineWidth',2), grid minor
legend('dispersión wavelet', 'dispersión scaling')
set(gcf,'color','w');
