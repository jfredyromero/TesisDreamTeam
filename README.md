# Repositorio de la tesis de grado de Jhon Fredy Romero y Lina Virginia Muñoz

Este repositorio contiene el código y los recursos utilizados en la investigación de tesis de grado de Jhon Fredy Romero y Lina Virginia Muñoz, dirigida por la tutora Maria Manuela Silva. El proyecto, desarrollado por el equipo "Dream Team", tiene como objetivo cuantificar señales de voz en el dominio wavelet utilizando el esquema lifting en MATLAB.

## Estructura del repositorio

- `Grabaciones/`: contiene las grabaciones de voz utilizadas en la investigación.
- `Mediciones/`: contiene los archivos utilizados para medir el PESQ y el NMSE.
  - `PESQ.m`
  - `NMSE.m`
- `Resultados/`: Contiene los resultados obtenidos en la investigación.
- `Src/`: contiene el código fuente utilizado para implementar el esquema lifting y mallat.
  - `Lifting/`: Contiene los archivos correspondientes al algoritmo de cuantificación lifting.
  - `Mallat/`: Contiene los archivos correspondientes al algoritmo de cuantificación mallat.
  - `pruebasLifting.m`: Archivo principal que contiene el código para realizar las pruebas del esquema Lifting.
  - `pruebasMallat.m`: Archivo principal que contiene el código para realizar las pruebas del esquema Mallat.
- `Utilidades/`: Contiene las funciones y scripts auxiliares utilizados en la investigación.

## Instrucciones de uso

Para utilizar el código fuente y los conjuntos de datos en MATLAB, sigue los siguientes pasos:

1. Descarga o clona este repositorio en tu ordenador.
2. Abre MATLAB y selecciona la carpeta `src` como directorio de trabajo.
3. Ejecuta el archivo `pruebasLifting.m` o `pruebasMallat.m` en MATLAB para ejecutar las pruebas correspondientes al algoritmo Lifting o Mallat, respectivamente.

Si deseas utilizar alguna de las funciones o scripts auxiliares ubicados en la carpeta `Utilidades/`, simplemente añade la ruta correspondiente en MATLAB para que pueda ser utilizada.

Para cargar un archivo `.mat` de otra carpeta en tu código, utiliza la función `load('ruta/al/archivo.mat')`.

¡Gracias por utilizar nuestro repositorio! Si tienes alguna pregunta o problema, no dudes en contactarnos.


