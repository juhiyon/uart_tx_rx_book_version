`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/12/15 17:30:19
// Design Name: 
// Module Name: top_tb
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

module top_tb;
reg rst, clk, rd;
reg rxd;
wire rxrdy, pe, fe, oe, out6r, out6g, out6b;
parameter step=10;

uart uart(.rst(rst),.clk(clk),.rd(rd),.rxd(rxd),.rxrdy(rxrdy),.pe(pe),.fe(fe),.oe(oe),.out6r(out6r),.out6g(out6g),.out6b(out6b));

always #(step/2) clk=~clk;
initial begin
    clk=1; rst=0; rd=0; rxd=0;
    rst =1; rd=1; rxd=1; #(step*542*2);
    rxd=0; #(step*542*2);
    rxd=0; #(step*542*2);
    rxd=0; #(step*542*2);
    rxd=0; #(step*542*2);
    rxd=0; #(step*542*2);
    rxd=1; #(step*542*2);
    rxd=0; #(step*542*2);
    rxd=0; #(step*542*2);
    rxd=1; #(step*542*2);
    $stop;
end
endmodule
