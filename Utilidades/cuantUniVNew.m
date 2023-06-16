%Trabajo de grado para la maestría en electrónica y telecomunicaciones 
%Universidad del Cauca 
%María Manuela Silva Zambrano
%Función para la cuantificación uniforme de una señal

function yc = cuantUniVNew(y, n)
%y es la señal de entrada a cuantificar 
%n es el número de niveles de cuantificación y debe ser una potencia entera
%de 2 
%yc es la señal cuantificada 
    minimo = min(y);
    maximo = max(y);
    diferencia = maximo - minimo;
    escalon = diferencia / n;
    if n == 2
        partition = minimo + escalon;
        codebook = [minimo, maximo];        
    else
        partition = minimo + escalon:escalon:(minimo + (escalon * (n - 1)));
        codebook = minimo + 0.5 * (escalon):escalon:(minimo + (escalon * (n - 1)) + 0.5 * escalon);
    end
    if isempty(partition) 
        partition = 0 ; 
        codebook = [0, 0];
    end 
    [index, quants, distor] = quantiz(y, partition, codebook);
    yc = quants'; 
end
