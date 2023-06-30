function wink2 = promSignal(wink,k)
        wink2 = wink;
        
        %coeficientes scaling 
        scalingScale = wink(2,:);
        scalingScaleMat = cell2mat(scalingScale);
        scalingScaleMat = reshape(scalingScaleMat,2,0.5*length(scalingScaleMat));
        scaling_S = scalingScaleMat(1,:);
        scaling_C = scalingScaleMat(2,:);
        %agrupar en 1/k elementos y promediar 
        
        scaling_S2 = reshape(scaling_S,4,0.25*length(scalingScaleMat));
        scaling_S2 = mean(scaling_S2);
        scaling_S2 = repelem(scaling_S2,1/k);
        
        scaling_C2 = reshape(scaling_C,4,0.25*length(scalingScaleMat));
        scaling_C2 = mean(scaling_C2);
        scaling_C2 = repelem(scaling_C2,1/k);
        
        scalingScaleMat = [scaling_S2' scaling_C2'];
        
        %coeficientes wavelet
        waveletScale = wink(1,:);
        waveletScaleMat = cell2mat(waveletScale);
        waveletScaleMat = reshape(waveletScaleMat,2,0.5*length(waveletScaleMat));
        wavelet_S = waveletScaleMat(1,:);
        wavelet_C = waveletScaleMat(2,:);
        %agrupar en 1/k elementos y promediar 
        
        wavelet_S2 = reshape(wavelet_S,4,0.25*length(waveletScaleMat));
        wavelet_S2 = mean(wavelet_S2);
        wavelet_S2 = repelem(wavelet_S2,1/k);
        
        wavelet_C2 = reshape(wavelet_C,4,0.25*length(waveletScaleMat));
        wavelet_C2 = mean(wavelet_C2);
        wavelet_C2 = repelem(wavelet_C2,1/k);
        
        waveletScaleMat = [wavelet_S2' wavelet_C2'];
        
        for i = 1:length(wink)
            wink2{i,1}=waveletScaleMat(i,:);
            wink2{i,2}=scalingScaleMat(i,:);
        end
end