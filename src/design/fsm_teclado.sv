module fsm_teclado (
    input  logic        clk,        // 27 MHz
    input  logic        rst_n,      // reset activo en bajo
    input  logic        tecla_valida, // pulso: indica que hay una tecla nueva
    input  logic [3:0]  tecla,      // valor de la tecla (0-9, A-F)
    output logic        capturando_A, // señal de control: estamos en número 1
    output logic        capturando_B, // señal de control: estamos en número 2
    output logic        ejecutar_suma // señal de control: calcular y mostrar
);

    // ── 1. Definición de estados ──────────────────────────────────────
    // Siempre usa typedef enum para que sea legible
    typedef enum logic [1:0] {
        IDLE      = 2'b00,
        INGRESO_A = 2'b01,
        INGRESO_B = 2'b10,
        MOSTRAR   = 2'b11
    } estado_t;

    estado_t estado_actual, estado_siguiente;

    // Constante: cuántos dígitos acepta cada número
    localparam MAX_DIGITOS = 3;

    // Contador de dígitos ingresados
    logic [1:0] contador_digitos; // 0, 1, 2, 3

    // ── 2. BLOQUE 1: Registro de estado (secuencial) ──────────────────
    // Este bloque SOLO actualiza el estado. Nada más.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            estado_actual <= IDLE;
        else
            estado_actual <= estado_siguiente;
    end

    // ── 3. BLOQUE 2: Lógica de siguiente estado (combinacional) ───────
    // Decide a dónde ir según el estado actual y las entradas.
    // IMPORTANTE: siempre cubre TODOS los casos con default.
    always_comb begin
        estado_siguiente = estado_actual; // default: quedarse

        case (estado_actual)
            IDLE: begin
                if (tecla_valida)
                    estado_siguiente = INGRESO_A;
            end

            INGRESO_A: begin
                // La tecla 'A' (4'hA) actúa como separador entre números
                if (tecla_valida && tecla == 4'hA)
                    estado_siguiente = INGRESO_B;
            end

            INGRESO_B: begin
                // La tecla 'B' (4'hB) ejecuta la suma
                if (tecla_valida && tecla == 4'hB)
                    estado_siguiente = MOSTRAR;
            end

            MOSTRAR: begin
                // La tecla 'C' (4'hC) reinicia todo
                if (tecla_valida && tecla == 4'hC)
                    estado_siguiente = IDLE;
            end

            default: estado_siguiente = IDLE;
        endcase
    end

    // ── 4. BLOQUE 3: Salidas (combinacional tipo Moore) ───────────────
    // Las salidas dependen SOLO del estado actual (tipo Moore).
    // Esto es más seguro y predecible para síntesis.
    always_comb begin
        // Valores por defecto (evita latches indeseados)
        capturando_A  = 1'b0;
        capturando_B  = 1'b0;
        ejecutar_suma = 1'b0;

        case (estado_actual)
            IDLE:      ; // todas las salidas en 0 (ya asignadas arriba)
            INGRESO_A: capturando_A  = 1'b1;
            INGRESO_B: capturando_B  = 1'b1;
            MOSTRAR:   ejecutar_suma = 1'b1;
            default:   ; // seguridad
        endcase
    end

endmodule
