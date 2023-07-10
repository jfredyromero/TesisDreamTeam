% Trabajo de grado de Ingeniería en Electrónica y Telecomunicaciones 
% Universidad del Cauca 
% Dream Team: Jhon Fredy Romero y Lina Virginia Muñoz
% Función para guardar resultados de las pruebas
function resultados = saveResults(audioResults, columnsNames, fw, folder)
    % audioResults es la celda con los resultados de las pruebas
    % columnsNames son los nombres de las columnas de la tabla
    % fw es el nombre de la familia Wavelet usada
    % folder es el nombre del folder donde se guardan los resultados
    
    % Crea y llena la tabla de resultados
    resultados = cell2table(audioResults,  'VariableNames', string(columnsNames));

    % Guarda la tabla con los resultados de las pruebas de los audios
    save("../Resultados/" + folder + "/wavelet-" + fw + "-results.mat", "resultados");
end