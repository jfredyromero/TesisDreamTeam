%Trabajo de grado para la maestría en electrónica y telecomunicaciones 
%Universidad del Cauca 
%María Manuela Silva Zambrano

function recx = p_idwt(s, w, hs, gs)
    %p_idwt es una función personalizada para aplicar la IDWT sobre un vector
    %hs son los coeficientes para representar la función scaling 
    %gs son los coeficientes para representar la función wavlet
    %s es el vector de coeficientes scaling de más bajo orden 
    %w es el vector de coeficientes wavelet de más bajo orden 
    %recx es el vector de coeficientes scaling de un orden superior
    
    %dado que la IDWT es un algoritmo iterativo recursivo, esta función
    %deberá llamarse por cada nivel de descomposición implementado
        
    fix = length(w) - length(s); %en caso de que existan diferencias en las longitudes de los coeficientes
    if fix < 0
        w = [w; zeros(1, fix)];
    elseif fix > 0
        s = [s; zeros(1, fix)];
    end
    recx = conv(gs, upsample(w, 2)) + conv(hs, upsample(s, 2));
    recx = signalCropper(recx);
end