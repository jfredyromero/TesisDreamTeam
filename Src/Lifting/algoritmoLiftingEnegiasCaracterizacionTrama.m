%% Importación de funciones

addpath('../../Utilidades/');
addpath('../../Mediciones/');


%% Limpieza de variables

clear;
close all;


%% Definicion de variables

%---------------------------FAMILIA WAVELET--------------------------------
fw = "db7";
%--------------------------FILTROS LIFTING---------------------------------
lsc = liftingScheme('Wavelet', fw);
%--------------------NÚMERO DE NIVELES DE DESCOMPOSICIÓN-------------------
n = 3;
%--------------------NÚMERO DE NIVELES DE CUANTIFICACIÓN-------------------
q = 8;
%--------------------CAMA INICIAL DE BITS POR MUESTRA----------------------
cama = log2(q)-1;


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
tramaDuration = 0.064*(1/2); % 64 milisegundos
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

totalEnergia = sum(energiaCoef);  %ENERGÍA POR CADA TRAMA


%% Asignación de bits y niveles de cuantificación

%---------------------BITS A UTILIZAR POR MUESTRA--------------------------
bitsPerSample = log2(q);
%------------------BITS A UTILIZAR POR TRAMA DEL AUDIO---------------------
bitsMaximosPerTrama = bitsPerSample * tramaSamples; 
%----------------------PORCENTAJES DE ENERGÍA------------------------------
porcentajesEnergia = energiaCoef ./ totalEnergia;
%--------------MATRIZ DE BITS ASIGNADOS POR COEFICIENTES-------------------
coefBits = ones(numTramas, n + 1)' * cama;

aux = totalCoef(:, 1);
for iii = 1:numTramas
    for i = 1:n + 1
        coefBits(i,iii) = length(aux{i}) * coefBits(i,iii);
    end
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

if(bitsAsignadosPerTrama > bitsMaximosPerTrama)
    disp("===============================================")
    disp("ERROR: Se asignaron más bits de los disponibles");
    disp("===============================================")
    return;
end

% Se asignan los bits en base al aporte de energia de cada coeficiente
%coefBits = coefBits + floor(bitsRestantesPerTrama .* porcentajesEnergia);

% Si se han asignado más de la totalidad de bits hay un error
bitsAsignadosPerTrama = sum(coefBits);
bitsDesperdiciadosPerTrama = bitsMaximosPerTrama - bitsAsignadosPerTrama;
if(bitsAsignadosPerTrama > bitsMaximosPerTrama)
    disp("===============================================")
    disp("ERROR: Se asignaron más bits de los disponibles");
    disp("===============================================")
    return;
end

