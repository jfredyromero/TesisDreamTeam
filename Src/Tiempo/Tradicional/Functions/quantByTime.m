% Trabajo de grado de Ingeniería en Electrónica y Telecomunicaciones 
% Universidad del Cauca 
% Dream Team: Jhon Fredy Romero y Lina Virginia Muñoz
% Función para la cuantificación de una señal en el dominio del tiempo
function [quantSignal, quality] = quantByTime(signal, q, td)
    % signal es la señal de entrada a cuantificar 
    % q es el número de niveles de cuantificación
    % td es la duración de cada trama en segundos (0.064, 0.032, 0.016, etc)

    %% Muestreo de la señal a 16KHz
    
    %-----------------------FACTOR DE MUESTREO Y PERIODO---------------------------
    Fs = 48000;
    %---------------------------FACTOR DE SUBMUESTREO------------------------------
    fsm = 3; % Ya que así se muestreará a una frecuencia de 16KHz --> 48KHz/3
    l = fsm * floor(length(signal) / fsm);
    signal = signal(1:l);
    %---------------------------SEÑAL SUBMUESTREADA------------------------------
    xn = downsample(signal, fsm);
    fs = Fs / fsm;


    %% División de la señal en tramas

    %--------------------LONGITUD DE TRAMA EN MUESTRAS----------------------
    tramaSamples = round(fs * td);
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
    end

    pesq = ((medirPESQ(xn(1:length(senalReconst)), senalReconst')) + 0.5) / 5;
    nmse = medirNMSE(xn(1:length(senalReconst)), senalReconst');

    % Variables a retornar
    quantSignal = senalReconst;
    quality = (pesq + nmse) / 2;

end