// top.sv
// Módulo superior que integra la lectura del teclado, el decodificador,
// el almacenamiento del valor de la tecla y el multiplexado de la pantalla.
// Genera dos enable de reloj: uno para el escaneo de teclado y otro para el
// refresco de los dígitos de la pantalla 7 segmentos.
module top(

    //////////////////////////////////////////////////
    // INPUTS
    //////////////////////////////////////////////////

    input logic clk,
    input logic reset,

    input logic [3:0] rows,

    //////////////////////////////////////////////////
    // OUTPUTS
    //////////////////////////////////////////////////

    output logic [3:0] cols,

    output logic [6:0] seg,

    output logic [1:0] an
);

//////////////////////////////////////////////////////
// INTERNAL SIGNALS
//////////////////////////////////////////////////////

logic scan_enable;
logic display_enable;

logic [1:0] row_detect;
logic [1:0] col_detect;

logic key_valid;

logic [3:0] key_value;

logic [1:0] active_display;

logic [3:0] digit_out;

//////////////////////////////////////////////////////
// FSM SIGNALS
//////////////////////////////////////////////////////

logic capturando_A;
logic capturando_B;
logic ejecutar_suma;


//////////////////////////////////////////////////////
// NUMBER STORAGE
//////////////////////////////////////////////////////

logic [9:0] numero_A;
logic [9:0] numero_B;

logic listo_A;
logic listo_B;

logic [10:0] resultado;

//////////////////////////////////////////////////////
// CLOCK ENABLES
//////////////////////////////////////////////////////

clock_enable #(
    .MAX_COUNT(5000) //cabiar de nuevo a 5000
)
scan_clk (

    .clk(clk),
    .reset(reset),

    .enable(scan_enable)
);

clock_enable #(
    .MAX_COUNT(100000) //cambiar de nuevo a 100000
)
display_clk (

    .clk(clk),
    .reset(reset),

    .enable(display_enable)
);

//////////////////////////////////////////////////////
// KEYPAD READER
//////////////////////////////////////////////////////

keypad_reader keypad0 (

    .clk(clk),
    .reset(reset),

    .scan_enable(scan_enable),

    .rows(rows),
    .cols(cols),

    .row_detect(row_detect),
    .col_detect(col_detect),

    .key_valid(key_valid)
);

//////////////////////////////////////////////////////
// KEY DECODER
//////////////////////////////////////////////////////

key_decoder decoder0 (

    .row(row_detect),
    .col(col_detect),

    .value(key_value)
);

//////////////////////////////////////////////////////
// FSM
//////////////////////////////////////////////////////

fsm_teclado fsm0 (

    .clk(clk),

    .rst_n(~reset),

    .tecla_valida(key_valid),

    .tecla(key_value),

    .capturando_A(capturando_A),

    .capturando_B(capturando_B),

    .ejecutar_suma(ejecutar_suma)
);

//////////////////////////////////////////////////////
// DISPLAY MUX
//////////////////////////////////////////////////////

mux_display mux0 (

    .clk(clk),
    .reset(reset),

    .display_enable(display_enable),

    .active_display(active_display)
);




capturador_numero capA (

    .clk(clk),
    .rst_n(~reset),

    .habilitado(capturando_A),

    .tecla_valida(key_valid),

    .tecla(key_value),

    .numero_bcd(numero_A),

    .listo(listo_A)
);


capturador_numero capB (

    .clk(clk),
    .rst_n(~reset),

    .habilitado(capturando_B),

    .tecla_valida(key_valid),

    .tecla(key_value),

    .numero_bcd(numero_B),

    .listo(listo_B)
);

//////////////////////////////////////////////////////
// ADDER
//////////////////////////////////////////////////////

assign resultado = numero_A + numero_B;

//////////////////////////////////////////////////////
// DISPLAY CONTENT
//////////////////////////////////////////////////////

always_comb begin

    digit_out = 4'd0;

    case(active_display)

        //////////////////////////////////////////////////
        // DISPLAY DERECHO
        //////////////////////////////////////////////////

        1'b0: begin

            if(ejecutar_suma)
                digit_out = resultado % 10;

            else if(capturando_B)
                digit_out = numero_B;

            else
                digit_out = numero_A;

        end

        //////////////////////////////////////////////////
        // DISPLAY IZQUIERDO
        //////////////////////////////////////////////////

        1'b1: begin

            if(ejecutar_suma)
                digit_out = resultado / 10;

            else
                digit_out = 4'd0;

        end

        default: digit_out = 4'd0;

    endcase

end

//////////////////////////////////////////////////////
// 7 SEG DECODER
//////////////////////////////////////////////////////

seven_seg_decoder seg0 (

    .number(digit_out),

    .seg(seg)
);

//////////////////////////////////////////////////////
// DISPLAY ENABLES
//////////////////////////////////////////////////////

always_comb begin

    // valor por defecto
    an = 2'b11;

    case(active_display)
        1'b0: an = 2'b10;
        1'b1: an = 2'b01;
        default: an = 2'b11;
    endcase

end

endmodule