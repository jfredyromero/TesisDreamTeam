% Limpieza de variables
clear;
close all;

% Carga los archivos de resultados
archivos = dir('*.mat');

promedios = zeros(numel(archivos), 11);

waveletsNames = cell(1, numel(archivos));

for i = 1:numel(archivos)
    % Nombre del archivo actual
    archivo = archivos(i).name;

    waveletsNames{i} = erase(archivo, ["wavelet-", "-caracterization.mat"]);

    % Carga los datos del archivo .mat
    datos = load(fullfile(archivo)); 
    
    % Calcula el promedio de cada columna y guárdalo en la tabla de promedios
    promedioCoeficientes = mean(datos.resultadosCaracterizacion(:, 2:end), 1);
    promedios(i, :) = table2array(promedioCoeficientes);
end

calidad = 1 - promedios;
calidadTotal = sum(calidad, 2);
calidadPorcentual = calidad ./ calidadTotal;

columnsNames = cell(1, 11);
for i = 1:10
    columnsNames{i} = "Importancia de coef Wavelet " + (11 - i);
end
columnsNames{end} = "Importancia de coef Scaling";

porcentajes = array2table(calidadPorcentual, 'VariableNames', string(columnsNames), 'RowNames', string(waveletsNames));

save("Porcentajes/porcentajesByFamilia.mat", "porcentajes");
