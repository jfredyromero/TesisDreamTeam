%Trabajo de grado para la maestría en electrónica y telecomunicaciones 
%Universidad del Cauca 
%María Manuela Silva Zambrano

function recx = p_idwt(s, w, hs, gs, n)
    %p_idwt es una función personalizada para aplicar la IDWT sobre un vector
    %hs son los coeficientes para representar la función scaling 
    %gs son los coeficientes para representar la función wavlet
    %s es el vector de coeficientes scaling de más bajo orden 
    %w es el vector de coeficientes wavelet de más bajo orden 
    %recx es el vector de coeficientes scaling de un orden superior
    
    %dado que la IDWT es un algoritmo iterativo recursivo, esta función
    %deberá llamarse por cada nivel de descomposición implementado
     
    %en este código se tiene que la longitud de las tramas es de 1024
    %muestras 

    for i=n:-1:1
        fix = length(w{i}) - length(s); %en caso de que existan diferencias en las longitudes de los coeficientes
        if fix < 0
            w{i} = [w{i} zeros(1, abs(fix))];
        elseif fix > 0
            s = [s zeros(1, fix)];
        end
        s = conv(gs, upsample(w{i}, 2)) + conv(hs, upsample(s, 2));
    end
    recx=s;
    %recx = signalCropper(recx);
     if length(recx)==1025
        recx=recx(2:end);
     else
        L=length(recx)-1024;
        if L>0
            recx=recx(floor(0.5*L)+1:floor(0.5*L)+1024); %se recordan las 2L-1 muestras que agrega el proceso de convolución
        end
     end
    p=1;
end