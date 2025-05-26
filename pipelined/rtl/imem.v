module imem #(parameter HIGH_BIT = 16)
             (input logic [31:0] a,
             output logic [31:0] rd);

    logic [31:0] RAM[0:(1 << HIGH_BIT) - 1] /* verilator public */;

    initial
        $readmemh("../programs_txt/load_use.mem", RAM);

    assign rd = RAM[a[HIGH_BIT+1:2]]; // word aligned
endmodule
