`include "alucontrol.v"
`include "instr_opcodes.v"

module aludec(input  logic [6:0] opcode,
              input  logic [2:0] funct3,
              input  logic       funct7b5,
              input  logic [1:0] ALUOp,
              output logic [3:0] ALUControl,
              output logic InverseBrCondD);

    logic RtypeSub;
    assign RtypeSub = funct7b5 & opcode[5]; // TRUE for R-type subtract

    assign InverseBrCondD = funct3[0];

    always_comb
        case(ALUOp)
            2'b00:          ALUControl = `ALU_ADD; // addition
            2'b01:          ALUControl = `ALU_SUB; // subtraction
            default: case(funct3) // R-type or I-type ALU
                        3'b000: if (RtypeSub)
                                    ALUControl = `ALU_SUB; // sub
                                else
                                    ALUControl = `ALU_ADD; // add, addi
                        3'b001:     ALUControl = `ALU_SLL; // sll, slli
                        3'b010:     ALUControl = `ALU_LESS; // slt, slti
                        3'b101:     ALUControl = funct7b5 ? `ALU_SRA : `ALU_SRL;
                        3'b110:     ALUControl = `ALU_OR; // or, ori
                        3'b111:     ALUControl = `ALU_AND; // and, andi
                        default: begin
                            $display("Unknown alu control command: %d", ALUControl);
                            ALUControl = 4'bxxxx;
                        end
                    endcase
        endcase
endmodule
