# Proyecto Corto II: Sistema digital sincrónico en FPGA
## Diseño Lógico EL-3307

## Integrantes
- Kevin Josué Mora Sobalvarro
- Pabro Cabrera Montealegre

## Introduccion 

El diseño fue dividido en distintos subsistemas: lectura de teclado, sincronización y debounce, FSM de control, almacenamiento de datos, suma aritmética y control de displays. Aunque el sistema completo no lograra funcionar correctamente durante la demostración final se desarrollaron y verificaron individualmente los submódulos mediante testbenches funcionales, permitiendo validar parcialmente el diseño propuesto.

## Objetivos

En general se propuso diseñar e implementar un sistema digital sincrónico en FPGA mediante SystemVerilog para capturar dos números de un teclado hexadecimal, sumarlos y desplejar el resultado displays de 7 segmentos. 
En cuanto a los específicos se despliegan:
Implementar lectura de teclado hexadecimal.
Diseñar una FSM de control del sistema.
Implementar almacenamiento de datos mediante registros.
Implementar suma aritmética en HDL. 
Implementar multiplexado de displays de 7 segmentos.
Realizar testbenches de los submódulos.

## Desarrollo

### Descripción general del sistema

En este proyecto se implementa un sistema digital sincrónco que realiza la acaptura de dos números de 3 dígitos desde un teclado hexadecimal, almacena los operandos para posteriormente ejecutar la suma de los mismos y finalmente desplegar el resultado en 4 displays de 7 segmentos. El sistema fue desarrollado mediante SystemVerilog sobre FPGA Tangnano 9k. Todo el sistema de módulos fue diseñado bajo una arquitectura sincrónica utilizando el reloj principal de 27 MHz.

### Arquitectura general

![Diagrama General](images/block_diagram.png)

El flujo general del sistema comienza con la captura de datos desde el teclado hexadecimal como se puede observar, para posteriormente que las señales pasen por procesos de sincronización y debounce para evitar los rebotes mecánicos y metastabilidad. La FSM controla la captura secuencial de los números A y B, habilitando posteriormente la unidad arimética para realizar la suma y enviando luego el resultado al subsistema de displays.

#### Subsistema de Clock

##### Descripción y funcionamiento
Implementa un generador de pulsos los cueles tienen como función principal producir una señal llamada enable que se activa durante un ciclo de reloj cada cierta cantidad de ciclos definidos por MAX_COUNT. Esto se debe a la necesidad de que ciertos bloques funcionen a una velocidad menor que la del reloj principal que viene por default en el FPGA, sin necesidad de crear un nuevo reloj físico. En lugar de dividir el reloj directamente, se genera una señal de habilitación que indica cuándo debe ejecutarse una operación. Funciona con un contador interno que incrementa su valor en cada flanco positivo del reloj. Cuando el contador alcanza el valor máximo establecido (MAX_COUNT - 1), el contador vuelve a cero y la salida enable se activa durante un único ciclo de reloj.
##### Diagrama de bloques

![Diagrama clock](images/diagrama clock.png)

##### Análisis wv

![tb_clock_enable](images/clock_tb.png)

clk: se espera una señal cuadrada entre 1 y 0 
reset: inicializa el sistema por lo que debe empezar en 1 y luego bajar a 0 indefinidamente
counter: como se utiliza el parámetro MAX_COUNT = 5 se espera que inicie desde 0 y que vaya cuntanto progresivamente hasta 4 para luego volver a iniciar el conteo
enable: permanece en 0 y se activa (cambia a 1) por un ciclo cuando el contador llega a su máximo.

Se puede observar que la salida del archivo wv es la esperada.

#### Subsistema de debounce

