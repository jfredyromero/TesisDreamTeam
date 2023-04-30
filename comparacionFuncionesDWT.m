addpath('../Grabaciones/');
addpath('../Utilidades/');
addpath('../Mediciones/');
addpath('../Src/Mallat/');
addpath('../Src/Lifting/');

% Limpieza de variables
clear;
close all;

% Cargar datos de los audios previamente almacenados
load("audios.mat");

% fw={'db1', 'db2', 'db3', 'db4', 'db5', 'db6', 'db7', 'db8', 'db9', 'db10', 'db11', 'db12', 'db13', 'db14', 'db15', 'db16', 'db17', 'db18',...
%     'db19', 'db20', 'db21', 'db22', 'db23', 'db24', 'db25', 'db26', 'db27', 'db28', 'db29', 'db30', 'db31', 'db32', 'db33', 'db34', 'db35', 'db36',...
%     'db37', 'db38', 'db39', 'db40', 'db41', 'db42', 'db43', 'db44', 'db45', 'coif1', 'coif2', 'coif3', 'coif4', 'coif5', 'sym2', 'sym3', 'sym4', 'sym5', 'sym6',...
%     'sym7', 'sym8', 'sym9', 'sym10', 'sym11', 'sym12', 'sym13', 'sym14', 'sym15', 'sym16', 'sym17', 'sym18', 'sym19', 'sym20', 'sym21', 'sym22',...
%     'sym23', 'sym24', 'sym25', 'sym26', 'sym27', 'sym28', 'sym29', 'sym30', 'sym31', 'sym32', 'sym33', 'sym34', 'sym35', 'sym36', 'sym37', 'sym38',...
%     'sym39', 'sym40', 'sym41', 'sym42', 'sym43', 'sym44', 'sym45','fk4', 'fk6', 'fk8', 'fk14', 'fk18', 'fk22', 'bl7', 'bl9', 'bl10', 'mb4.2', 'mb8.2',...
%     'mb8.3', 'mb8.4', 'mb10.3', 'mb12.3', 'mb14.3', 'mb16.3', 'mb18.3', 'mb24.3', 'mb32.3', 'beyl', 'vaid', 'han2.3', 'han3.3', 'han4.5', 'han5.5',...
%     'dmey', 'bior1.1', 'bior1.3', 'bior1.5', 'bior2.2', 'bior2.4', 'bior2.6', 'bior2.8', 'bior3.1', 'bior3.3', 'bior3.5', 'bior3.7', 'bior3.9', 'bior4.4',...
%     'bior5.5', 'bior6.8', 'rbio1.1', 'rbio1.3', 'rbio1.5', 'rbio2.2', 'rbio2.4', 'rbio2.6', 'rbio2.8', 'rbio3.1', 'rbio3.3', 'rbio3.5', 'rbio3.7', 'rbio3.9',...
%     'rbio4.4', 'rbio5.5', 'rbio6.8'};

%familias wavelet en común entre Lifting  
fw={'db1', 'db2', 'db3', 'db4', 'db5', 'db6', 'db7', 'db8', 'sym2', 'sym3', 'sym4', 'sym5', 'sym6', 'sym7',...
    'sym8', 'cdf1.1', 'cdf1.3', 'cdf1.5', 'cdf2.2', 'cdf2.4', 'cdf2.6', 'cdf3.1', 'cdf3.3', 'cdf3.5',...
    'cdf4.2', 'cdf4.4', 'cdf4.6', 'cdf5.1', 'cdf5.3', 'cdf5.5', 'cdf6.2', 'cdf6.4', 'cdf6.6', 'coif1',...
    'coif2', 'bior1.1', 'bior1.3', 'bior1.5', 'bior2.2', 'bior2.4', 'bior2.6', 'bior2.8', 'bior3.1',...
    'bior3.3', 'bior3.5', 'bior3.7', 'bior3.9', 'bior4.4', 'bior5.5', 'bior6.8', 'bs3', '9.7', 'rbs3',...
    'r9.7', 'rbio1.1', 'rbio1.3', 'rbio1.5', 'rbio2.2', 'rbio2.4', 'rbio2.6', 'rbio2.8', 'rbio3.1',...
    'rbio3.3', 'rbio3.5', 'rbio3.7', 'rbio3.9', 'rbio4.4', 'rbio5.5', 'rbio6.8'};
%niveles de descomposición
N=10;

%análisis y síntesis con diferentes familias wavelet
%audios1=audios; %audios reconstruidos con funciones propias
%audios2=audios; %audios reconstruidos con funciones de MATLAB
resultados1=cell(numel(fw)*N,3);
%resultados2=cell(numel(fw)*N,3);
it=0;
for ow=1:numel(fw) 
    %[ha,ga,hs,gs]= wfilters(fw{ow});
    lsc= liftingScheme('Wavelet', fw{ow});
    for n=1:N %niveles de descomposición
      it=it+1;
      resultados1{it,1}=num2str(n);
      resultados1{it,2}=fw{ow};
      %resultados2{it,1}=num2str(n);
      %resultados2{it,2}=fw{ow};
      nmse1=zeros(1,numel(audios));
      %nmse2=zeros(1,numel(audios));
      for j=1:numel(audios)  
          x=audios{j};
          f=size(x);
          recon1=zeros(f(1),f(2));
          %recon2=zeros(f(1),f(2)); 
          for i=1:f(1)
              %Mallat
              %[sx1,dxCoef1] = m_dwt(x(i,:),ha,ga,n); 
              [sx1,dxCoef1] = lwt(x(i,:),'LiftingScheme',lsc,'Level', n);
              %[sx2,dxCoef2] = lwt(x(i,:),'LiftingScheme',lsc,'Int2Int',true,'Level', n);
              %[sx2,dxCoef2] = t_dwt(x(i,:),ha,ga,n); 
              %recon1(i,:)= p_idwt(sx1, dxCoef1, hs, gs, n);
              %recon2(i,:)= t_idwt(sx2, dxCoef2, hs, gs, n);
              recon1(i,:) = ilwt(sx1,dxCoef1,'LiftingScheme',lsc,'Level',0);
              %recon2(i,:) = ilwt(sx2,dxCoef2,'LiftingScheme',lsc,'Int2Int',true,'Level',0);
          end
          %audios1{j}=recon1;
          %audios2{j}=recon2;
          nmse1(j) = medirNMSE(x, recon1);
          %nmse2(j) = medirNMSE(x, recon2);
      end
      resultados1{it,3}=mean(nmse1);
      %resultados2{it,3}=mean(nmse2);
      %namefile=['adios_ND' num2str(n) fw{ow} 'MallatP.mat'];
      %save(namefile,'audios1');
      %namefile=['adios_ND' num2str(n) fw{ow} 'MallatT.mat'];
      %save(namefile,'audios2');
    end
end
save("resultadosL.mat","resultados1")
%save("resultadosLI.mat","resultados2")