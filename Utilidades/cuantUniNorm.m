%Trabajo de grado para la maestría en electrónica y telecomunicaciones 
%Universidad del Cauca 
%María Manuela Silva Zambrano
%Función para la cuantificación uniforme de una señal

function [yc,C,S]=cuantUniNorm(y,n)
%y es la señal de entrada a cuantificar 
%n es el número de niveles de cuantificación y debe ser una potencia entera
%de 2 
%yc es la señal cuantificada 
    [yn,C,S]=normalize(y,"range"); %valores para poder regresar a la escala original
    yn=2*yn-1;%señal normalizada entre -1 y 1
    delta=2/n;
    %k1=log2(n);
    % yc=zeros(size(yn));
    % for k=-k1:k1
    %     yc=yc+0.5*delta*sign(yn-k*delta);
    % end
    % yc(yc==1)=1-0.5*delta;
    % yc(yc==-1)=-1+0.5*delta;
  
    yc=delta*round(yn/delta)-sign(yn)*delta/2;

end