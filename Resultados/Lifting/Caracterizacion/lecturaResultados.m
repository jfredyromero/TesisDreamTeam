archivos = dir('*.mat');

promedios = zeros(numel(archivos), 10);

for i = 1:numel(archivos)
    % Nombre del archivo actual
    archivo = archivos(i).name;

    % Carga los datos del archivo .mat
    datos = load(fullfile(archivo)); 
    
    % Calcula el promedio de cada columna y guárdalo en la tabla de promedios
    promedioCoeficientes = mean(datos.resultTable(:, 2:end), 1);
    promedios(i, :) = table2array(promedioCoeficientes);
end

calidad = mean(promedios, 1);
calidadByCoef = 1 - calidad;
calidadTotal = sum(calidadByCoef, 2);
calidadPorcentual = calidadByCoef ./ calidadTotal;

columnsNames = cell(1, 10);
for i = 1:10
    columnsNames{i} = "Calidad de coef Wavelet " + (11 - i);
end

porcentajes = array2table(calidadPorcentual,  'VariableNames', string(columnsNames));

save("porcentajes.mat", "porcentajes");