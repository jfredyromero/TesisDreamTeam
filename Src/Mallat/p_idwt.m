%Trabajo de grado para la maestría en electrónica y telecomunicaciones 
%Universidad del Cauca 
%María Manuela Silva Zambrano

function recx = p_idwt(coefQuant, hs, gs)
    %p_idwt es una función personalizada para aplicar la IDWT sobre un vector
    %hs son los coeficientes para representar la función scaling 
    %gs son los coeficientes para representar la función wavlet
    %s es el vector de coeficientes scaling de más bajo orden 
    %w es el vector de coeficientes wavelet de más bajo orden 
    %recx es el vector de coeficientes scaling de un orden superior
    
    lastScalingCoef = coefQuant{end}';    
    for j = 1:length(coefQuant) - 1
        lastWaveletCoef = coefQuant{end - j}';
        currentSize = length(lastWaveletCoef) * 2;
        lastScalingCoef = conv(gs, upsample(lastWaveletCoef, 2)) + conv(hs, upsample(lastScalingCoef, 2));
        lastScalingCoef = signalCropper(lastScalingCoef, currentSize);
    end
    recx = lastScalingCoef;
end