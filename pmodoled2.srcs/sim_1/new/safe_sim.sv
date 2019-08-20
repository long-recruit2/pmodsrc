`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/07/26 22:33:51
// Design Name: 
// Module Name: safe_sim
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


module safe_sim;
    logic clk;
    logic [3:0] row;
    logic [3:0] col;
    logic [3:0] led;
    logic led5_r;
    logic led5_b;
    logic led6_r;
    logic [7:0] jb;
    logic [7:0] je;
    logic rst;

    localparam CLK_FREQ = 125e6;
    localparam CLK_HALF_PERIOD = 1/real'(CLK_FREQ)*1000e6/2;
    localparam DRIVE_DLY = 1;

    always begin
        #CLK_HALF_PERIOD clk = 1;
        #CLK_HALF_PERIOD clk = 0;
    end

    default clocking cb@(posedge clk);
    endclocking

    bootstrap s(
        .sysclk(clk),
        .rst(rst),
        .row(row),
        .col(col),
        .led(led),
        .led5_r(led5_r),
        .led5_b(led5_b),
        .led6_b(led6_b),
        .je(jb)
        // .je(je)
    );

    localparam POLL_PERIOD = 1e-3;
    localparam int CLK_DIV_COUNT = 125000;
    
    initial begin
        clk <= 0;
        rst <= 1;
        $display("Current time = %t", $time);
        ##(CLK_DIV_COUNT)
        rst <= 0;
        ##1000000000
        ;
        ##1000000000
        ;
        ##100000000
        ;
        $finish();
    end
endmodule