##### Descripción general y funcionamiento
Este módulo debounce es un sistema de eliminación de rebotes digitales. Su propósito es filtrar señales de entrada inestables como los insertados por el teclado en este caso. Cuando un botón es presionado o liberado, la señal no de inmediato entre valores lógicos y básicamente se producen muchas transiciones entre 0 y 1 en un corto tiempo. Esto tiende a ser un problema ya que podrían llegar a leerse varias pulsaciones del botón cuando en realidad solo está ocurriendo una. Esto se resuelve verificando que la señal de entrada permanezca estable un tiempo definido antes y después de que ocurra el eneble de la tecla.
En este caso, el módulo recibe una señal de entrada noisy_in, que representa una señal inestable de entrada. Se almacena el valor anterior de la entrada en una variable llamada previous. Esto permite detectar si la señal ha cambiado entre un ciclo de reloj y el siguiente. Se presentan 3 diferentes casos: si la señal cambia respecto al valor anterior el contador se reinicia, si permanece igual el contador incrementa finalmente cuando la señal ha permanecido estable durante LIMIT ciclos consecutivos, el valor se considera válido y se actualiza la salida clean_out. 
##### Diagrama de bloques

![Debounce](images/debounce.png)

##### Análisis wv

![tb_debounce](images/debounce.png)

clk: senal del reloj definida anteriormente
LIMIT: limite del contador, por lo tanto cuando este llegue a este numero, el valor de clean_out cambia a 1 ya que es estable.
previous: guarda el numero anterior a cada ciclo para poder realizar la debida comparacion.
noisy_in: es una senal de prueba por lo que se espera que se vean rapidos cambios logicos y tambien periodos en los que permanece estable.
counter: debe de reiniciarse cada vez que la senal cambia de 1 a 0 y continuar con la cuenta si la senal es estable
clean_out: debe de ignorar todos los rebotes cuando la senal cambia rapidamente y tenere un valor de 1 una vez esta haya estado estable por mas de un ciclo.

Como se logra apreciar en la senal del wv del testbench, se cumple satisfactoriamente todo lo mencionado anteriormente

#### Modulo lector de teclado

##### Descripción general y funcionamiento
El módulo ejecuta la lógica para leer un teclado matricial de 4 filas por 4 columnas. Funciona basado en un proceso de escaneo de columnas y filas donde activa una columna a la vez y posteriormente verifica qué fila (si hay alguna) se encuentra presionada. En cada activación de scan_enable, una única columna del teclado es colocada en estado activo mientras las demás permanecen inactivas. Luego, el sistema revisa las líneas de filas y si alguna fila se encuentra activa, significa que una tecla ubicada en la intersección entre la fila y la columna actual ha sido presionada enviando entonces la señal key_valid para ser reconocida y dándole un valor a esta misma.
##### Diagrama General

![Lector de teclado](images/keypad.png)

##### Análisis wv

![tb_keypad_reader](images/tb_keypad.png)

clk: reloj definido anteriormente
reset: inicia el modulo
scan_enable: permite que la tecla presionada sea leida cada cierto tiempo
cols: va columna por columna al ser un teclado 4x4 se espera 1110 1101 1011 0111
rows: va fila por fila revisando si hay alguna pusacion al ser un teclado 4x4 se espera 0000 y un 1 en la posicion que este activa (si hay).
current_col: indica la columna que se esta analizando actualmente
row_detect: al momento de activarse una tecla indica cual fila ha sido.
col_detect: al momento de activarse una tecla indica cual columna ha sido.
key_valid: envia la senal de que una tecla ha sido presionada y debe coincidir con los datos anteriores

De nuevo se vuelve a cumplir lo esperado, se genera la senal key_enable con la columna 2 y fila 1

#### Modulo sync

