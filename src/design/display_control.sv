module display_control (

    input logic active_display,

    input logic [3:0] units,
    input logic [3:0] tens,

    output logic [3:0] digit_out
);

always_comb begin

    case(active_display)

        2'd0: digit_out = units;
        2'd1: digit_out = tens;

    endcase

end

endmodule