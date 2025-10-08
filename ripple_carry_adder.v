`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.10.2025 02:13:03
// Design Name: 
// Module Name: ripple_carry_adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//Full Adder:
module full_adder(    
    input  a, b, cin,
    output sum, cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule

module ripple_carry_adder (
    input  [7:0] A,
    input  [7:0] B,
    input        Cin,
    output [7:0] Sum,
    output       Cout
);
    wire [7:0] carry;
  //  genvar i;

    // LSB adder
    full_adder fa0(A[0], B[0], Cin, Sum[0], carry[0]);
    
    
//    generate 
//        for (i=1; i<8; i = i +1) begin
//            full_adder fa(A[i], B[i], carry[i-1], Sum[i], carry[i]);        
//        end 
//    endgenerate 
    
    assign Cout = carry[7];

    // Next adders
    full_adder fa1(A[1], B[1], carry[0], Sum[1], carry[1]);
    full_adder fa2(A[2], B[2], carry[1], Sum[2], carry[2]);
    full_adder fa3(A[3], B[3], carry[2], Sum[3], carry[3]);
    full_adder fa4(A[4], B[4], carry[3], Sum[4], carry[4]);
    full_adder fa5(A[5], B[5], carry[4], Sum[5], carry[5]);
    full_adder fa6(A[6], B[6], carry[5], Sum[6], carry[6]);
    full_adder fa7(A[7], B[7], carry[6], Sum[7], carry[7]);

endmodule