##### Descripcion general y funcionamiento
El módulo sync es un sincronizador de señales mediante dos flip-flops en cascada. Su funcion es permitir que una señal externa pueda ser utilizada de manera segura dentro de un sistema síncrono controlado por reloj. Las señales producidas por el teclado pueden cambiar en cualquier instante, independientemente del reloj interno del sistema. Cuando una señal asíncrona entra directamente a lógica secuencial sincronizada por reloj, existe el riesgo de producir metastabilidad que es cuando un flip-flop no logra decidir rápidamente si almacenar un 0 o un 1, generando estados intermedios temporales que pueden propagarse al resto del sistema y producir comportamientos indeseados o glitches. Este módulo, reduce significativamente este problema.
El sincronizador utiliza dos flip-flops conectados en serie donde el primer flip-flop (ff1) captura la señal asíncrona y luego el segundo flip-flop (ff2) captura la salida del primero produciendo una salida sincronizada. Se usan dos etapas para que si el primer flip-flop entra en metastabilidad, tenga suficiente tiempo para estabilizarse antes de que el segundo flip-flop capture su valor.

##### Diagrama de bloques

![Sincronizador](images/sync.png)

##### Analisis wv

![tb_sync](images/tb_sync.png)

clk: senal de clock definida anteriormente
async_in: debe cambiar aleatoriamenrte no necesariamente con el clk.
ff1: actualiza unicamente en los flancos positivos del clk.
ff2: siguie los resultados de ff1 pero con un ciclo de clk de retraso.
sync_out: debe ser identica a ff2 ya que es la senal limpia.

De nuevo, se cumple satisfactoriamente, donde ambos ff inician apagados hasta que la senal clk los enciende, se tiene una senal aleatoria async_in la cual es capturada por los ff en cascada cambiando cada uno un ciclo despues del anterior. Adicionalmente, se tiene la senal sync_out limpia identica a la salida del segundo ff en cascada.

#### Máquina de Estados Finitos (FSM)

La FSM fue diseñada principalmente para el control completo del flujo del sistema. 
![FSM](images/fsm.png)

##### Tabla de Estados

| Estado | Nombre | Función |
|---|---|---|
| S0 | RESET | Inicializa registros y variables |
| S1 | ESPERA_NUM1 | Espera ingreso del primer número |
| S2 | CAPTURA_NUM1 | Captura dígitos del número A |
| S3 | CONFIRMAR_NUM1 | Confirma finalización del número A |
| S4 | CAPTURA_NUM2 | Captura dígitos del número B |
| S5 | CONFIRMAR_NUM2 | Confirma finalización del número B |
| S6 | SUMAR | Ejecuta la operación A + B |
| S7 | MOSTRAR_RESULTADO | Muestra resultado en displays |

##### Pseudocódigo FSM
Inicializar sistema

Borrar registros

Esperar ingreso del número A

Capturar dígitos

Confirmar número A

Esperar número B

Capturar dígitos

Confirmar número B

Resultado = A + B

Mostrar resultado

##### testbench FSM

El testbench realizado sobre este módulo resultó como se quería: el reset arranca en 0 y luego sube a 1, se ve la secuencia del estado actual 00 -> 01 -> 10, lo cual también corresponde a IDLE -> INGRESO_A -> INGRESO_B. Se ejecuta la suma cuando suba 1 al momento que entra al estado 11 MOSTRAR como es de esperar.

![TB_FSM](images/fsm_tb.png)

##### Subsistema de Suma

Fue implementado utilizando operadores aritméticos de SystemVerilog cuyo diseño recibe los datos almacenados en los registros A y B y genera un resultado sin signo. Dicho módulo opera de manera sincrónica con el reloj principal de 27 MHz; la ejecución de la suma es controlada por la FSM del sistema por señales de habiliación. El objetivo es que reciba los operandos almacenados en registros internos, ejecutar la suma aritmética sin signo, generar el resultado para despliegue, mantener sincronización con la FSM y evitar modificaciones fuera del estado de suma.

##### Entradas y Salidas

 Entradas
|Señal| Descripción | 
| clk | Reloj principal de 27 MHz |
| rst_n | Reinicio del módulo |
| numero_a | Primer operando |
| numero_b | Segundo operando |
| ejecutar | Habilita ejecución de suma |

 Salidas 
| Señal | Descripcion |
| resultado | Resultado del a suma |

##### Diagrama de estados suma

![FSM Sumador](images/fsm_sumador.png)

