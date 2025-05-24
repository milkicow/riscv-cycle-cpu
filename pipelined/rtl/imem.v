module imem(input logic [31:0] a,
            output logic [31:0] rd);

    logic [31:0] RAM[0:127] /* verilator public */;

    // initial
    //     $readmemh("../programs_txt/store.mem", RAM);

    assign rd = RAM[a[8:2]]; // word aligned
endmodule
