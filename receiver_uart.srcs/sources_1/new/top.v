module top(rst, clk, rd, rxd, out6r, out6g, out6b, pe, fe, oe, rxrdy);
input rst, clk, rd, rxd;
output reg out6r, out6g, out6b;
output pe,fe,oe;
output rxrdy;
reg [7:0] d;
reg pe, fe, oe;
reg [7:0] rxhold;
reg [7:0] rxreg;
reg rxparity;
reg paritygen;
reg rxstop;
reg rxclk;
reg rxidle;
reg rxdatardy;
reg [10:0] rxcnt;
reg rx1;
reg hunt;
reg rd1, rd2;
reg rxidle1;

always @(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        hunt <=0;   rxcnt<=0;   rx1<=0; rxclk<=0;
    end
    else
    begin
        rxcnt <= rxcnt+1;
        if(rxcnt == 542)
        begin
            rxclk <= ~rxclk;
            rxcnt <= 0;
        end
        rx1<=rxd;   
        if(rxidle == 1 & rxd == 0 & rx1 ==1)
            hunt <= 1;
        if(rxidle ==0 | rxd == 1)
            hunt <= 0;
        if(rxidle==0 | hunt ==1)
            rxcnt<=rxcnt+1;
        else    rxcnt <= 4'b0001;
    end
end

always @(posedge rxclk or negedge rst)
begin
    if(!rst)
    begin
        rxreg <= 8'h00; rxparity<=0;
        paritygen<=0;   rxstop<=0;
    end
    else
    if(rxidle)
    begin
        rxreg <= 8'hff;
        rxparity<=1;
        paritygen<=1;
        rxstop<=0;
    end
    else
    begin
        rxreg <= { rxparity, rxreg[7:1]};
        rxparity<=rxstop;
        paritygen<=paritygen^rxstop;
        rxstop<=rxd;
    end
end

always @(posedge rxclk or negedge rst)
begin
    if(!rst)    rxidle <=0;
    else
        rxidle <= ~rxidle& ~rxreg[0];
end

always @(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        rd1<=0; rd2<=0; rxidle1<=0;
    end
    else
    begin
        rxidle1 <= rxidle;
        rd2<= rd1;
        rd1<=rd;
    end
end

always @(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        oe <=0; pe <=0; fe <=0;
        rxhold<=0;  rxdatardy<=0; 
    end
    else
    begin
        if(rd1==0 & rd2==1)
        begin
            d<=rxhold;
            rxdatardy<=0;
            pe<=0;  fe<=0;  oe<=0;
        end
        if(rxidle==1 & rxidle1 ==0)
        begin
            if(rxdatardy)   oe<=1;
            else
            begin
                oe<=0;
                rxhold<=rxreg;
                pe<=paritygen;
                fe<=~rxstop;
                rxdatardy<=1;
            end
        end
    end
end

always @(d)
begin
    if(d == 8'h52)
    begin
        out6r <= 1;
        out6g <= 0;
        out6b <= 0;
    end
    else if(d == 8'h47)
    begin
        out6r <= 0;
        out6g <= 1;
        out6b <= 0;
    end
    else if(d == 8'h42)
    begin
        out6r <= 0;
        out6g <= 0;
        out6b <= 1;
    end
    else
    begin
        out6r <= 0;
        out6g <= 0;
        out6b <= 0;
    end  
end
assign rxrdy=rxdatardy;
endmodule
