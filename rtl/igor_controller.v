module igor_controller(
    input  logic        clk,
    input  logic [31:0] InstrFInFirst,
    output logic [31:0] InstrFResult,
    output multiInstrStall
);

    logic [6:0] funct7;
    logic [4:0] rs2, rs1, rd;
    logic [2:0] funct3;
    logic [6:0] opcode;

    logic [31:0] InstrFIn;

    assign funct7 = InstrFIn[31:25];
    assign funct3 = InstrFIn[14:12];
    assign opcode = InstrFIn[6:0];

    assign rd = InstrFIn[11:7];

    assign rs2 = InstrFIn[24:20];
    assign rs1 = InstrFIn[19:15];

    logic [4:0] counter;
    logic [4:0] rs1_result, rs2_result, rsd_result;

    always_ff @(negedge clk) begin
        if ((funct7 == 7'b1011111) && (funct3 == 3'b111) && (opcode == 7'b1110111) && ((rs1 + counter) <= rs2)) begin
            multiInstrStall <= 1;

            rsd_result <= rd;

            rs2_result <= rs1 + counter + 1;
            rs1_result <= rs1 + counter;

            if (counter == 0) begin
                InstrFResult <= {7'b0000000, 5'b0000, 5'b00000, 3'b000, rd, 7'b0110011};
            end else begin
                InstrFResult <= {7'b0000000, rd, rs1_result, 3'b000, rd, 7'b0110011};
            end
            counter <= counter + 1;
        end else begin
            counter <= 0;
            multiInstrStall <= 0;
            rsd_result <= 0;
            rs2_result <= 0;
            rs1_result <= 0;

            InstrFResult <= InstrFInFirst;
            InstrFIn <= InstrFInFirst;
        end
    end

endmodule
