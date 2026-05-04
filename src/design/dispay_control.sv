module display_control (

    input logic [1:0] active_display,

    input logic [3:0] units,
    input logic [3:0] tens,
    input logic [3:0] hundreds,
    input logic [3:0] thousands,

    output logic [3:0] digit_out
);

always_comb begin

    case(active_display)

        2'd0: digit_out = units;
        2'd1: digit_out = tens;
        2'd2: digit_out = hundreds;
        2'd3: digit_out = thousands;

    endcase

end

endmodule