%Trabajo de grado para la maestría en electrónica y telecomunicaciones 
%Universidad del Cauca 
%Dream Team
%Función para la cuantificación uniforme de una señal

function yc = cuantUniV(y, n)
%y es la señal de entrada a cuantificar 
%n es el número de niveles de cuantificación y debe ser una potencia entera
%de 2 
%yc es la señal cuantificada 
    [minimo, indices] = min(y);
    maximo = max(y);
    delta = (maximo - minimo) / n;
    
    if delta == 0 % Se da cuando solo hay un valor en y
        yc = 0;
        return
    end

    yc = zeros(length(y), 1);
    for i = 1:length(y)
        if mod(y(i), delta) == 0
            yc(i) = y(i) - delta / 2;
        else
            yc(i) = delta * floor(y(i) / delta) + delta / 2;
        end
    end
    
    yc(indices) = minimo + delta / 2; % Se modifica el minimo para que no se excedan la cantidad de niveles de cuantificacion
end