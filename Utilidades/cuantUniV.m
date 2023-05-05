%Trabajo de grado para la maestría en electrónica y telecomunicaciones 
%Universidad del Cauca 
%María Manuela Silva Zambrano
%Función para la cuantificación uniforme de una señal

function yc = cuantUniV(y, n)
%y es la señal de entrada a cuantificar 
%n es el número de niveles de cuantificación y debe ser una potencia entera
%de 2 
%yc es la señal cuantificada 
    [senalNormalized, C, S] = normalize(y, "range");
    senalMoved = 2 * senalNormalized - 1; % señal normalizada entre -1 y 1
    delta = 2/n;
    senalQuantified = delta * round(senalMoved / delta) - sign(senalMoved) * delta / 2;
    senalQuantifiedNormalized = (senalQuantified + 1) / 2; % señal cuantificada y normalizada entre 0 y 1
    yc = senalQuantifiedNormalized * S + C;
end