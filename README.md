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

## . Desarrollo

### 3.0 Descripción general del sistema

En este proyecto se implementa un sistema digital sincrónco que realiza la acaptura de dos números de 3 dígitos desde un teclado hexadecimal, almacena los operandos para posteriormente ejecutar la suma de los mismos y finalmente desplegar el resultado en 4 displays de 7 segmentos. El sistema fue desarrollado mediante SystemVerilog sobre FPGA Tangnano 9k. Todo el sistema de módulos fue diseñado bajo una arquitectura sincrónica utilizando el reloj principal de 27 MHz.

## Arquitectura general

![Diagrama General](images/block_diagram.png)

El flujo general del sistema comienza con la captura de datos desde el teclado hexadecimal como se puede observar, para posteriormente que las señales pasen por procesos de sincronización y debounce para evitar los rebotes mecánicos y metastabilidad. La FSM controla la captura secuencial de los números A y B, habilitando posteriormente la unidad arimética para realizar la suma y enviando luego el resultado al subsistema de displays.

## Subsistema de Lectura de Teclado


## Máquina de Estados Finitos (FSM)

La FSM fue diseñada principalmente para el control completo del flujo del sistema. 
![FSM](images/fsm.png)

## Tabla de Estados

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

# Pseudocódigo FSM
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

# testbench FSM

El testbench realizado sobre este módulo resultó como se quería: el reset arranca en 0 y luego sube a 1, se ve la secuencia del estado actual 00 -> 01 -> 10, lo cual también corresponde a IDLE -> INGRESO_A -> INGRESO_B. Se ejecuta la suma cuando suba 1 al momento que entra al estado 11 MOSTRAR como es de esperar.

![TB_FSM](images/fsm_tb.png)

## Subsistema de Suma

Fue implementado utilizando operadores aritméticos de SystemVerilog cuyo diseño recibe los datos almacenados en los registros A y B y genera un resultado sin signo. Dicho módulo opera de manera sincrónica con el reloj principal de 27 MHz; la ejecución de la suma es controlada por la FSM del sistema por señales de habiliación. El objetivo es que reciba los operandos almacenados en registros internos, ejecutar la suma aritmética sin signo, generar el resultado para despliegue, mantener sincronización con la FSM y evitar modificaciones fuera del estado de suma.

### Entradas y Salidas

# Entradas
|Señal| Descripción | 
| clk | Reloj principal de 27 MHz |
| rst_n | Reinicio del módulo |
| numero_a | Primer operando |
| numero_b | Segundo operando |
| ejecutar | Habilita ejecución de suma |

# Salidas 
| Señal | Descripcion |
| resultado | Resultado del a suma |

## Diagrama de estados suma

![FSM Sumador](images/fsm_sumador.png)

## Pesudocódigo suma
```
Inicializar módulo

Esperar datos válidos

Si sum_enable = 1:

    resultado = A + B

    guardar resultado

    activar señal done

Esperar nueva operación
```
## Implementación en SystemaVerilog
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
## Testbench suma

En general el mópdulo se comportó como era debido en el testbench realizado donde el reloj se mantuvo uniforme en toda la simulación, ejecutar sube brevemente para cada prueba y baja nuevamente, rst_n arranca en bajo y sube correctamente y resultado cambia correcatamente después de cada pulso de ejecutar.

![TB_SUMA](images/suma_tb.png)


## 4. Consumo de recursos

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

## 5. Problemas encontrados durante el proyecto

La principal dificultad se presentó en la integración total del sistema y la interacción simultánea entre módulos en hardware real. Entre los problema técnicos se encuentra que en la integración se presenta una comunicación incorrecta entre módulos como diversas razones, entre las más usuales el incorrecto nombramiento o llamado de un módulo para ser conectado a otro mediante la FSM de control; otro caso fue el timing que presentaba diferencias entre simulación y hardware y problemas de estabilidad en la sincronización. Finalmente, la conexion física del circuito presentó sus debidos fallos en su cableado entre componentes y FPGA para su funcionamiento. No obstante, en los testbenches realizados se logró demostrar que módulo por módulo sus funcionamiento fue el correcto y esperado para este sistema.

## Reporte de velocidades máximas de reloj

Tomando en cuenta el tamaño moderado del diseño, ausencia de bloques de procesamiento complejos, lógica secuencial relativamente simple y capacidad típica de operacio´n de FPGA para diseños similares, además de que como se evidenció el sistema completo no se logró integrar correctamente en hardware y no fue posible una validación experimental de la frecuencia máxima real de operación de circuito completo se estima:
| Parámetro | Valor aproximado |
| Frecuencia mínima requerida | 27 MHz |
| Frecuencia utilizada | 27 MHz | 
| Frecuencia máxima estimada | 40 - 70 MHz | 

Por supuesto esto tomando en cuenta los módulos desarrollados individualmente como la FSM y controldor de displays que vienen a ser lógica digital de complejidad moderada que la componen Registros secuenciales, Multiplexado de displays, Lógica Combinacional básica, etc.

## Apendices:
### Apendice 1:
texto, imágen, etc

