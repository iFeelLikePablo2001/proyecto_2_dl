module top(

    input logic clk,
    input logic reset,

    input logic [3:0] rows,
    output logic [3:0] cols,

    output logic [6:0] seg,
    output logic [3:0] an
);

///////////////////////////////////////////////////////////
// SIGNALS
///////////////////////////////////////////////////////////

logic scan_enable;
logic display_enable;

logic [1:0] row_detect;
logic [1:0] col_detect;

logic key_valid;

logic [3:0] key_value;

logic [1:0] active_display;

logic [3:0] digit_out;

logic [3:0] stored_digit;

///////////////////////////////////////////////////////////
// CLOCK ENABLES
///////////////////////////////////////////////////////////

clock_enable #(
    .MAX_COUNT(50000)
)
scan_clk (
    .clk(clk),
    .reset(reset),
    .enable(scan_enable)
);

clock_enable #(
    .MAX_COUNT(100000)
)
display_clk (
    .clk(clk),
    .reset(reset),
    .enable(display_enable)
);

///////////////////////////////////////////////////////////
// KEYPAD READER
///////////////////////////////////////////////////////////

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

///////////////////////////////////////////////////////////
// KEY DECODER
///////////////////////////////////////////////////////////

key_decoder decoder0 (

    .row(row_detect),
    .col(col_detect),

    .value(key_value)
);

///////////////////////////////////////////////////////////
// STORE LAST KEY
///////////////////////////////////////////////////////////

always_ff @(posedge clk or posedge reset) begin

    if(reset)
        stored_digit <= 0;

    else if(key_valid)
        stored_digit <= key_value;

end

///////////////////////////////////////////////////////////
// DISPLAY MULTIPLEXER
///////////////////////////////////////////////////////////

mux_display mux0 (

    .clk(clk),
    .reset(reset),

    .display_enable(display_enable),

    .active_display(active_display)
);

///////////////////////////////////////////////////////////
// ANODES CONTROL
///////////////////////////////////////////////////////////

always_comb begin

    case(active_display)

        2'd0: an = 4'b1110;
        2'd1: an = 4'b1101;
        2'd2: an = 4'b1011;
        2'd3: an = 4'b0111;

    endcase

end

///////////////////////////////////////////////////////////
// DISPLAY DATA
///////////////////////////////////////////////////////////

display_control display0 (

    .active_display(active_display),

    .units(stored_digit),
    .tens(stored_digit),
    .hundreds(stored_digit),
    .thousands(stored_digit),

    .digit_out(digit_out)
);

///////////////////////////////////////////////////////////
// 7 SEG DECODER
///////////////////////////////////////////////////////////

seven_seg_decoder seg0 (

    .number(digit_out),
    .seg(seg)
);

endmodule