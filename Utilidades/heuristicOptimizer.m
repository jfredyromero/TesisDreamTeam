% Trabajo de grado para Ingeneria en Electrónica y Telecomunicaciones 
% Universidad del Cauca 
% Dream Team: Jhon Fredy Romero y Lina Virginia Muñoz
% Función para la reparticion de bits inteligente

function [coefBits, maxCalidadAlcanzada, bestSignal] = heuristicOptimizer(coefBits, percentagesPerCoef, tamanosCoeficientes, totalCoef, maxCalidadAlcanzada, currentBestSignal, lsc, originalSignal)
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
    [~, numTramas] = size(totalCoef);
    tramaSamples = sum(tamanosCoeficientes);
    totalCoefQuant = cell([n + 1, numTramas]);
    calidad = maxCalidadAlcanzada;
    bestSignal = currentBestSignal;
    
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
                
                for k = 1:numTramas * (n + 1)
                    if mod(k, n + 1) == 0
                        qIndex = n + 1;
                    else
                        qIndex = mod(k, n + 1);
                    end
                    totalCoefQuant{qIndex, floor((k - 1) / (n + 1)) + 1} = cuantUniV(totalCoef{k}, qPerNivelDescomp(qIndex));
                end

                for k = 1:numTramas
                    senalReconst(((k - 1) * tramaSamples) + 1:tramaSamples * k) = ilwt(totalCoefQuant{n + 1, k}, totalCoefQuant(1:n, k), 'LiftingScheme', lsc)'; 
                end

                pesq = ((medirPESQ(originalSignal, senalReconst')) + 0.5) / 5;
                nmse = medirNMSE(originalSignal, senalReconst');
                calidad = (pesq + nmse) / 2;

                if calidad > maxCalidadAlcanzada
                    coefBits = newCoefBits;
                    maxCalidadAlcanzada = calidad
                    bestSignal = senalReconst;
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