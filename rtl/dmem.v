module dmem #(parameter HIGH_BIT = 18)
             (input logic         clk, we,
              input logic  [31:0] a, wd,
              output logic [31:0] rd);

    logic [31:0] RAM[0:(1 << HIGH_BIT) - 1];

    assign rd = RAM[a[HIGH_BIT+1:2]]; // word aligned

    always_ff @(posedge clk)
        if (we) RAM[a[HIGH_BIT+1:2]] <= wd;
endmodule
