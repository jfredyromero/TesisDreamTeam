% Trabajo de grado de Ingeniería en Electrónica y Telecomunicaciones 
% Universidad del Cauca 
% Dream Team: Jhon Fredy Romero y Lina Virginia Muñoz
% Función para el calculo de la medida objetiva PESQ
function pesq = medirPESQ(originalSignal, processedSignal)
    % originalSignal es la señal original
    % processedSignal es la señal procesada
    
    a0 = 4.5;
    a1 = -0.1;
    a2 = -0.0309;
    
    d_sym = calculate_distortion_sym(originalSignal, processedSignal);
    d_asym = calculate_distortion_asym(originalSignal, processedSignal);
    
    pesq = a0 + a1 * d_sym + a2 * d_asym;
end

function d_sym = calculate_distortion_sym(originalSignal, processedSignal)
    d = originalSignal - processedSignal;
    d_sym = sum(d.^2) / sum(originalSignal.^2);
end

function d_asym = calculate_distortion_asym(originalSignal, processedSignal)
    % Cálculo de la distorsión asimétrica
  
    d = originalSignal - processedSignal;
    d_asym = sum(abs(d)) / sum(abs(originalSignal));
end