% Trabajo de grado de Ingeniería en Electrónica y Telecomunicaciones 
% Universidad del Cauca 
% Dream Team: Jhon Fredy Romero y Lina Virginia Muñoz
% Función para la cuantificación de una señal en el dominio Wavelet con el
%   algoritmo de Lifting
function [cuantSignal, bitsUsados, bitsDesperdiciados] = algoritmoLifting(x, n, q, lsc)
    % x es la señal de entrada a cuantificar 
    % n es el número de niveles de descomposición
    % q es el número de niveles de cuantificación
    % lsc es el objeto usado por la funcion de la transformada donde se
    %   especifica la Wavelet madre en uso

    %% Muestreo de la señal a 16KHz
    
    %-----------------------FACTOR DE MUESTREO Y PERIODO---------------------------
    Fs = 48000;
    %---------------------------FACTOR DE SUBMUESTREO------------------------------
    fsm = 3; % Ya que así se muestreará a una frecuencia de 16KHz --> 48KHz/3
    l = fsm * floor(length(x) / fsm);
    x = x(1:l);
    %---------------------------SEÑAL SUBMUESTREADA------------------------------
    xn = downsample(x, fsm);
    fs = Fs/fsm;

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

    %% Transformada Wavelet con esquema Lifting

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
        energiaCoef(indexX, floor((i - 1) / (n + 1)) + 1) = (1 / length(totalCoef{i})) * sum(totalCoef{i}.^2);
    end
    promedioEnergia = (1/numTramas) * sum(energiaCoef, 2);
    totalEnergia = sum(promedioEnergia);

    %% Asignación de bits y niveles de cuantificación

    %---------------------BITS A UTILIZAR POR MUESTRA--------------------------
    bitsPerSample = log2(q);
    %------------------BITS A UTILIZAR POR TODO EL AUDIO-----------------------
    bitsMaximosPerTrama = bitsPerSample * tramaSamples; 
    %----------------------PORCENTAJES DE ENERGÍA------------------------------
    porcentajesEnergia = promedioEnergia / totalEnergia;
    %--------------MATRIZ DE BITS ASIGNADOS POR COEFICIENTES-------------------
    coefBits = ones(1, n + 1)';
    %-------MATRIZ NIVELES DE CUANTIFICACION POR NIVEL DE DESCOMPOSICIÓN-------
    qPerNivelDescomp = ones(1, n + 1)';
    %---------------------CANTIDAD DE BITS ASIGNADOS---------------------------
    bitsAsignados = 0;
    % Se itera en los niveles de descomposición
    for i = 1:n
        % Se agrega un bit por cada coeficiente Wavelet de cada nivel de una
        % trama
        bitsAsignados = bitsAsignados + length(tramaWaveletCoef{i});
    end
    % Se agrega un bit por cada coeficiente Scaling de una trama
    bitsAsignados = bitsAsignados + length(tramaScalingCoef);
    % La suma anterior siempre va a ser equivalente al número de muestras de
    % una trama
    %---------------------CANTIDAD DE BITS RESTANTES---------------------------
    bitsRestantesPerTrama = bitsMaximosPerTrama - bitsAsignados;
    %-----------------BITS PARA CADA NIVEL DE DESCOMPOSICIÓN-------------------
    bitsPerNivelDescomp = round(bitsRestantesPerTrama * porcentajesEnergia);
    %------------------BITS PARA COEFICIENTES WAVELET--------------------------
    for i = 1:n
        coefBits(i) = coefBits(i) + floor(bitsPerNivelDescomp(i) / length(tramaWaveletCoef{i}));
        qPerNivelDescomp(i) = 2^(coefBits(i));
    end
    %------------------BITS PARA COEFICIENTES SCALING--------------------------
    coefBits(end) = coefBits(end) + floor(bitsPerNivelDescomp(end) / length(tramaScalingCoef));
    qPerNivelDescomp(end) = 2^(coefBits(end));

    %% Cálculo de bits usados y desperdiciados por trama

    bitsUsados = 0;
    for i = 1:n
        bitsUsados = bitsUsados + coefBits(i) * length(tramaWaveletCoef{i});
    end
    bitsUsados = bitsUsados + length(tramaScalingCoef) * coefBits(end);
    bitsDesperdiciados = bitsMaximosPerTrama - bitsUsados;

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
    cuantSignal = 1:numel(tramas);
    for i = 1:numTramas
        cuantSignal(((i - 1) * tramaSamples) + 1:tramaSamples * i) = ilwt(totalCoefQuant{n + 1, i}, totalCoefQuant(1:n, i), 'LiftingScheme', lsc)'; 
    end
end
