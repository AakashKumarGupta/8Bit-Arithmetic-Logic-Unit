`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Aakash Semiconductor Pvt. Ltd.
// Engineer: Aakash Kumar Gupta
// 
// Create Date: 02.10.2025 
// Design Name: 8-bit Arithmetic Logic Unit   
// Module Name: ALU_8bit
// Project Name: 8-bit ALU with Multiple Operations
// Target Devices: FPGA/ASIC
// Tool Versions: Vivado
// Description: 
//     8-bit ALU supporting 15 operations including arithmetic, logical, 
//     shift, and rotate operations. Features flag generation for Zero, 
//     Sign, Carry, Parity, and Overflow conditions.
// 
// Operations Supported:
//     0000: ADD  - Addition with carry
//     0001: SUB  - Subtraction with borrow
//     0010: AND  - Bitwise AND
//     0011: OR   - Bitwise OR
//     0100: XOR  - Bitwise XOR
//     0101: NAND - Bitwise NAND
//     0110: NOR  - Bitwise NOR
//     0111: XNOR - Bitwise XNOR
//     1000: NOT  - Bitwise NOT (complement of A)
//     1001: INC  - Increment A by 1
//     1010: DEC  - Decrement A by 1
//     1011: SLL  - Shift Left Logical by B[2:0] positions
//     1100: SRL  - Shift Right Logical by B[2:0] positions
//     1101: ROL  - Rotate Left by B[2:0] positions
//     1110: ROR  - Rotate Right by B[2:0] positions
//
// Flags:
//     CarryOut - Set when operation produces carry/borrow
//     Zero     - Set when result is all zeros
//     Sign     - Set when MSB of result is 1 (negative in signed)
//     Parity   - Set when result has even number of 1s
//     Overflow - Set when signed arithmetic overflows
// 
// Dependencies: ripple_carry_adder, full_adder modules
// 
// Revision:
// Revision 0.02 - Bug fixes for rotate operations and overflow detection
// Additional Comments:
//     - Synchronous design with clock and reset
//     - Enable signal allows holding previous result
//     - All outputs are registered for better timing
// 
//////////////////////////////////////////////////////////////////////////////////

module ALU_8bit (
    input  [7:0] A,           // First operand
    input  [7:0] B,           // Second operand
    input  [3:0] Operation,   // Operation selector (0000 to 1110)
    input  clk,               // Clock signal
    input  reset,             // Active high reset
    input  enable,            // Enable signal (1=active, 0=hold)
    output reg [7:0] Result,  // Operation result
    output reg CarryOut,      // Carry/Borrow flag
    output reg Zero,          // Zero flag
    output reg Sign,          // Sign flag (MSB of result)
    output reg Parity,        // Parity flag (even parity)
    output reg Overflow       // Overflow flag for signed arithmetic
);

    // Parameters for better code readability
    parameter DATA_WIDTH = 8;
    parameter OP_WIDTH = 4;
    
    // Operation code definitions for clarity
    localparam OP_ADD  = 4'b0000;  // Addition
    localparam OP_SUB  = 4'b0001;  // Subtraction
    localparam OP_AND  = 4'b0010;  // Bitwise AND
    localparam OP_OR   = 4'b0011;  // Bitwise OR
    localparam OP_XOR  = 4'b0100;  // Bitwise XOR
    localparam OP_NAND = 4'b0101;  // Bitwise NAND
    localparam OP_NOR  = 4'b0110;  // Bitwise NOR
    localparam OP_XNOR = 4'b0111;  // Bitwise XNOR
    localparam OP_NOT  = 4'b1000;  // Bitwise NOT
    localparam OP_INC  = 4'b1001;  // Increment
    localparam OP_DEC  = 4'b1010;  // Decrement
    localparam OP_SLL  = 4'b1011;  // Shift Left Logical
    localparam OP_SRL  = 4'b1100;  // Shift Right Logical
    localparam OP_ROL  = 4'b1101;  // Rotate Left
    localparam OP_ROR  = 4'b1110;  // Rotate Right
    
    // Internal wires from adder/subtractor modules
    wire [7:0] add_sum;       // Sum output from adder
    wire [7:0] sub_sum;       // Sum output from subtractor
    wire add_cout;            // Carry out from adder
    wire sub_cout;            // Carry out from subtractor
    
    // Combinational result wires (calculated before clock edge)
    reg [7:0] Next_Result_W;   // Next result value
    reg Next_CarryOut_W;       // Next carry value
    reg Next_Overflow_W;       // Next overflow value

    // Ripple carry adder for addition: A + B + 0
    ripple_carry_adder ADDER_CIRCUIT( 
        .A(A), 
        .B(B),
        .Cin(1'b0),           // No carry input for addition
        .Sum(add_sum),        // Result of addition
        .Cout(add_cout)       // Carry output
    ); 
    
    // Ripple carry adder configured for subtraction: A - B = A + (~B) + 1
    // This implements 2's complement subtraction
    ripple_carry_adder SUBBER (
        .A(A), 
        .B(~B),               // Invert B (1's complement)
        .Cin(1'b1),           // Add 1 to complete 2's complement
        .Sum(sub_sum),        // Result of subtraction
        .Cout(sub_cout)       // Carry output (inverse of borrow)
    );
    
    //=========================================================================
    // COMBINATIONAL LOGIC - Calculate next result based on operation
    // This always block executes whenever inputs change
    //=========================================================================
    always @(*) begin
        // Default values to avoid latches
        Next_Result_W = 8'b0;
        Next_CarryOut_W = 1'b0;
        Next_Overflow_W = 1'b0;
        
        case (Operation)
            //=================================================================
            // ARITHMETIC OPERATIONS
            //=================================================================
            OP_ADD: begin 
                // Addition: A + B
                Next_Result_W = add_sum; 
                Next_CarryOut_W = add_cout;
                // Overflow occurs when both operands have same sign but result differs
                // Positive + Positive = Negative (overflow)
                // Negative + Negative = Positive (overflow)
                Next_Overflow_W = (A[7] & B[7] & ~add_sum[7]) | (~A[7] & ~B[7] & add_sum[7]);
            end

            OP_SUB: begin 
                // Subtraction: A - B (using 2's complement)
                Next_Result_W = sub_sum;
                Next_CarryOut_W = sub_cout;  // Carry = NOT Borrow in subtraction
                // Overflow when operands have different signs and result differs from A
                Next_Overflow_W = (A[7] & ~B[7] & ~sub_sum[7]) | (~A[7] & B[7] & sub_sum[7]);
            end
            
            //=================================================================
            // LOGICAL OPERATIONS
            //=================================================================
            OP_AND:  Next_Result_W = A & B;          // Bitwise AND
            OP_OR:   Next_Result_W = A | B;          // Bitwise OR
            OP_XOR:  Next_Result_W = A ^ B;          // Bitwise XOR
            OP_NAND: Next_Result_W = ~(A & B);       // Bitwise NAND
            OP_NOR:  Next_Result_W = ~(A | B);       // Bitwise NOR
            OP_XNOR: Next_Result_W = ~(A ^ B);       // Bitwise XNOR (equivalence)
            OP_NOT:  Next_Result_W = ~A;             // Bitwise NOT (complement)
            
            //=================================================================
            // INCREMENT/DECREMENT OPERATIONS
            //=================================================================
            OP_INC: begin 
                // Increment A by 1
                Next_Result_W = A + 8'b0000_0001;
                Next_CarryOut_W = (A == 8'hFF);  // Carry when wrapping from FF to 00
                // Overflow: 0x7F + 1 = 0x80 (127 + 1 = -128 in signed)
                Next_Overflow_W = (A == 8'h7F);
            end
            
            OP_DEC: begin 
                // Decrement A by 1
                Next_Result_W = A - 8'b0000_0001;
                Next_CarryOut_W = (A == 8'h00);  // Borrow when decrementing 0
                // Overflow: 0x80 - 1 = 0x7F (-128 - 1 = 127 in signed)
                Next_Overflow_W = (A == 8'h80);
            end 

            //=================================================================
            // SHIFT OPERATIONS
            // Use only B[2:0] for shift amount (0-7 positions)
            //=================================================================
            OP_SLL: begin 
                // Shift Left Logical: A << B[2:0]
                Next_Result_W = A << B[2:0];
                // Carry flag = last bit shifted out (if shift amount > 0)
                if (B[2:0] != 3'b000 && B[2:0] <= 4'd8)
                    Next_CarryOut_W = A[8 - B[2:0]];  // Bit that was shifted out
            end
            
            OP_SRL: begin 
                // Shift Right Logical: A >> B[2:0]
                Next_Result_W = A >> B[2:0];
                // Carry flag = last bit shifted out (if shift amount > 0)
                if (B[2:0] != 3'b000 && B[2:0] <= 4'd8)
                    Next_CarryOut_W = A[B[2:0] - 1];  // Bit that was shifted out
            end
            
            //=================================================================
            // ROTATE OPERATIONS
            // Rotate combines left shift and right shift to wrap bits around
            //=================================================================
            OP_ROL: begin 
                // Rotate Left: bits shifted out on left reappear on right
                if (B[2:0] == 3'b000)
                    Next_Result_W = A;  // No rotation if amount is 0
                else
                    // Rotate = (shift left) OR (shift right by complement amount)
                    Next_Result_W = (A << B[2:0]) | (A >> (8 - B[2:0]));
                // Carry = bit that rotated from MSB position
                if (B[2:0] != 3'b000)
                    Next_CarryOut_W = A[8 - B[2:0]];
            end
            
            OP_ROR: begin 
                // Rotate Right: bits shifted out on right reappear on left
                if (B[2:0] == 3'b000)
                    Next_Result_W = A;  // No rotation if amount is 0
                else
                    // Rotate = (shift right) OR (shift left by complement amount)
                    Next_Result_W = (A >> B[2:0]) | (A << (8 - B[2:0]));
                // Carry = bit that rotated from LSB position
                if (B[2:0] != 3'b000)
                    Next_CarryOut_W = A[B[2:0] - 1];
            end
            
            //=================================================================
            // DEFAULT CASE
            //=================================================================
            default: begin
                Next_Result_W = 8'b0;
                Next_CarryOut_W = 1'b0;
                Next_Overflow_W = 1'b0;
            end
        endcase
    end

    //=========================================================================
    // FLAG GENERATION (Combinational)
    // These flags are calculated based on the result
    //=========================================================================
    wire Next_Zero_W   = (Next_Result_W == 8'b0);     // Zero flag: 1 if result is 0
    wire Next_Sign_W   = Next_Result_W[7];            // Sign flag: MSB of result
    wire Next_Parity_W = ~(^Next_Result_W);           // Parity: 1 if even number of 1s
                                                       // ^ is XOR reduction operator
    
    //=========================================================================
    // SEQUENTIAL LOGIC - Register outputs on clock edge
    // All outputs are synchronized to clock for better timing
    //=========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Asynchronous reset: clear all outputs immediately
            Result   <= 8'b0;
            CarryOut <= 1'b0;
            Zero     <= 1'b0;
            Sign     <= 1'b0;
            Parity   <= 1'b0;
            Overflow <= 1'b0;
        end 
        else if (enable) begin
            // When enabled, register the calculated values on clock edge
            Result   <= Next_Result_W;
            CarryOut <= Next_CarryOut_W;
            Overflow <= Next_Overflow_W;
            Zero     <= Next_Zero_W;
            Sign     <= Next_Sign_W;
            Parity   <= Next_Parity_W;
        end
        // If enable=0, outputs hold their previous values
    end

endmodule