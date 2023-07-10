% Trabajo de grado para Ingeneria en Electrónica y Telecomunicaciones 
% Universidad del Cauca 
% Dream Team: Jhon Fredy Romero y Lina Virginia Muñoz
% Función para la reparticion de bits inteligente

function [coefBits, maxCalidadAlcanzada, bestTrama] = heuristicOptimizerPerTrama(coefBits, percentagesPerCoef, tamanosCoeficientes, totalCoef, maxCalidadAlcanzada, currentBestTrama, lsc, tramaOriginal)
    % coefBits es la reparticion inicial de bits por coeficiente y se
    %   modifica a lo largo de la función para retornarse con la mejor
    %   distribucion de bits
    % percentagesPerCoef son los porcentajes de bits por cada coeficiente
    % tamanosCoeficientes son los tamaños de cada coeficiente
    % totalCoef es una matriz que contiene todos los coeficientes de la señal
    % maxCalidadAlcanzada es la mejor calidad alcanzada hasta el momento
    % currentBestSignal es la mejor señal lograda hasta el momento
    % lsc es el objeto con los filtros correspondientes a la familia
    %   wavelet en uso
    % originalSignal es la señal original contra la que se va a comparar

    n = length(percentagesPerCoef) - 1;
    [~, ubicacionesOrdenadas] = sort(percentagesPerCoef, 'descend');
    calidad = maxCalidadAlcanzada;
    bestTrama = currentBestTrama;
    
    for i = 1:n + 1
        j = 1;
        while calidad >= maxCalidadAlcanzada
            coefSizePorAumentar = tamanosCoeficientes(ubicacionesOrdenadas(i));
            coefSizePorDisminuir = tamanosCoeficientes(ubicacionesOrdenadas(end + 1 - j));

            if  coefBits(ubicacionesOrdenadas(end + 1 - j)) >= coefSizePorAumentar && ubicacionesOrdenadas(i) ~= ubicacionesOrdenadas(end + 1 - j)
                newCoefBits = coefBits;

                if coefSizePorAumentar >= coefSizePorDisminuir                    
                    newCoefBits(ubicacionesOrdenadas(i)) = coefBits(ubicacionesOrdenadas(i)) + coefSizePorAumentar;
                    newCoefBits(ubicacionesOrdenadas(end + 1 - j)) = coefBits(ubicacionesOrdenadas(end + 1 - j)) - coefSizePorAumentar; 
                else
                    newCoefBits(ubicacionesOrdenadas(i)) = coefBits(ubicacionesOrdenadas(i)) + coefSizePorDisminuir;
                    newCoefBits(ubicacionesOrdenadas(end + 1 - j)) = coefBits(ubicacionesOrdenadas(end + 1 - j)) - coefSizePorDisminuir;
                end

                bitsPerMuestra = floor(newCoefBits ./ tamanosCoeficientes);
                bitsDesperdiciadosPerNivel = mod(newCoefBits, tamanosCoeficientes);

                % Si la suma de bits desperdiciados por nivel es mayor a cero significa que
                % no se estan asignando la totalidad de bits.
                if sum(bitsDesperdiciadosPerNivel) ~= 0
                    error("ERROR: Se han desperdiciado bits");
                end

                qPerNivelDescomp = 2.^(bitsPerMuestra);


                %% Cuantificación de los coeficientes totales
        
                %---------------MATRIZ DE LOS COEFICIENTES CUANTIFICADOS-------------------
                tramaCoefQuant = cell([n + 1, 1]);
                for k = 1:n + 1
                    tramaCoefQuant{k} = cuantUniV(totalCoef{k}, qPerNivelDescomp(k));
                end

                %% Reconstrucción de la trama
    
                tramaCoefReconst = ilwt(tramaCoefQuant{n + 1}, tramaCoefQuant(1:n), 'LiftingScheme', lsc)'; 
                calidad = medirNMSE(tramaOriginal, tramaCoefReconst);

                if calidad > maxCalidadAlcanzada
                    coefBits = newCoefBits;
                    maxCalidadAlcanzada = calidad;
                else
                    j = j + 1;
                    calidad = maxCalidadAlcanzada;
                end
            else
                j = j + 1;
            end

            if j == n + 2
                break;
            end
        end
    end
end