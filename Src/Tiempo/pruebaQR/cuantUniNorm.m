function [yc,C,S]=cuantUniNorm(y,n)
%y es la señal de entrada a cuantificar 
%n es el número de niveles de cuantificación y debe ser una potencia entera
%de 2 
%yc es la señal cuantificada 
    [yn,C,S]=normalize(y,"range"); %valores para poder regresar a la escala original
    yn=2*yn-1;%señal normalizada entre -1 y 1
    delta=2/n;
  
    yc=delta*round(yn/delta)-sign(yn)*delta/2;

end