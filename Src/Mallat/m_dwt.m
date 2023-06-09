function [s,dx] = m_dwt(x, ha, ga, n)
    %p_dwt es una función personalizada para aplicar la DWT sobre un vector
    %x es el vector que equivale a los coeficientes scaling de más alto orden 
    %ha son los coeficientes para representar la función scaling 
    %ga son los coeficientes para representar la función wavlet
    %s es el vector de coeficientes scaling de un orden inferior 
    %w es el vector de coeficientes wavelet de un orden inferieor 
    %dx es la celda con los valores de los coeficientes wavelet

    dx = cell(n,1);
    [s,w] = dwt(x, ha, ga);
    currentSize = 2^floor(log2(length(s)));
    dx{1} = signalCropper(w, currentSize)';
    if n > 1
        for i = 2:n
            [s,w] = dwt(s, ha, ga);  
            currentSize = currentSize/2;
            dx{i} = signalCropper(w, currentSize)';
        end
    end
    s = signalCropper(s, currentSize)';
end
