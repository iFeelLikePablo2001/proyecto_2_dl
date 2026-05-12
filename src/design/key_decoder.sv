// key_decoder.sv
// Convierte la posición de fila/columna detectada en el valor de la tecla.
// Mapea cada combinación de row/col a un valor numérico o a códigos especiales
// como A y B para funciones de control.
module key_decoder (
    input logic [1:0] row,
    input logic [1:0] col,
    output logic [3:0] value
);

always_comb begin

    case({row,col})

        4'b0000: value = 1;
        4'b0001: value = 2;
        4'b0010: value = 3;
        4'b0011: value = 10;

        4'b0100: value = 4;
        4'b0101: value = 5;
        4'b0110: value = 6;
        4'b0111: value = 11;

        default: value = 0;

    endcase

end

endmodule