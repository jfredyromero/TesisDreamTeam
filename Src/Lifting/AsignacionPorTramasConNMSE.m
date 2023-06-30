%% Importación de funciones

addpath('../../Utilidades/');
addpath('../../Mediciones/');
addpath('../../Resultados/Lifting/Caracterizacion');


%% Limpieza de variables

clear;
close all;
clc;


%% Cargar datos de los porcentajes

load("porcentajes.mat");


%% Definicion de variables

%---------------------------FAMILIA WAVELET--------------------------------
%fw = "bior2.6";
fw = "db1";
%--------------------------FILTROS LIFTING---------------------------------
lsc = liftingScheme('Wavelet', fw);
%--------------------NÚMERO DE NIVELES DE DESCOMPOSICIÓN-------------------
n = 9; %--> OJO HAY QUE HACER UN FOR EN LA CUANTIFICACIÓN PORQUE NO FUNCIONA EL NUEVO CUANTIFICADOR DESPUES DE  N = 5 (hasta 5 funciona)
%6 dió un mejor resultado
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
tramaDuration = 0.064*(1); % 64 milisegundos
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
coefBits = ones(numTramas, n + 1)' * cama;

aux = totalCoef(:, 1);
for iii = 1:numTramas
    for i = 1:n + 1
        coefBits(i,iii) = length(aux{i}) * coefBits(i,iii);
    end
end

%----------------------PORCENTAJES------------------------------
% porcentajesPercepcion = table2array(porcentajes)';
totalCoefReply = totalCoef;

    for i = 1:numTramas
         totalCoefReply = totalCoef;
        for jjj = 1:n+1
            totalCoefReply{jjj, i} = zeros(length(totalCoefReply{jjj, i}), 1);
            senalReconstCaract(((i - 1) * tramaSamples) + 1:tramaSamples * i) = ilwt(totalCoefReply{n + 1, i}, totalCoefReply(1:n, i), 'LiftingScheme', lsc)'; 
            m2 = medirNMSE(xn(1:length(senalReconstCaract)), senalReconstCaract');
            porcentajesPercepcion(jjj,i)= 1 - m2;
            totalCoefReply = totalCoef;
         end
        porcentajesPercepcion(:,i) = porcentajesPercepcion(:,i) / sum(porcentajesPercepcion(:,i));
    %m1 = medirPESQ(xn(1:length(senalReconstCaract)), senalReconstCaract') / 4.639;

    end



% porcentajesPercepcion(1)= 0.042287166;
% porcentajesPercepcion(2)=0.133418043;
% porcentajesPercepcion(3)=0.182871665;
% porcentajesPercepcion(4)=0.21656925;
% porcentajesPercepcion(5)=0.202897078;
% porcentajesPercepcion(6)=0.118424396;
% porcentajesPercepcion(7)=0.049911055;
% porcentajesPercepcion(8)=0.022465057;
% porcentajesPercepcion(9)=0.012198221;
% porcentajesPercepcion(10)=0.009809403;
% porcentajesPercepcion(11)=0.009148666;
% 
% porcentajesPercepcion = [porcentajesPercepcion(1:length(coefBits) - 1); sum(porcentajesPercepcion(length(coefBits):end))];

%----------CANTIDAD DE BITS ASIGNADOS PARA CADA TRAMA DEL AUDIO------------
bitsAsignadosPerTrama(1,:) = sum(coefBits,1);

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
    disp("ERROR: Se asignaron más bits de los disrcenibles");
    disp("===============================================")
    return;
end

bed= bitsMaximosPerTrama - sum(coefBits);
% Se asignan los bits en base al aporte de energia de cada coeficiente
%----------------------------BLOQUE 1---------------------------------
%AQUI EMPIEZO A ASIGNAR LOS BITS DESDE EL WAVELET MÁS GRANDE HASTA EL MÁS
%CHIQUITO SEGÚN LOS %, POR ALGÚNA RAZON NO SE ASIGNAN TODOS ENTONCES POR
%ESO SE HACE EL BLOQUE 2
% for i = 1:length(aux) 
%     if bitsMaximosPerTrama - sum(coefBits) < length(aux{i,1})
%         break
%     end
%     m = length(aux{i,1}); 
%     valueGroup = bed * Per
% Percepcion(i);
%     coefBits(i) = coefBits(i) + (round(valueGroup/m)*m);
%     bitsRestantesPerTrama = bitsMaximosPerTrama - sum(coefBits);
% end 
%------------------SEGUNDO BLOQUE-------------------------
%COMO SOBRABAN MUCHOS BITS SE REASIGNAN DE TAL MANERA QUE SE LE VAN DANDO
%BITS A LOS COEFICIENTES CON MÁS RELEVANCIA
%coefBits(1)=(length(aux{1,1}))* (log2(q)-4) ;
[valores_ordenados, ubicaciones_ordenadas] = sort(porcentajesPercepcion, 'descend');
contador=1;
totalCoefQuant = cell([n + 1, numTramas]);
  
        %-------------------BITS A UTILIZAR POR CADA MUESTRA-----------------------
        bitsPerMuestra = zeros(n + 1,numTramas );
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
            valueGroup(ppp) = bed(ppp) * porcentajesPercepcion(ubicaciones_ordenadas(iii,ppp));
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
           %totalCoefQuant{qIndex, floor((contador - 1) / (n + 1)) + 1} = cuantUniVNew(totalCoef{contador}, qPerNivelDescomp(qIndex,ppp));
           totalCoefQuant{qIndex, floor((contador - 1) / (n + 1)) + 1} = cuantUniV(totalCoef{contador}, qPerNivelDescomp(qIndex,ppp));
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