% Trabajo de grado para Ingeneria en Electrónica y Telecomunicaciones 
% Universidad del Cauca 
% Dream Team: Jhon Fredy Romero y Lina Virginia Muñoz
% Función para la reparticion de bits inteligente

function coefBits = bitDistributor(coefBits, percentagesPerCoef, tamanosCoeficientes, bitsMaxToDistribute)
    % coefBits es la reparticion inicial de bits por coeficiente y se
    %   modifica a lo largo de la función para retornarse con la 
    %   distribucion final de bits
    % percentagesPerCoef son los porcentajes de bits por cada coeficiente
    % tamanosCoeficientes son los tamaños de cada coeficiente
    % bitsMaxToDistribute es la cantidad de bits máxima por distribuir
    
    %----------CANTIDAD DE BITS ASIGNADOS PARA CADA TRAMA DEL AUDIO------------
    bitsAsignadosPerTrama = sum(coefBits);
    
    %----------CANTIDAD DE BITS RESTANTES PARA CADA TRAMA DEL AUDIO------------
    bitsRestantesPerTrama = bitsMaxToDistribute - bitsAsignadosPerTrama;
    
    if(bitsAsignadosPerTrama > bitsMaxToDistribute)
        error("ERROR: Se asignaron más bits de los disponibles");
    end

    [~, ubicacionesOrdenadas] = sort(percentagesPerCoef, 'descend');

    i = 1; 
    while bitsRestantesPerTrama ~= 0
        % Antes de asignar bits mediante el porcentaje de percepción
        % se verifica si alcanza para el numero de muestras que
        % tiene el coeficiente, sino no se asigna 
        bitsAsignadosPorPorcentaje = bitsRestantesPerTrama * percentagesPerCoef(ubicacionesOrdenadas(i));
        coefSize = tamanosCoeficientes(ubicacionesOrdenadas(i));
        if (ceil(bitsAsignadosPorPorcentaje / coefSize) * coefSize) <= bitsRestantesPerTrama
            coefBits(ubicacionesOrdenadas(i)) = coefBits(ubicacionesOrdenadas(i)) + (ceil(bitsAsignadosPorPorcentaje / coefSize) * coefSize);
            bitsRestantesPerTrama = bitsMaxToDistribute - sum(coefBits);
            i = i + 1;
            if i == length(percentagesPerCoef) + 1
                i = 1;
            end
        % Si no alcanzaron los bits en el punto anterior, entonces se verifica
        % que al menos se le pueda asignar un bit a cada muestra. De ser así,
        % se asignan tantos bits como sea posible por los bits que restan
        elseif bitsRestantesPerTrama >= coefSize
            veces = floor(bitsRestantesPerTrama / coefSize);
            coefBits(ubicacionesOrdenadas(i)) = coefBits(ubicacionesOrdenadas(i)) + coefSize * veces;
            bitsRestantesPerTrama = bitsMaxToDistribute - sum(coefBits);
            i = i + 1;
            if i == length(percentagesPerCoef) + 1
                i = 1;
            end
        else
            valoresCercanos = tamanosCoeficientes(tamanosCoeficientes <= bitsRestantesPerTrama);
            valorMasCercano = max(valoresCercanos);
            indexValorMasCercano = find(tamanosCoeficientes == valorMasCercano);
            coefBits(indexValorMasCercano(1)) = coefBits(indexValorMasCercano(1)) + tamanosCoeficientes(indexValorMasCercano(1));
            bitsRestantesPerTrama = bitsRestantesPerTrama - tamanosCoeficientes(indexValorMasCercano(1));
        end
    end 
end