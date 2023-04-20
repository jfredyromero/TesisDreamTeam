folderPath = '../Grabaciones';
fileList = dir(fullfile(folderPath, '**/*.m4a')); % Obtiene la lista de archivos .m4a en la carpeta principal y sus subcarpetas

audioCell = cell(length(fileList), 2); % Inicializa una celda para almacenar los datos de audio

for i = 1:length(fileList)
    filePath = fullfile(fileList(i).folder, fileList(i).name); % Obtiene la ruta completa del archivo
    
    % Lee los datos de audio del archivo
    [audioData, sampleRate] = audioread(filePath);
    
    % Extrae el nombre del archivo sin la extensión
    [~, fileName, ~] = fileparts(filePath);
    
    % Almacena los datos de audio en la celda
    audioCell{i, 1} = fileName;
    audioCell{i, 2} = audioData;
end

% Guarda la matriz de audios
save("../Grabaciones/audioCell.mat", "audioCell");