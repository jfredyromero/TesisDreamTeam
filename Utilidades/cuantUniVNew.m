%Trabajo de grado para la maestría en electrónica y telecomunicaciones 
%Universidad del Cauca 
%María Manuela Silva Zambrano
%Función para la cuantificación uniforme de una señal

function yc = cuantUniVNew(y, n)
%y es la señal de entrada a cuantificar 
%n es el número de niveles de cuantificación y debe ser una potencia entera
%de 2 
%yc es la señal cuantificada 
    minimo= min(y);
    maximo= max(y);
    diferencia= maximo-minimo;
    escalon = diferencia/n;
%    % if n == 2
%         partition = [minimo,maximo];
%         codebook = minimo+escalon;
%         
%     else
        partition = minimo+escalon:escalon:maximo-escalon;
        codebook = minimo+0.5*(escalon):escalon:maximo-0.5*(escalon);
        % Now optimize, using codebook as an initial guess.
        [partition2,codebook2] = lloyds(y,codebook);
        [index,quants,distor] = quantiz(y,partition,codebook);
        [index2,quant2,distor2] = quantiz(y,partition2,codebook2);
        yc = quants';
%     end

    
    

end
