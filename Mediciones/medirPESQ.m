% Trabajo de grado de Ingeniería en Electrónica y Telecomunicaciones 
% Universidad del Cauca 
% Dream Team: Jhon Fredy Romero y Lina Virginia Muñoz
% Función para el calculo de la medida objetiva PESQ
% Author: Jacob Donley
% University of Wollongong
% Email: jrd089@uowmail.edu.au
% Copyright: Jacob Donley 2017
% Date: 2 August 2017
% Revision: 0.3 (2 August 2017)
% Revision: 0.2 (16 June 2016)
function pesq = medirPESQ(originalSignal, processedSignal)
    % originalSignal es la señal original
    % processedSignal es la señal procesada
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Just incase this function tries to call within a class folder we should 
    % create a function handle for this function to use instead
    infun = dbstack('-completenames');
    funcName = 'PESQ_MEX';
    funcPath = infun.file;
    classDirs = getClassDirs(funcPath);
    pesq_mex_ = str2func([classDirs funcName]);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    Fs = 16000;
    modeOfOperation = 'narrowband';
    
    switch lower(modeOfOperation)
        case 'narrowband'
            mOp = {''};
        case 'wideband'
            mOp = {'+wb'};
        case 'both'
            mOp = {'';'+wb'};
        otherwise
            error(['''' modeOfOperation ''' is not a recognised ''modeOfOperation'' value.'])
    end   
    
    max_val = max(abs([originalSignal(:); processedSignal(:)]));
    
    pesq = zeros(numel(mOp),1);
    for m = 1:numel(mOp)
        pesqArgs = {['+' num2str(Fs)], ...
                             mOp{m}, ...
                             single(originalSignal / max_val), ...
                             single(processedSignal / max_val)};
        pesq(m,:) = pesq_mex_(pesqArgs{~cellfun(@isempty,pesqArgs)});
        pesq = 46607/14945 - (2000*log(1/(pesq/4 - 999/4000) - 1))/2989;
    end

end

function classDirs = getClassDirs(FullPath)
    classDirs = '';
    classes = strfind(FullPath,'+');
    for c = 1:length(classes)
        clas = FullPath(classes(c):end);
        stp = strfind(clas,filesep);
       classDirs = [classDirs  clas(2:stp(1)-1) '.'];
    end
end