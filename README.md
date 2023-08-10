# Repositorio de la tesis de grado de Jhon Fredy Romero y Lina Virginia Muñoz

Este repositorio contiene el código y los recursos utilizados en la investigación de tesis de grado de Jhon Fredy Romero y Lina Virginia Muñoz, dirigida por la tutora Maria Manuela Silva. El proyecto, desarrollado por el equipo "Dream Team", tiene como objetivo cuantificar señales de voz en el dominio wavelet utilizando el esquema lifting en MATLAB.

## Estructura del repositorio

- `Comprobaciones/`: Contiene las comprobaciones requeridas por la investigación.
- `Grabaciones/`: Contiene las grabaciones de voz utilizadas en la investigación.
- `Mediciones/`: Contiene los archivos utilizados para medir el PESQ y el NMSE de los audios procesados.
  - `medirPESQ.m`: Archivo que contiene el código para realizar la medición objetiva PESQ sobre el audio procesado.
  - `medirNMSE.m`: Archivo que contiene el código para realizar la medición objetiva NMSE sobre el audio procesado.
- `Resultados/`: Contiene los resultados obtenidos en la investigación.
  - `Comparacion/`: Contiene los resultados de comparaciones entre 2 o más algoritmos de cuantificación.
  - `Lifting/`: Contiene los resultados relacionados exclusivamente al algoritmo de cuantificación lifting.
- `Src/`: Contiene los archivos fuente utilizados en la investigación.
  - `Lifting/`: Contiene los archivos correspondientes al algoritmo de cuantificación lifting.
    - `Adaptativo/`: Contiene los archivos relacionados con la implementación del algoritmo lifting con el calculo trama a trama de los porcentajes de relevancia.
    - `Constante/`: Contiene los archivos relacionados con la implementación del algoritmo lifting con el establecimiento previo de los porcentajes de relevancia de todo el audio.
    - `Tradicional/`: Contiene los archivos relacionados con la implementación del algoritmo lifting sin ninguna distribución particular de bits.
  - `Mallat/`: Contiene los archivos correspondientes al algoritmo de cuantificación mallat.
    - `Adaptativo/`: Contiene los archivos relacionados con la implementación del algoritmo mallat con el calculo trama a trama de los porcentajes de relevancia.
    - `Tradicional/`: Contiene los archivos relacionados con la implementación del algoritmo mallat sin ninguna distribución particular de bits.
  - `Tiempo/`: Contiene los archivos correspondientes al algoritmo de cuantificación en el tiempo.
    - `Tradicional/`: Contiene los archivos relacionados con la implementación de una cuantificación en el tiempo sin ninguna distribución particular de bits.
- `Utilidades/`: Contiene las funciones y scripts auxiliares utilizados en la investigación.
  - `audioLecture.m`: Archivo que contiene el código para realizar la lectura automatizada de los audios dentro de la carpeta `Grabaciones/`.
  - `bitDistributor.m`: Archivo que contiene el código para la distribución inteligente del 100% de los bits disponibles.
  - `cuantUniV.m`: Archivo que contiene el código para realizar la cuantificación uniforme de un grupo de coeficientes.  
  - `heuristicOptimizer.m`: Archivo que contiene el código que realiza la optimización heuristica de los bits disponibles para cada coeficiente.
  - `signalCropper.m`: Archivo que contiene el código para realizar el recorte necesario de los coeficientes Wavelet y Scaling para que tengan un tamaño potencia de 2.

## Instrucciones de uso

Para utilizar el código fuente y los conjuntos de datos en MATLAB, sigue los siguientes pasos:

1. Descarga o clona este repositorio en tu ordenador.
2. Abre MATLAB y selecciona la carpeta `Comprobaciones/` como directorio de trabajo.
3. Ejecuta cualquiera de los archivos disponibles en MATLAB para ejecutar las comprobaciones relacionadas con la investigación.

Si deseas utilizar alguna de las funciones o scripts auxiliares ubicados en la carpeta `Utilidades/`, simplemente añade la ruta correspondiente en MATLAB para que pueda ser utilizada.

Para cargar un archivo `.mat` de otra carpeta en tu código, utiliza la función `load('ruta/al/archivo.mat')`.

¡Gracias por utilizar nuestro repositorio! Si tienes alguna pregunta o problema, no dudes en contactarnos.


