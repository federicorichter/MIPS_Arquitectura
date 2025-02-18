## Universidad Nacional de Córdoba
![image](https://github.com/user-attachments/assets/16ea052b-a425-4ebf-8b1b-adf87b052919)

**Facultad de Ciencias Exactas, Físicas y Naturales**

![image](https://github.com/user-attachments/assets/70ccfa04-87b9-4431-a122-28e955776985)


### Grupo: Federico Richter - Joaquín Otalora  
**Materia:** Arquitectura de Computadoras  
**Año:** 2024  

---
## Introducción

Como parte de este último trabajo de la materia, se implementa un pipeline de procesador MIPS de 5 etapas (Instruction Fetch, Instruction Decode, Execution, Memory Access y Write Back) con detección y control de riesgos. El desarrollo se basa en la teoría vista a lo largo del cuatrimestre sobre segmentación, con el objetivo de ejecutar un programa con las instrucciones compatibles con nuestra arquitectura. Como parte de los requerimientos, también se implementa una unidad de debug para facilitar el proceso de corrección.

Se utiliza el lenguaje de descripción de Hardware Verilog y la plataforma Vivado para la implementación, simulación y programación de la FPGA, en este caso, una Basys 3. Se aclara que se utilizarán una serie de módulos implementados en trabajos anteriores de la materia (ALU y UART).

## Instrucciones

La arquitectura MIPS implementada soporta 3 tipos de instrucciones: R, I y J.

*   **Tipo R:** Operaciones aritméticas y lógicas.
    *   Opcode: `000000` (siempre).
    *   Función: Indicada en los 6 bits menos significativos.
    *   Formato: Especifica las posiciones de los registros fuente (s y t) y el registro destino en el 
    banco de registros.

![image](https://github.com/user-attachments/assets/aabd4949-8c5f-4e58-b97c-545dd905f0b1)

*   **Tipo I:** Operaciones entre un registro y un inmediato.
    *   Opcode: Determina la operación en los 6 bits más significativos.
    *   Operación: Se realiza sobre el inmediato (16 bits menos significativos) y el registro indicado en `rs`.
    *   Resultado: Almacenado en `rt`.
    *   LOAD y STORE: Calculan la dirección de acceso a memoria sumando el registro en `rs` y el inmediato.
    
![image](https://github.com/user-attachments/assets/04be5045-e039-4907-9d87-09ec0eacd498)

*   **Tipo J:** Saltos incondicionales.
    *   Posición de salto: Indicada en los bits menos significativos.
    *   Instrucciones: `J` y `JAL` (almacena la posición de retorno en el registro 31).
      
![image](https://github.com/user-attachments/assets/0360e80e-f955-4d6f-85a8-bd19861c93f1)


Se implementa la siguiente lista de instrucciones: `SLL`, `SRL`, `SRA`, `SLLV`, `SRLV`, `SRAV`, `ADDU`, `SUBU`, `AND`, `OR`, `XOR`, `NOR`, `SLT`, `SLTU`, `LB`, `LH`, `LW`, `LWU`, `LBU`, `LHU`, `SB`, `SH`, `SW`, `ADDI`, `ADDIU`, `ANDI`, `ORI`, `XORI`, `LUI`, `SLTI`, `SLTIU`, `BEQ`, `BNE`, `J`, `JAL`, `JR`, `JALR`.

## Implementación etapas

El pipeline consiste en 5 etapas, cada una con una función específica. Los datos y señales de control se transmiten entre etapas utilizando latches (Flip-flops):

*   **Instruction Fetch (IF):**
    *   Función: Almacena el program counter (PC) e incluye la memoria de instrucciones.
    *   Salida: La instrucción y el valor del PC se transmiten a la siguiente etapa.
*   **Instruction Decode (ID):**
    *   Función: Decodifica la instrucción y levanta las señales de control pertinentes.
    *   Acceso: Se realiza el acceso a los registros dentro del banco de registros.
*   **Execution (E):**
    *   Entrada: Valores de los operandos (desde el banco de registros o el inmediato).
    *   Función: Utiliza la ALU para realizar la operación correspondiente.
*   **Memory Access (M):**
    *   Dirección: Calculada en la etapa anterior.
    *   Función: Escribe (STORE) o lee (LOAD) datos de la memoria de datos.
    *   Acceso: Solo las instrucciones de LOAD y STORE acceden a la memoria de datos.
*   **Write Back (WB):**
    *   Función: Escribe los registros con los resultados de la etapa E o los datos leídos de la memoria de datos.

![image](https://github.com/user-attachments/assets/333bbefa-7038-41ef-b8ac-b830b0333a5f)

En esta figura se incluyen las 5 etapas faltando los latches intermedios entre etapa y etapa que almacenan los datos que se transmiten entre una y otra. 


## Señales de control 

En la etapa de ID se implementa una unidad de control que, dependiendo de la instrucción (opcode y función), levanta una serie de banderas o bits de control y los envía a la siguiente etapa. A lo largo del pipeline se utilizan distintas señales de control, transmitiéndose las señales requeridas de latch a latch.

En esta implementación se utilizan 18 bits de control:

*   `REG_WRITE`: Indica si se escribirá un registro en la etapa de Write Back.
*   `BRANCH`: Indica si es una instrucción del tipo branch.
*   `UNSIGNED`: Indica si es una operación con signo o no.
*   `MEM_READ`: Indica si se lee la memoria en la etapa 4.
*   `MEM_WRITE`: Indica si se escribe la memoria en la etapa 4.
*   `MASK_1` y `MASK_2`: En LOAD y STORE, indica cuántos bits de los 32 son tomados en cuenta (bytes, media palabra o palabra).
*   `REG_DST`: Si es uno, el registro destino es `rd`; sino, es `rt`.
*   `SHIFT_SRC`: Determina si la cantidad de bits a shiftear proviene del registro `rs` (0) o de la instrucción.
*   `ALU_SRC`: Si es 1, el operando B surge del inmediato; sino, es el valor del registro `rt`.
*   `ALU_OP`: 3 bits que determinan la operación a ejecutar de la ALU.
*   `MEM_2_REG`: Indica una instrucción STORE que escribe en un registro el dato leído de memoria.
*   `J_RET_DST`: En saltos que guardan el PC, indica si se guarda en el registro 31 (1) o en el registro indicado en la instrucción (0) `rd`.
*   `EQorNE`: Si es 1, el salto condicional depende de que los operandos sean iguales; sino, que sean distintos.
*   `JUMP_SRC`: Determina si el destino del salto proviene de un registro (0) o inmediato (1).
*   `JUMP_OR_B`: Si es 1, es una instrucción J; sino, es un salto condicional.

![image](https://github.com/user-attachments/assets/22d7b670-26a7-47dc-ab54-e3ab199917d2)


## Detección y control de riesgos 

Existen 3 tipos de riesgos en un procesador: estructurales, de datos y de control.

*   **Riesgos estructurales:** Surgen al querer acceder al mismo recurso en el mismo ciclo de reloj en más de una instrucción.
    *   Solución: Dos memorias separadas de instrucciones y datos, dos puertos para la lectura de registros en el banco de registros, flanco ascendente del reloj para la escritura y descendente para lectura en memoria y registros.
*   **Riesgos de datos:** Surgen cuando una instrucción necesita el dato que genera una instrucción anterior y todavía no está lista.
    *   Solución: Unidad de forwarding que detecta estos riesgos y pasa a la etapa de ejecución directamente los valores de los operandos necesarios.
    *   Caso especial: Si se requiere un dato en la memoria de datos accedido con un LOAD en el ciclo inmediato, se implementa una unidad de detección de riesgos que genera una burbuja y detiene el pipeline por un ciclo.
*   **Riesgos de control:** Surgen de la necesidad de tomar una decisión en los saltos condicionales basados en un resultado de comparación que no se obtiene hasta más adelante en el pipeline.
    *   Solución: Hardware para comparar los operandos en la etapa de ID y un sumador para obtener la dirección a la cual saltar, requiriendo detener el pipeline (inducir una burbuja) un solo ciclo.

![image](https://github.com/user-attachments/assets/5786c313-137d-449a-8798-feaee2ad3006)


## Debugger

El módulo `debugger.v` ofrece un conjunto de utilidades para observar y controlar la ejecución del procesador MIPS, permitiendo:

*   Visualización y edición del contenido de registros internos.
*   Examinación de memoria de datos.
*   Carga de programas en la memoria de instrucciones.
*   Ejecución en modo continuo o paso a paso.

La comunicación se realiza mediante UART, permitiendo interacción remota.

### Parámetros de Configuración

*   `SIZE`: Ancho de los datos.
*   `NUM_REGISTERS`: Número de registros.
*   `MEM_SIZE`: Tamaño de la memoria de datos.
*   `STEP_CYCLES`: Cantidad de ciclos de reloj para el modo paso a paso.

### Interfaz del Módulo

#### Entradas Principales

*   `i_clk`, `i_reset`: Reloj y reset.
*   `i_uart_rx`: Entrada UART.
*   `i_registers_debug`: Lectura de registros.
*   `i_IF_ID`, `i_ID_EX`, `i_EX_MEM`, `i_MEM_WB`: Contenidos de los latches del pipeline.
*   `i_debug_data`: Lectura de memoria de datos.
*   `i_pc`: Contador de programa.
*   `i_debug_instructions`: Memoria completa de instrucciones.

#### Salidas Principales

*   `o_uart_tx`: Transmisión UART.
*   `o_mode`: Modo de depuración.
*   `o_debug_addr`: Dirección de depuración de memoria.
*   `o_write_addr_reg`, `o_inst_write_enable_reg`, `o_write_data_reg`: Escritura de memoria de instrucciones.
*   `o_prog_reset`: Pulso de reset del pipeline.

### Funcionamiento General

El depurador usa una máquina de estados:

1.  **IDLE:** Espera comandos.
2.  **Recepción del Comando:** Decodifica la acción a realizar.
3.  **Ejecución:** Envía registros, modifica memorias, cambia de modo, o resetea el pipeline.
4.  **Confirmación (ACK):** En algunos casos, responde con 'R' tras completar la acción.

### Interacción con el Procesador MIPS

*   Lectura de registros y latches: Envía estados de los registros y pipeline.
*   Escritura en memoria de instrucciones: Permite cargar instrucciones y resetear el pipeline.
*   Acceso a memoria de datos: Lee y escribe direcciones de memoria.
*   Modo Paso a Paso y StopPC: Permite pausas controladas en la ejecución.

### Comandos Implementados

Algunos de los comandos más relevantes:

*   `0x01`: Lectura de registros.
*   `0x06`: Lectura de memoria.
*   `0x07`: Carga de programa.
*   `0x08`: Modo continuo.
*   `0x09`: Modo paso a paso.
*   `0x0A`: Ejecución de un paso.
*   `0x0E`: Configuración de StopPC.

### Carga de Programas

1.  Enviar `0x07`.
2.  Enviar el número de instrucciones.
3.  Enviar cada instrucción (4 bytes).
4.  Esperar el ACK ('R').
5.  Enviar `0x0D` para iniciar ejecución.

### Diagrama de Estados del debugger

Puedes ver el diagrama de estados del depurador a continuación:

![image](https://github.com/user-attachments/assets/56c497ed-9682-42dc-9672-fc8338ee3702)

Link Google Drive SVG: https://drive.google.com/file/d/1QCAa9kFoFwlr-5MrAj1FITfCE0ovDCWr/view?usp=sharing

## Analisis de timing:
Se probo la frecuencia maxima a la que se puede ejecutar el sistema sin problemas de timing.

### 70Mhz
- ![image](https://github.com/user-attachments/assets/2360cfd6-b675-446a-9705-da5912d95427)

### 60Mhz
- ![image](https://github.com/user-attachments/assets/348c63c5-f27d-4e85-8504-a0b1adf983a1)

### 55Mhz
- ![image](https://github.com/user-attachments/assets/20582888-5e11-4028-b3ae-803737ef9006)

### 40 Mhz:
- ![image](https://github.com/user-attachments/assets/c6390d10-d1cd-4892-afa9-e4d68e3c101b)

Concluimos que la frecuencia maxima a la que podemos hacer funcionar la implementacion es de 55 Mhz.

## Diagrama de bloques del MIPS

![image](https://github.com/user-attachments/assets/ebb25c3f-bbd5-4f15-80dc-36e83e09e6f5)

Link Google Drive SVG: https://drive.google.com/file/d/12zH1TmU-y-AC7Wxa7y6nwYojT1YrmjtS/view?usp=sharing
