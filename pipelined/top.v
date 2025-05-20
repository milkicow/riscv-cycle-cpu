
module top(input  logic        clk, reset,
           output logic [31:0] WriteData, DataAdr,
           output logic        MemWrite);

    logic [31:0] PC, Instr, ReadData;

    // instantiate processor and memories
    riscvpipelined rvpipelined(.clk(clk), .reset(reset),
                               .PC(PC), .InstrF(Instr),
                               .MemWrite(MemWrite),
                               .ALUResult(DataAdr),
                               .WriteData(WriteData),
                               .ReadData(ReadData));

    imem imem(PC, Instr);
    dmem dmem(clk, MemWrite, DataAdr, WriteData, ReadData);
endmodule