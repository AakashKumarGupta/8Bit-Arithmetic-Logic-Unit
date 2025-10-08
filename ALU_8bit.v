`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Aakash Semiconductor Pvt. Ltd.
// Engineer: Aakash Kumar Gupta
// 
// Create Date: 02.10.2025 
// Design Name: 8-bit Arithmetic Logic Unit   
// Module Name: ALU_8bit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 8-bit ALU with arithmetic, logical, shift, and rotate operations
//              CORRECTED VERSION - Fixed rotate logic, shift carry, and overflow
// 
// Dependencies: ripple_carry_adder module (included below)
// 
// Revision:
// Revision 0.02 - Bug Fixes Applied
// Additional Comments:
// - Fixed rotate operations for B[2:0] = 0 edge case
// - Added carry flag for shift operations
// - Corrected overflow logic for INC/DEC
// - Added operation code parameters for clarity
// 
//////////////////////////////////////////////////////////////////////////////////

module ALU_8bit (
    input  [7:0] A, B,
    input  [3:0] Operation,   
    input  clk,
    input  reset,
    input  enable,    
    output reg [7:0] Result,
    output reg CarryOut,
    output reg Zero,
    output reg Sign,
    output reg Parity,
    output reg Overflow
);

    // Parameters for better readability
    parameter DATA_WIDTH = 8;
    parameter OP_WIDTH = 4;
    
    // Operation Code Definitions
    localparam OP_ADD  = 4'b0000;
    localparam OP_SUB  = 4'b0001;
    localparam OP_AND  = 4'b0010;
    localparam OP_OR   = 4'b0011;
    localparam OP_XOR  = 4'b0100;
    localparam OP_NAND = 4'b0101;
    localparam OP_NOR  = 4'b0110;
    localparam OP_XNOR = 4'b0111;
    localparam OP_NOT  = 4'b1000;
    localparam OP_INC  = 4'b1001;
    localparam OP_DEC  = 4'b1010;
    localparam OP_SLL  = 4'b1011;  // Shift Left Logical
    localparam OP_SRL  = 4'b1100;  // Shift Right Logical
    localparam OP_ROL  = 4'b1101;  // Rotate Left
    localparam OP_ROR  = 4'b1110;  // Rotate Right
    
    // Internal wires for adder/subtractor
    wire [7:0] add_sum, sub_sum;
    wire add_cout, sub_cout;
    
    // Combinational result wires
    reg [7:0] Next_Result_W;
    reg Next_CarryOut_W;
    reg Next_Overflow_W;

    // Instantiate RCA for addition
    ripple_carry_adder ADDER_CIRCUIT( 
        .A(A), 
        .B(B),
        .Cin(1'b0), 
        .Sum(add_sum), 
        .Cout(add_cout)
    ); 
    
    // For subtraction: A - B = A + (~B + 1) using 2's complement
    ripple_carry_adder SUBBER (
        .A(A), 
        .B(~B), 
        .Cin(1'b1),
        .Sum(sub_sum), 
        .Cout(sub_cout)
    );
    
    // Combinational logic for operation execution
    always @(*) begin
        // Default values
        Next_Result_W = 8'b0;
        Next_CarryOut_W = 1'b0;
        Next_Overflow_W = 1'b0;
        
        case (Operation)
            OP_ADD: begin // ADD operation
                Next_Result_W = add_sum; 
                Next_CarryOut_W = add_cout;
                // Overflow when both operands have same sign but result differs
                Next_Overflow_W = (A[7] & B[7] & ~add_sum[7]) | (~A[7] & ~B[7] & add_sum[7]);
            end

            OP_SUB: begin // SUB operation (A - B)
                Next_Result_W = sub_sum;
                Next_CarryOut_W = sub_cout;  // Carry = NOT Borrow
                // Overflow when operands have different signs and result differs from A
                Next_Overflow_W = (A[7] & ~B[7] & ~sub_sum[7]) | (~A[7] & B[7] & sub_sum[7]);
            end
            
            OP_AND:  Next_Result_W = A & B;          // AND
            OP_OR:   Next_Result_W = A | B;          // OR
            OP_XOR:  Next_Result_W = A ^ B;          // XOR
            OP_NAND: Next_Result_W = ~(A & B);       // NAND
            OP_NOR:  Next_Result_W = ~(A | B);       // NOR
            OP_XNOR: Next_Result_W = ~(A ^ B);       // XNOR
            OP_NOT:  Next_Result_W = ~A;             // NOT
            
            OP_INC: begin // INCREMENT
                Next_Result_W = A + 8'b0000_0001;
                Next_CarryOut_W = (A == 8'hFF);  // Carry on overflow to 0
                // Overflow when incrementing max positive (0x7F) to negative (0x80)
                Next_Overflow_W = (A == 8'h7F);
            end
            
            OP_DEC: begin // DECREMENT
                Next_Result_W = A - 8'b0000_0001;
                Next_CarryOut_W = (A == 8'h00);  // Borrow when decrementing 0
                // Overflow when decrementing min negative (0x80) wraps to positive (0x7F)
                Next_Overflow_W = (A == 8'h80);
            end 

            OP_SLL: begin // Logical Left Shift
                Next_Result_W = A << B[2:0];
                // Carry = last bit shifted out (MSB before shift if shift amount > 0)
                if (B[2:0] != 3'b000 )
                    Next_CarryOut_W = A[8 - B[2:0]];
            end
            
            OP_SRL: begin // Logical Right Shift
                Next_Result_W = A >> B[2:0];
                // Carry = last bit shifted out (LSB before shift if shift amount > 0)
                if (B[2:0] != 3'b000)
                    Next_CarryOut_W = A[B[2:0] - 1];
            end
            
            OP_ROL: begin // Rotate Left
                // Fixed: Handle B[2:0] = 0 case where rotate by 0 should return A unchanged
                if (B[2:0] == 3'b000)
                    Next_Result_W = A;
                else
                    Next_Result_W = (A << B[2:0]) | (A >> (8 - B[2:0]));
                // Carry = MSB after rotation (which was at position 8-shift before rotation)
                if (B[2:0] != 3'b000)
                    Next_CarryOut_W = A[8 - B[2:0]];
            end
            
            OP_ROR: begin // Rotate Right
                // Fixed: Handle B[2:0] = 0 case where rotate by 0 should return A unchanged
                if (B[2:0] == 3'b000)
                    Next_Result_W = A;
                else
                    Next_Result_W = (A >> B[2:0]) | (A << (8 - B[2:0]));
                // Carry = LSB after rotation (which was at position shift-1 before rotation)
                if (B[2:0] != 3'b000)
                    Next_CarryOut_W = A[B[2:0] - 1];
            end
            
            default: begin
                Next_Result_W = 8'b0;
                Next_CarryOut_W = 1'b0;
                Next_Overflow_W = 1'b0;
            end
        endcase
    end

    // Combinational Flag Generation based on Next_Result_W
    wire Next_Zero_W   = (Next_Result_W == 8'b0);
    wire Next_Sign_W   = Next_Result_W[7];
    wire Next_Parity_W = ~(^Next_Result_W); // Even parity (1 if even number of 1s)
    
    // Sequential logic for registering outputs
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            Result   <= 8'b0;
            CarryOut <= 1'b0;
            Zero     <= 1'b0;
            Sign     <= 1'b0;
            Parity   <= 1'b0;
            Overflow <= 1'b0;
        end 
        else if (enable) begin
            Result   <= Next_Result_W;
            CarryOut <= Next_CarryOut_W;
            Overflow <= Next_Overflow_W;
            Zero     <= Next_Zero_W;
            Sign     <= Next_Sign_W;
            Parity   <= Next_Parity_W;
        end
        // If enable = 0, hold previous values
    end

endmodule


////////////////////////////////////////////////////////////////////////////////////
//// Ripple Carry Adder Module
//// 8-bit full adder using ripple carry architecture
////////////////////////////////////////////////////////////////////////////////////
//module ripple_carry_adder (
//    input  [7:0] A,
//    input  [7:0] B,
//    input  Cin,
//    output [7:0] Sum,
//    output Cout
//);

//    wire [8:0] carry;  // Internal carry chain (9 bits for 8 full adders)
    
//    assign carry[0] = Cin;
    
//    // Generate 8 full adders
//    genvar i;
//    generate
//        for (i = 0; i < 8; i = i + 1) begin : full_adder_chain
//            full_adder FA (
//                .a(A[i]),
//                .b(B[i]),
//                .cin(carry[i]),
//                .sum(Sum[i]),
//                .cout(carry[i+1])
//            );
//        end
//    endgenerate
    
//    assign Cout = carry[8];

//endmodule


////////////////////////////////////////////////////////////////////////////////////
//// Full Adder Module
//// Single bit full adder
////////////////////////////////////////////////////////////////////////////////////
//module full_adder (
//    input  a,
//    input  b,
//    input  cin,
//    output sum,
//    output cout
//);

//    assign sum  = a ^ b ^ cin;
//    assign cout = (a & b) | (b & cin) | (a & cin);

//endmodule