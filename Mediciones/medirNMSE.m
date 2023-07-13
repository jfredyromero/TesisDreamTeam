% Trabajo de grado de Ingeniería en Electrónica y Telecomunicaciones 
% Universidad del Cauca 
% Dream Team: Jhon Fredy Romero y Lina Virginia Muñoz
% Función para el calculo de la medida objetiva NMSE
function nmse = medirNMSE(originalSignal, processedSignal)
    % originalSignal es la señal original
    % processedSignal es la señal procesada
    originalSignal = originalSignal/max(abs(originalSignal));
    processedSignal = processedSignal/max(abs(processedSignal));
    
    numerator = sum((originalSignal - processedSignal).^2);
    denominator = sum(originalSignal.^2);

    nmse = 1 - (0.5 * sqrt(numerator / denominator));
end