% Trabajo de grado de Ingeniería en Electrónica y Telecomunicaciones 
% Universidad del Cauca 
% Dream Team: Jhon Fredy Romero y Lina Virginia Muñoz
% Función para la cuantificación de una señal en el dominio Wavelet con el
%   algoritmo de Mallat
function [quantSignal, quality] = quantByPerception(signal, n, q, td, cama, ha, ga, hs, gs)
    % signal es la señal de entrada a cuantificar 
    % n es el número de niveles de descomposición
    % q es el número de niveles de cuantificación
    % td es la duración de cada trama en segundos (0.064, 0.032, 0.016, etc)
    % cama es el número de bits repartidos inicialmente a cada muestra
    % lsc es el objeto usado por la funcion de la transformada donde se
    %   especifica la Wavelet madre en uso

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


    %% Transformada Wavelet con algoritmo Lifting

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


    %% Asignación de bits y niveles de cuantificación

    %---------------------BITS A UTILIZAR POR MUESTRA--------------------------
    bitsPerSample = log2(q);
    %------------------BITS A UTILIZAR POR TRAMA DEL AUDIO---------------------
    bitsMaximosPerTrama = bitsPerSample * tramaSamples;
    %--------------MATRIZ DE BITS ASIGNADOS POR COEFICIENTES-------------------
    coefBits = ones(n + 1, numTramas) * cama;
    %--------------MATRIZ DE TAMAÑO DE CADA GRUPO DE COEFICIENTES--------------
    tamanosCoeficientes = cellfun(@(x) x(1), cellfun(@size, totalCoef(:, 1), 'UniformOutput', false));
    coefBits = tamanosCoeficientes .* coefBits;
    %------------------------------SEÑAL FINAL---------------------------------
    senalReconst = 1:numel(tramas);

    for i = 1:numTramas

        %----------------------PORCENTAJES DE PERCEPCION---------------------------
        porcentajesPercepcion = zeros(n + 1, 1);
        totalCoefCopy = totalCoef;
    
        for j = 1:n + 1
            totalCoefCopy{j, i} = zeros(length(totalCoefCopy{j, i}), 1);
            tramaReconstruida = p_idwt(totalCoefCopy(:, i), hs, gs);
            calidadTrama = medirNMSE(tramas(i, :), tramaReconstruida);
            porcentajesPercepcion(j) = 1 - calidadTrama;
            totalCoefCopy = totalCoef;
        end
    
        porcentajesPercepcion = porcentajesPercepcion / sum(porcentajesPercepcion);
    
        tramaCoefBits = ones(n + 1, 1) * cama;          
        tramaCoefBits = tamanosCoeficientes .* tramaCoefBits;
        
        %----------CANTIDAD DE BITS ASIGNADOS PARA CADA TRAMA DEL AUDIO------------
        bitsAsignadosPerTrama = sum(tramaCoefBits);
    
        % Si se asignan más de (1024 * cama) bits hay un error
        if(bitsAsignadosPerTrama ~=  tramaSamples * cama)
            error("ERROR: Se asignaron como cama más bits de los esperados");
        end

        % Si se asignan más bits de los posibles hay un error
        if(bitsAsignadosPerTrama > bitsMaximosPerTrama)
            error("ERROR: Se asignaron más bits de los disponibles");
        end
    
        % Distribución inteligente de bits para que no sobre ninguno
        tramaCoefBits = bitDistributor(tramaCoefBits, porcentajesPercepcion, tamanosCoeficientes, bitsMaximosPerTrama);
        coefBits(:, i) = tramaCoefBits;
    
        % Si se han asignado más de la totalidad de bits hay un error
        bitsAsignadosPerTrama = sum(tramaCoefBits);
        if(bitsAsignadosPerTrama > bitsMaximosPerTrama)
            error("ERROR: Se asignaron más bits de los disponibles");
        end
    
        %-------------------BITS A UTILIZAR POR CADA MUESTRA-----------------------
        bitsPerMuestra = floor(tramaCoefBits ./ tamanosCoeficientes);
        %----------------------BITS SOBRANTES POR MUESTRA--------------------------
        bitsDesperdiciadosPerNivel = mod(tramaCoefBits, tamanosCoeficientes);
        
        % Si la suma de bits desperdiciados por nivel es mayor a cero significa que
        % no se estan asignando la totalidad de bits.
        if sum(bitsDesperdiciadosPerNivel) ~= 0
            error("ERROR: Se han desperdiciado bits");
        end
    
        %---------------------MATRIZ NIVELES DE CUANTIFICACION---------------------
        qPerNivelDescomp = 2.^(bitsPerMuestra);
    
    
        %% Cuantificación de los coeficientes totales
            
        %---------------MATRIZ DE LOS COEFICIENTES CUANTIFICADOS-------------------
        tramaCoefQuant = cell([n + 1, 1]);
        for j = 1:n + 1
            tramaCoefQuant{j} = cuantUniV(totalCoef{j, i}, qPerNivelDescomp(j));
        end
    
    
        %% Reconstrucción de las tramas y de la señal original
        
        tramaCoefReconst = p_idwt(tramaCoefQuant, hs, gs);
        senalReconst(((i - 1) * tramaSamples) + 1:tramaSamples * i) = tramaCoefReconst;
    end

    pesq = ((medirPESQ(xn(1:length(senalReconst)), senalReconst')) + 0.5) / 5;
    nmse = medirNMSE(xn(1:length(senalReconst)), senalReconst');

    % Variables a retornar
    quantSignal = senalReconst;
    quality = (pesq + nmse) / 2;

end