##### Pesudocódigo suma
```
Inicializar módulo

Esperar datos válidos

Si sum_enable = 1:

    resultado = A + B

    guardar resultado

    activar señal done

Esperar nueva operación
```
##### Implementación en SystemaVerilog
```
module suma (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        ejecutar,    // viene de ejecutar_suma de la FSM
    input  logic [9:0]  numero_a,    // máx 999, necesita 10 bits
    input  logic [9:0]  numero_b,    // máx 999, necesita 10 bits
    output logic [10:0] resultado    // máx 1998, necesita 11 bits
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            resultado <= 11'd0;
        else if (ejecutar)
            resultado <= numero_a + numero_b;
    end

endmodule
```
##### Testbench suma

En general el mópdulo se comportó como era debido en el testbench realizado donde el reloj se mantuvo uniforme en toda la simulación, ejecutar sube brevemente para cada prueba y baja nuevamente, rst_n arranca en bajo y sube correctamente y resultado cambia correcatamente después de cada pulso de ejecutar.

![TB_SUMA](images/suma_tb.png)


## Consumo de recursos

El proyecto utilizó principalmente la parte asociada a la lógica combinacional y secuencial debido a la implementación de FSM de control, registros de almacenamiento, lógica debounce, multiplexado de displays, división de frecuencia y control del teclado hexadecimal.

### Recursos
| Recurso | Uso principal |
| LUTs | FSM, lógica de control y decodificación |
| FFs | Registros, sincronización y divisores |
| IO Buffers | Keypad y displays |
| CLK | Reloj principal de 27 MHz |

El mayor consumo de LUTs se presentó en la lógica de control de la FSM y el controlador de displays de 7 segmentos, esto por el multiplexado y decodificación requeridos para el funcionamiento.
Mientras que por otro lado, los flip-flops fueron utilizados principalmente para mantener el diseño complemtante sincrónico y almacenar estados y operandos.
En cuanto al consumo de potencia estiamado por las herramientas se mantuvo relativamente bajo, dado que el diseño operó únicamenta a 27 MHz, no se utilizaron memorias BRAM ni bloques DSP y el tamaño del sistema no fue tan grande, relativamente moderado. El bloque que probablemente generó mayor actividad dinámica fue el subsistema de displays debido al refrescamiento continuo y multiplexado de señales. 

## Problemas encontrados durante el proyecto

La principal dificultad se presentó en la integración total del sistema y la interacción simultánea entre módulos en hardware real. Entre los problema técnicos se encuentra que en la integración se presenta una comunicación incorrecta entre módulos como diversas razones, entre las más usuales el incorrecto nombramiento o llamado de un módulo para ser conectado a otro mediante la FSM de control; otro caso fue el timing que presentaba diferencias entre simulación y hardware y problemas de estabilidad en la sincronización. Finalmente, la conexion física del circuito presentó sus debidos fallos en su cableado entre componentes y FPGA para su funcionamiento. No obstante, en los testbenches realizados se logró demostrar que módulo por módulo sus funcionamiento fue el correcto y esperado para este sistema.

## Reporte de velocidades máximas de reloj

Tomando en cuenta el tamaño moderado del diseño, ausencia de bloques de procesamiento complejos, lógica secuencial relativamente simple y capacidad típica de operacio´n de FPGA para diseños similares, además de que como se evidenció el sistema completo no se logró integrar correctamente en hardware y no fue posible una validación experimental de la frecuencia máxima real de operación de circuito completo se estima:
| Parámetro | Valor aproximado |
| Frecuencia mínima requerida | 27 MHz |
| Frecuencia utilizada | 27 MHz | 
| Frecuencia máxima estimada | 40 - 70 MHz | 

Por supuesto esto tomando en cuenta los módulos desarrollados individualmente como la FSM y controldor de displays que vienen a ser lógica digital de complejidad moderada que la componen Registros secuenciales, Multiplexado de displays, Lógica Combinacional básica, etc.

