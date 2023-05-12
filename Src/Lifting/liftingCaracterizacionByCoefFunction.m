% Trabajo de grado de Ingeniería en Electrónica y Telecomunicaciones 
% Universidad del Cauca 
% Dream Team: Jhon Fredy Romero y Lina Virginia Muñoz
% Función para la cuantificación de una señal en el dominio Wavelet con el
%   algoritmo de Lifting
function cuantSignal = liftingCaracterizacionByCoefFunction(x, n, z, lsc)
    % x es la señal de entrada a cuantificar 
    % n es el número de niveles de descomposición
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


    %% Elimino coeficientes :)

    for i = 1:numTramas
        totalCoef{z, i} = zeros(length(totalCoef{z, i}), 1);
    end


    %% Reconstrucción de las tramas y de la señal original

    cuantSignal = 1:numel(tramas);
    for i = 1:numTramas
        cuantSignal(((i - 1) * tramaSamples) + 1:tramaSamples * i) = ilwt(totalCoef{n + 1, i}, totalCoef(1:n, i), 'LiftingScheme', lsc)'; 
    end
end
