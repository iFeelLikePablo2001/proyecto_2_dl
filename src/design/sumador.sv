module sumador (
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