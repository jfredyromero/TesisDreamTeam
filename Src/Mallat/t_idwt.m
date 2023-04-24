function recx = t_idwt(s, w, hs, gs, n)
    %p_idwt es una función personalizada para aplicar la IDWT sobre un vector
    %hs son los coeficientes para representar la función scaling 
    %gs son los coeficientes para representar la función wavlet
    %s es el vector de coeficientes scaling de más bajo orden 
    %w es el vector de coeficientes wavelet de más bajo orden 
    %recx es el vector de coeficientes scaling de un orden superior
    
    %dado que la IDWT es un algoritmo iterativo recursivo, esta función
    %deberá llamarse por cada nivel de descomposición implementado
    if  iscolumn(s)
        s=s;  
    else
        s=s'; 
    end
    for i=n:-1:1
        s=signalCropper(s,i);
        w{i}=signalCropper(w{i},i);
        s = idwt(s,w{i},hs,gs);
        %s=signalCropper(s);
         if  iscolumn(s)
            s=s;  
        else
            s=s'; 
        end
    end
    if length(s)~=1024
        recx=signalCropper(s,0);       
    else
        recx=s;
    end

end