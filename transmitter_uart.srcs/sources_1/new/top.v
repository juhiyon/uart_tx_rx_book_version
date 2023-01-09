`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/12/09 16:00:22
// Design Name: 
// Module Name: top
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


module top(rst,clk,wr,sw,txd,txrdy);
input rst,clk;//reset, 시리얼 클록
input wr;//송신 데이터 판별 신호
input [1:0] sw;
reg [7:0] d_in=8'b00000000;//송신용 데이터
output txd;//송신 데이터
output txrdy;//송신 데이터 가능 플래그

always @(sw[0] or sw[1])
begin
    if(sw[0] == 1 && sw[1] == 0)
    begin
        d_in <= 8'h54;
    end
    else if(sw[0] == 0 && sw[1] == 1)
    begin
        d_in <= 8'h53;
    end
    else
    begin
        d_in <= 8'h55;
    end
end

reg txd;//나중에 always안에 들어가니 reg선언 필요

reg [7:0]txhold;//송신 데이터 홀딩 레지스터
reg [7:0]txreg;//송신 시프트 레지스터
reg txtag2;//송신 완전 끝 검사 위한 비트
reg txtag1;//송신 완전 끝 검사 위한 비트, txtag2 txtag1 txreg ->
reg txparity;//패리티 비트

reg txclk;//송신 클록
wire txdone;//1:txtag2가 출력 핀에 도달, 즉 송신 완전 끝 0:송신 끝 상태 아닌 경우
wire paritycycle;//1:패리티 사이클
reg txdatardy;//딱 txhold에 적재된 순간에만 1

reg [9:0] clk_count;
reg wr1, wr2;//wr 신호 1,2 사이클 지연 및 엣지 검출 위함, wr->wr1 wr2 -> (txtag1,2느낌)
             //스타트 비트 1txclk동안 0전송이니까 그거 맞추려고 일부러 두개 밀린 듯
reg txdone1;//txdone 신호 1사이클 지연 및 엣지 검출 위함, txdone txdone1->

//wr과 txdone하강 엣지 만들기
always @(posedge clk or negedge rst)
begin
    if(!rst)//리셋이면 클리어
    begin
        wr1 <= 0; wr2 <= 0; txdone1 <= 0;
    end
    else//clk 상승 모서리에서 시프트
    begin
        wr2 <= wr1;
        wr1 <= wr;//wr값은 테벤에서 넣어준다
        txdone1 <= txdone;//
    end
end

//wr과 txdone하강 엣지 때의 동작 기술
always @(posedge clk or negedge rst)
begin
    if(!rst)//리셋이면 클리어
        txdatardy <= 0;//송신 끝, txhold에 데이터 저장 가능
    else
        if(wr1 == 0 & wr2 == 1)//wr 하강 엣지
        begin
            txhold <= d_in;
            txdatardy <= 1;//딱 wr하강에 의해 txhold에 적재했을 때만 txdatardy=1이며, 그 외의 경우는 0
        end
        else if(txdone ==0 & txdone1 == 1)//txdone 하강 엣지때 txdatady=0이 된다.
            txdatardy <= 0;//적재된 이후는 일단 txdone이 1에서 0으로 하강 엣지가 되어 txdatardy=0, 그 뒤에 송신 끝나서 1된다해도 상승 엣지라 그대로 유지
                           //즉 (송신 끝나 txdone=1상태) -> wr이 하강엣지->txhold적재, "txdatardy=1"->txreg에 적재->txdone=0->"txdatardy=0"->데이터 송신 끝나면 txdone=1->계속 반복
end

//송신용 시프트 클럭 txclk 만들기
//1비트 보낼 때 clk16개 필요, 따라서 8비트 마다 토글시켜 총 16비트 주기 만들면 됨
always @(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        clk_count <= 0; txclk <= 0;
    end
    else
    begin
        clk_count <= clk_count+1;
        if(clk_count == 542)//
        begin
            txclk <= ~txclk;//8비트마다 토글, 16비트 주기의 txclk만들어짐
            clk_count <= 0;
        end
    end
end

//송신 시프트
always @(posedge txclk or negedge rst)
begin : txshift
    if(!rst)
    begin
        txreg <= 0;
        txtag1 <= 0;
        txtag2 <= 0;
        txparity <= 0;
    end
    else//txclk 상승 모서리에서
        if((txdone & txdatardy)==1)//송신 완전히 끝나고, wr하강에 의해 txhold에 데이터 실려 있으면
        begin
            txreg <= txhold;
            txtag2 <= 1;
            txtag1 <= 1;
            txparity <= 1;
        end
        else//txreg에 적재됐으니 txdone=0이며 이에 따라 txdatardy도 0
        begin
            txreg <= {txtag1, txreg[7:1]};
            txtag1 <= txtag2;
            txtag2 <= 0;
            txparity <= txparity ^ txreg[0];//최종 txparity가 1:최초 txparity까지 합쳐서 1가 홀수개, 0: 1가 짝수개
        end
end
//갑자기 왜 저 조건이 만족되면서 txreg에 적재가 될까? -> 이 전 것 연산 끝나서 txdone=1, wr하강에 의해 txhold에 적재하면서 txdatardy=1 되기 때문
//그렇다면 데이타 흐름에서 1->0 될 수 있지


//송신
always @(posedge txclk or negedge rst)
begin : tx_out
    if(!rst)    txd<=1;//reset이면 송신 신호 클리어, 왜냐? 스톱비트까지 전송 끝나면 txd출력 1이니 그때랑 같다고 보는 것
    else if(txdatardy)  txd<=0;//딱 스타트 비트 때만 흘림
    else if(paritycycle)    txd<=txparity;//초기 txtag2=1가 txreg[1]에 도달했을 때 txparity 출력
    else if(txdone) txd<=1;//스톱 비트 출력
    else txd <= txreg[0];
end

//txtag2가 txreg[1]에 도달했을 때 paritycycle = 1
//초기 txtag2=1가 txreg[1]에 도달했을때, 그 따라오는 비트들은 모두 0이어야 함
assign paritycycle = txreg[1] & ~(txtag2 | txtag1 | (| txreg[5:2]));
//|므로 1이 하나라도 있으면 0, 즉 초기 설정(txtag2=1이 다 나갈때까지 txdone은 0, 완전히 끝나면 그때 1
assign txdone = ~(txtag2 | txtag1 | (| txreg[7:0]));//어차피 최하위 비트부터 가는거라서 000111이런건 걍 111만 보내도 되는것..!! 10000011이건 검출 되잖아.
assign txrdy = ~txdatardy;

endmodule