bed= bitsMaximosPerTrama - sum(coefBits);
[valores_ordenados, ubicaciones_ordenadas] = sort(porcentajesEnergia, 'descend');
contador=1;
totalCoefQuant = cell([n + 1, numTramas]);
for ppp = 1: numTramas
        flagValue = false; 
        if sum(coefBits(:,ppp)) < bitsMaximosPerTrama
            flagValue = true; 
        end
        iii=1; 
        while flagValue
            %antes de asignar se verifica si alcanza para el numero de muestras que
            %tiene el coeficiente, sino no se asigna 
            m = length(aux{ubicaciones_ordenadas(iii,ppp),1});
            valueGroup(ppp) = bed(ppp) * porcentajesEnergia(ubicaciones_ordenadas(iii,ppp));
            if (ceil(valueGroup(ppp)/m)*m)<= bitsMaximosPerTrama-sum(coefBits(:,ppp))
                coefBits(ubicaciones_ordenadas(iii,ppp),ppp) = coefBits(ubicaciones_ordenadas(iii,ppp),ppp) + (ceil(valueGroup(ppp)/m)*m);
                bitsRestantesPerTrama(ppp) = bitsMaximosPerTrama - sum(coefBits(:,ppp));
                iii=iii+1;
                if iii==n+2
                    iii=1;
                end
        
            elseif bitsMaximosPerTrama-sum(coefBits(:,ppp))>=length(aux{ubicaciones_ordenadas(iii,ppp),1})
                veces = floor((bitsMaximosPerTrama-sum(coefBits(:,ppp)))/(length(aux{ubicaciones_ordenadas(iii,ppp),1})));
                coefBits(ubicaciones_ordenadas(iii,ppp),ppp) = coefBits(ubicaciones_ordenadas(iii,ppp),ppp) + length(aux{ubicaciones_ordenadas(iii,ppp),1})*veces;
                bitsRestantesPerTrama(ppp) = bitsMaximosPerTrama - sum(coefBits(:,ppp));
                iii=iii+1;
                if iii==n+2
                    iii=1;
                end
        %---------------------------TERCER BLOQUE-----------------
        %Asignación de ultimos bits 
            elseif ((bitsMaximosPerTrama-sum(coefBits(:,ppp)) > 0) && bitsMaximosPerTrama-sum(coefBits(:,ppp))<length(aux{ubicaciones_ordenadas(iii,ppp),1}))
                search = bitsMaximosPerTrama-sum(coefBits(:,ppp));
                tamanos_celdas = cellfun(@(x) x(1), cellfun(@size, aux, 'UniformOutput', false));
                valores_cercanos = tamanos_celdas(tamanos_celdas <= search);
                valor_cercano = max(valores_cercanos);
                location = find(tamanos_celdas == valor_cercano);
                coefBits(location(1),ppp) = coefBits(location(1),ppp) + length(aux{location(1),1});
                bitsRestantesPerTrama(ppp)= bitsMaximosPerTrama - sum(coefBits(:,ppp));
            else
                flagValue=false;
            end
        end 
        
        % Si se han asignado más de la totalidad de bits hay un error
        bitsAsignadosPerTrama = sum(coefBits(:,ppp));
        bitsDesperdiciadosPerTrama = bitsMaximosPerTrama - bitsAsignadosPerTrama;
        if(bitsAsignadosPerTrama > bitsMaximosPerTrama)
            disp("===============================================")
            disp("ERROR: Se asignaron más bits de los disponibles");
            disp("===============================================")
            return;
        end
        
        %-------------------BITS A UTILIZAR POR CADA MUESTRA-----------------------
        bitsPerMuestra = zeros(n + 1,numTramas );
        %----------------------BITS SOBRANTES POR MUESTRA--------------------------
        bitsDesperdiciadosPerNivel = zeros(n + 1, numTramas);
        for i = 1:n + 1
            bitsPerMuestra(i,ppp) = floor(coefBits(i,ppp) / length(aux{i}));
            bitsDesperdiciadosPerNivel(i,ppp) = mod(coefBits(i,ppp), length(aux{i}));
        end
        
        %---------------------MATRIZ NIVELES DE CUANTIFICACION---------------------
        qPerNivelDescomp = 2.^(bitsPerMuestra);
        
        
        %% Cálculo de bits usados y desperdiciados por trama
        
        bitsDesperdiciadosPerTrama = bitsDesperdiciadosPerTrama + sum(bitsDesperdiciadosPerNivel(:,ppp));
        bitsUsadosPerNivel = coefBits(:,ppp) - bitsDesperdiciadosPerNivel(:,ppp);
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
        
        % %---------------MATRIZ DE LOS COEFICIENTES CUANTIFICADOS-------------------
       
        for i = 1:n+1
            if mod(contador, n + 1) == 0
                qIndex = n + 1;
            else
                qIndex = mod(contador, n + 1);
            end
            totalCoefQuant{qIndex, floor((contador - 1) / (n + 1)) + 1} = cuantUniVNew(totalCoef{contador}, qPerNivelDescomp(qIndex,ppp));
           %totalCoefQuant{qIndex, floor((contador - 1) / (n + 1)) + 1} = cuantUniV(totalCoef{contador}, qPerNivelDescomp(qIndex,ppp));
            contador=contador+1;
        end
end

%% Reconstrucción de las tramas y de la señal original

senalReconst = 1:numel(tramas);
for i = 1:numTramas
    senalReconst(((i - 1) * tramaSamples) + 1:tramaSamples * i) = ilwt(totalCoefQuant{n + 1, i}, totalCoefQuant(1:n, i), 'LiftingScheme', lsc)'; 
end

pesq = ((medirPESQ(xn(1:length(senalReconst)), senalReconst'))+0.5)/5;
nmse = medirNMSE(xn(1:length(senalReconst)), senalReconst');
(pesq + nmse) / 2


%% Reproducción de la señal reconstruida

sound(senalReconst, fs);