% Trabajo de grado de Ingeniería en Electrónica y Telecomunicaciones 
% Universidad del Cauca 
% Dream Team: Jhon Fredy Romero y Lina Virginia Muñoz
% Función para calcular nombres de las columnas
function columnsNames = getColumnsNames(n, q)
    % n es el número de niveles de descomposición
    % q son los niveles de cuantificación

    columnsNames = cell(1, 4 * n * length(q) + 1);
    columnsNames{1} = "Audio";
    indexer = 2;

    % Crea los nombres de las columnas
    for j = 1:n
        for k = q
            columnsNames{indexer} = "PESQ, q = " + k + ", n = " + j;
            indexer = indexer + 1;
            columnsNames{indexer} = "NMSE, q = " + k + ", n = " + j;
            indexer = indexer + 1;
            columnsNames{indexer} = "Bits usados, q = " + k + ", n = " + j;
            indexer = indexer + 1;
            columnsNames{indexer} = "Bits desperdiciados, q = " + k + ", n = " + j;
            indexer = indexer + 1;
        end
    end
end