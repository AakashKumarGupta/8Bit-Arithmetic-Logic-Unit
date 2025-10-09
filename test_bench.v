//////////////////////////////////////////////////////////////////////////////////
// Module: full_adder
// Description: Single bit full adder
//              Implements: sum = a XOR b XOR cin
//                         cout = (a AND b) OR (b AND cin) OR (a AND cin)
//////////////////////////////////////////////////////////////////////////////////
module full_adder (
    input  a,      // First input bit
    input  b,      // Second input bit
    input  cin,    // Carry input
    output sum,    // Sum output
    output cout    // Carry output
);

    // Sum: XOR of all three inputs
    assign sum  = a ^ b ^ cin;
    
    // Carry out: majority function (at least 2 inputs are 1)
    assign cout = (a & b) | (b & cin) | (a & cin);

endmodule


//////////////////////////////////////////////////////////////////////////////////
// SIMPLE TESTBENCH
// Description: Basic testbench to verify ALU functionality
//              Tests each operation with sample inputs
//////////////////////////////////////////////////////////////////////////////////
module ALU_8bit_simple_tb;

    // Testbench signals
    reg [7:0] A, B;
    reg [3:0] Operation;
    reg clk, reset, enable;
    wire [7:0] Result;
    wire CarryOut, Zero, Sign, Parity, Overflow;
    
    // Instantiate the ALU
    ALU_8bit uut (
        .A(A), .B(B), .Operation(Operation),
        .clk(clk), .reset(reset), .enable(enable),
        .Result(Result), .CarryOut(CarryOut), .Zero(Zero),
        .Sign(Sign), .Parity(Parity), .Overflow(Overflow)
    );
    
    // Clock generation: 10ns period (100MHz)
    always #5 clk = ~clk;
    
    // Helper function to get operation name
    function [63:0] op_name;
        input [3:0] op;
        case(op)
            4'b0000: op_name = "ADD";
            4'b0001: op_name = "SUB";
            4'b0010: op_name = "AND";
            4'b0011: op_name = "OR";
            4'b0100: op_name = "XOR";
            4'b0101: op_name = "NAND";
            4'b0110: op_name = "NOR";
            4'b0111: op_name = "XNOR";
            4'b1000: op_name = "NOT";
            4'b1001: op_name = "INC";
            4'b1010: op_name = "DEC";
            4'b1011: op_name = "SLL";
            4'b1100: op_name = "SRL";
            4'b1101: op_name = "ROL";
            4'b1110: op_name = "ROR";
            default: op_name = "???";
        endcase
    endfunction
    
    integer i;
    
    initial begin
        // Initialize
        clk = 0;
        reset = 1;
        enable = 1;
        A = 0; B = 0; Operation = 0;
        
        $display("\n================================");
        $display("   8-bit ALU Test");
        $display("================================\n");
        
        // Release reset
        #15 reset = 0;
        #10;
        
        // Test each operation
        $display("Op | A    B    -> Result | Flags");
        $display("---+----------+---------+-------");
        
        // Test all operations with sample values
        for (i = 0; i < 15; i = i + 1) begin
            @(negedge clk);
            A = 8'hA5;              // Sample input
            B = 8'h3C;              // Sample input
            Operation = i;
            @(posedge clk);
            #1;
            $display("%s| %h   %h -> %h     | C:%b Z:%b S:%b P:%b V:%b", 
                     op_name(Operation), A, B, Result, 
                     CarryOut, Zero, Sign, Parity, Overflow);
        end
        
        $display("\n--- Special Cases ---");
        
        // Test overflow
        @(negedge clk);
        A = 8'h7F; B = 8'h01; Operation = 4'b0000;
        @(posedge clk); #1;
        $display("Overflow: %h + %h = %h (V=%b)", A, B, Result, Overflow);
        
        // Test zero flag
        @(negedge clk);
        A = 8'h50; B = 8'h50; Operation = 4'b0001;
        @(posedge clk); #1;
        $display("Zero: %h - %h = %h (Z=%b)", A, B, Result, Zero);
        
        // Test rotate by 0 (bug fix verification)
        @(negedge clk);
        A = 8'hAB; B = 8'h00; Operation = 4'b1101;
        @(posedge clk); #1;
        $display("ROL by 0: %h -> %h (should be same)", A, Result);
        
        $display("\n================================");
        $display("   Test Complete!");
        $display("================================\n");
        
        #20 $finish;
    end

endmodule
