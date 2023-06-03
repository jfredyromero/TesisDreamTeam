
clear;
close all;

%--------------------NÚMERO DE NIVELES DE CUANTIFICACIÓN-----------------
q =8;
 
%-----------------------LECTURA DE SEÑAL DE VOZ--------------------------
[x,Fs] = audioread('8.Veronica.m4a');
Ts = 1/Fs;

%factor de submuestreo
k=3; %ya que así se muestreará a una frecuencia de 16KHz --> 41KHz/3
%para solucionar problemas de longitud de vectores
L=k*floor(length(x)/k);
x=x(1:L);
%muestreo
xn=downsample(x,k);
fs=Fs/k;
t=0:Ts:length(x)/fs - Ts;
%-------------------DIVISIÓN DE LA SEÑAL EN TRAMAS
% Longitud de cada trama (en muestras)
trama_len = round(fs * (0.064/2));

% Número de tramas
num_tramas = floor(length(xn) / trama_len);

% Inicializa la matriz de tramas
tramas = zeros(num_tramas, trama_len);

% Divide el audio en tramas
for i = 1:num_tramas
    inicio = (i-1)*trama_len + 1;
    fin = i*trama_len;
    tramas(i,:) = xn(inicio:fin);
end

%Cuantificación

for k = 1:num_tramas 
    minimo= min(tramas(k,:));
    maximo= max(tramas(k,:));
    diferencia= maximo-minimo;
    escalon = diferencia/q;
    
    partition = minimo+escalon:escalon:maximo-escalon;
    codebook = minimo+0.5*(escalon):escalon:maximo-0.5*(escalon);
    % Now optimize, using codebook as an initial guess.
    [partition2,codebook2] = lloyds(tramas(k,:),codebook);
    [index,quants,distor] = quantiz(tramas(k,:),partition,codebook);
    [index2,quant2,distor2] = quantiz(tramas(k,:),partition2,codebook2);
    valQuantiz(k,:) = quants;
    valQuantiz2(k,:) = quant2;
end
%----------------CALCULO NÚMERO DE BITS MÁXIMOS UTILIZAR-------------------
bpm = log2(q);
bitsUsados = bpm * trama_len; 

% .RECONSTRUCCIÓN 
final=[];
final2=[];
for i = 1:num_tramas
    final = [final valQuantiz(i,:)];
    final2 = [final2 valQuantiz2(i,:)];
end 
% REPRODUCCIÓN
sound(final,fs);
