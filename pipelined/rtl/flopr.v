module flopr #(parameter WIDTH = 8)
              (input  logic             clk, reset,
               input  logic [WIDTH-1:0] reset_data,
               input  logic [WIDTH-1:0] data,
               output logic [WIDTH-1:0] q);

    always_ff @(posedge clk)
                if (reset) q <= reset_data;
                else       q <= data;

endmodule
