module flopenr #(parameter WIDTH = 8)
                (input  logic             clk, reset, en,
                 input  logic [WIDTH-1:0] reset_data,
                 input  logic [WIDTH-1:0] d,
                 output logic [WIDTH-1:0] q);

    always_ff @(posedge clk)
        if (reset)      q <= reset_data;
        else if (en)    q <= d;

endmodule
