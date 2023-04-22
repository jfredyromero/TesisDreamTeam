%Trabajo de grado para la maestría en electrónica y telecomunicaciones 
%Universidad del Cauca 
%María Manuela Silva Zambrano
%Función para la cuantificación uniforme de una señal

function yc=cuantUniV(y,n)
%y es la señal de entrada a cuantificar 
%n es el número de niveles de cuantificación
%yc es la señal cuantificada 
valores=uniquetol(y); %valores de la señal a cuantificar

if length(valores)>n
    %y=y/max(abs(y));
    ma=max(y); %máximo valor de la señal de audio
    mi=min(y); %mínimo valor de la señal de audio 
    rango=ma-mi; %rango dinámico de la señal 
    paso=rango/n;
    p2=paso/2;
    Am=zeros(1,n);
    Am(1)=mi+p2;
    for i=2:n
        Am(i)=Am(i-1)+paso;
    end
    Te=zeros(1,n-1);%valores umbrales para realizar la comparación
    Te(1)=mi+paso;
     for i=2:n-1
        Te(i)=Te(i-1)+paso;
     end
    yc=zeros(length(y),1); 
    yc(y<=Te(1))=Am(1); 
    yc(y>=Te(n-1))=Am(n);
    for i=2: n-1
        yc(y>Te(i-1) & y<=Te(i))=Am(i);
    end
else
    yc=y;
end
end