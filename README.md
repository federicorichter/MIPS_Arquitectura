# TP3 - MIPS

## Universidad Nacional de Córdoba
![image](https://github.com/user-attachments/assets/16ea052b-a425-4ebf-8b1b-adf87b052919)

**Facultad de Ciencias Exactas, Físicas y Naturales**

![Uploading image.png…]()


### Grupo: Federico Richter - Joaquín Otalora  
**Materia:** Arquitectura de Computadoras  
**Año:** 2024  

---

## Introducción

Como parte de este último trabajo de la materia, se implementa un pipeline de procesador MIPS de 5 etapas (Instruction Fetch, Instruction Decode, Execution, Memory Access y Write Back) con detección y control de riesgos. Para esto, nos basamos en la teoría vista a lo largo del cuatrimestre sobre segmentación y el objetivo es lograr ejecutar un programa con las instrucciones compatibles con nuestra arquitectura. Como parte de los requerimientos, también se debe implementar una unidad de debug para facilitar el proceso de corrección.

Utilizando el lenguaje de descripción de Hardware Verilog y la plataforma Vivado, se implementa, simula y programa en una FPGA Basys 3. Se reutilizan módulos previamente implementados en trabajos anteriores, como la ALU y la UART.

---

## Instrucciones

En la arquitectura MIPS contamos con tres tipos de instrucciones: **R, I y J**.

- **Instrucciones tipo R:** Operaciones aritméticas y lógicas. El opcode es siempre `000000` y la función se determina en los 6 bits menos significativos.
  - ![image](https://github.com/user-attachments/assets/aabd4949-8c5f-4e58-b97c-545dd905f0b1)
- **Instrucciones tipo I:** Se realizan entre un registro y un inmediato. El opcode en los 6 bits más significativos determina la operación.
  - ![image](https://github.com/user-attachments/assets/04be5045-e039-4907-9d87-09ec0eacd498)
- **Instrucciones tipo J:** Representan saltos incondicionales. La dirección de destino se encuentra en los bits menos significativos.
  - ![image](https://github.com/user-attachments/assets/0360e80e-f955-4d6f-85a8-bd19861c93f1)

Las instrucciones implementadas incluyen: `SLL, SRL, SRA, SLLV, SRLV, SRAV, ADDU, SUBU, AND, OR, XOR, NOR, SLT, SLTU, LB, LH, LW, LWU, LBU, LHU, SB, SH, SW, ADDI, ADDIU, ANDI, ORI, XORI, LUI, SLTI, SLTIU, BEQ, BNE, J, JAL, JR, JALR`.

---

## Implementación de las Etapas

El pipeline consta de cinco etapas que transmiten datos y señales de control a través de latches:

1. **Instruction Fetch (IF):** Contiene la memoria de instrucciones y el Program Counter (PC).
2. **Instruction Decode (ID):** Decodifica instrucciones y accede al banco de registros.
3. **Execution (E):** Utiliza la ALU para realizar operaciones.
4. **Memory Access (M):** Accede a la memoria para operaciones `LOAD` y `STORE`.
5. **Write Back (WB):** Escribe resultados en registros.

![image](https://github.com/user-attachments/assets/333bbefa-7038-41ef-b8ac-b830b0333a5f)


---

## Señales de Control

En la etapa ID, una unidad de control interpreta la instrucción y genera señales de control. Se implementan 18 señales, entre ellas:

- `REG_WRITE`: Indica si se escribe un registro en WB.
- `BRANCH`: Indica si es una instrucción de salto condicional.
- `MEM_READ` / `MEM_WRITE`: Indica acceso a memoria.
- `ALU_OP`: Define la operación de la ALU.
- `MASK_1` y `MASK_2`: Determinan el tamaño de acceso a memoria.

![image](https://github.com/user-attachments/assets/22d7b670-26a7-47dc-ab54-e3ab199917d2)

---

## Detección y Control de Riesgos

Existen tres tipos de riesgos en el procesador:

1. **Riesgos estructurales:** Se evitan con memorias separadas y doble puerto en el banco de registros.
2. **Riesgos de datos:** Se resuelven con una unidad de forwarding.
3. **Riesgos de control:** Se reducen agregando hardware para evaluar saltos en la etapa ID y minimizar burbujas.

![image](https://github.com/user-attachments/assets/5786c313-137d-449a-8798-feaee2ad3006)

---

## Debugger

El módulo `debugger.v` ofrece un conjunto de utilidades para observar y controlar la ejecución del procesador MIPS, permitiendo:

- Visualización y edición del contenido de registros internos.
- Examinación de memoria de datos.
- Carga de programas en la memoria de instrucciones.
- Ejecución en modo continuo o paso a paso.

La comunicación se realiza mediante UART, permitiendo interacción remota.

## 1. Parámetros de Configuración

- `SIZE`: Ancho de los datos.
- `NUM_REGISTERS`: Número de registros.
- `MEM_SIZE`: Tamaño de la memoria de datos.
- `STEP_CYCLES`: Cantidad de ciclos de reloj para el modo paso a paso.

## 2. Interfaz del Módulo

### Entradas Principales

- `i_clk`, `i_reset`: Reloj y reset.
- `i_uart_rx`: Entrada UART.
- `i_registers_debug`: Lectura de registros.
- `i_IF_ID`, `i_ID_EX`, `i_EX_MEM`, `i_MEM_WB`: Contenidos de los latches del pipeline.
- `i_debug_data`: Lectura de memoria de datos.
- `i_pc`: Contador de programa.
- `i_debug_instructions`: Memoria completa de instrucciones.

### Salidas Principales

- `o_uart_tx`: Transmisión UART.
- `o_mode`: Modo de depuración.
- `o_debug_addr`: Dirección de depuración de memoria.
- `o_write_addr_reg`, `o_inst_write_enable_reg`, `o_write_data_reg`: Escritura de memoria de instrucciones.
- `o_prog_reset`: Pulso de reset del pipeline.

## 3. Funcionamiento General

El depurador usa una máquina de estados:

1. **IDLE:** Espera comandos.
2. **Recepción del Comando:** Decodifica la acción a realizar.
3. **Ejecución:** Envía registros, modifica memorias, cambia de modo, o resetea el pipeline.
4. **Confirmación (ACK):** En algunos casos, responde con 'R' tras completar la acción.

## 4. Interacción con el Procesador MIPS

- **Lectura de registros y latches:** Envía estados de los registros y pipeline.
- **Escritura en memoria de instrucciones:** Permite cargar instrucciones y resetear el pipeline.
- **Acceso a memoria de datos:** Lee y escribe direcciones de memoria.
- **Modo Paso a Paso y StopPC:** Permite pausas controladas en la ejecución.

## 5. Comandos Implementados

Algunos de los comandos más relevantes:

- `0x01`: Lectura de registros.
- `0x06`: Lectura de memoria.
- `0x07`: Carga de programa.
- `0x08`: Modo continuo.
- `0x09`: Modo paso a paso.
- `0x0A`: Ejecución de un paso.
- `0x0E`: Configuración de StopPC.

## 6. Carga de Programas

1. Enviar `0x07`.
2. Enviar el número de instrucciones.
3. Enviar cada instrucción (4 bytes).
4. Esperar el ACK ('R').
5. Enviar `0x0D` para iniciar ejecución.

## 7. Diagrama de Estados del debugger

Puedes ver el diagrama de estados del depurador a continuación:

![Diagrama de Estados del Depurador](scripts/Debugger_State_Diagram.svg)
