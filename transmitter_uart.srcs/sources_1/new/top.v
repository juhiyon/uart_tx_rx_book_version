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
input rst,clk;//reset, �ø��� Ŭ��
input wr;//�۽� ������ �Ǻ� ��ȣ
input [1:0] sw;
reg [7:0] d_in=8'b00000000;//�۽ſ� ������
output txd;//�۽� ������
output txrdy;//�۽� ������ ���� �÷���

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

reg txd;//���߿� always�ȿ� ���� reg���� �ʿ�

reg [7:0]txhold;//�۽� ������ Ȧ�� ��������
reg [7:0]txreg;//�۽� ����Ʈ ��������
reg txtag2;//�۽� ���� �� �˻� ���� ��Ʈ
reg txtag1;//�۽� ���� �� �˻� ���� ��Ʈ, txtag2 txtag1 txreg ->
reg txparity;//�и�Ƽ ��Ʈ

reg txclk;//�۽� Ŭ��
wire txdone;//1:txtag2�� ��� �ɿ� ����, �� �۽� ���� �� 0:�۽� �� ���� �ƴ� ���
wire paritycycle;//1:�и�Ƽ ����Ŭ
reg txdatardy;//�� txhold�� ����� �������� 1

reg [9:0] clk_count;
reg wr1, wr2;//wr ��ȣ 1,2 ����Ŭ ���� �� ���� ���� ����, wr->wr1 wr2 -> (txtag1,2����)
             //��ŸƮ ��Ʈ 1txclk���� 0�����̴ϱ� �װ� ���߷��� �Ϻη� �ΰ� �и� ��
reg txdone1;//txdone ��ȣ 1����Ŭ ���� �� ���� ���� ����, txdone txdone1->

//wr�� txdone�ϰ� ���� �����
always @(posedge clk or negedge rst)
begin
    if(!rst)//�����̸� Ŭ����
    begin
        wr1 <= 0; wr2 <= 0; txdone1 <= 0;
    end
    else//clk ��� �𼭸����� ����Ʈ
    begin
        wr2 <= wr1;
        wr1 <= wr;//wr���� �׺����� �־��ش�
        txdone1 <= txdone;//
    end
end

//wr�� txdone�ϰ� ���� ���� ���� ���
always @(posedge clk or negedge rst)
begin
    if(!rst)//�����̸� Ŭ����
        txdatardy <= 0;//�۽� ��, txhold�� ������ ���� ����
    else
        if(wr1 == 0 & wr2 == 1)//wr �ϰ� ����
        begin
            txhold <= d_in;
            txdatardy <= 1;//�� wr�ϰ��� ���� txhold�� �������� ���� txdatardy=1�̸�, �� ���� ���� 0
        end
        else if(txdone ==0 & txdone1 == 1)//txdone �ϰ� ������ txdatady=0�� �ȴ�.
            txdatardy <= 0;//����� ���Ĵ� �ϴ� txdone�� 1���� 0���� �ϰ� ������ �Ǿ� txdatardy=0, �� �ڿ� �۽� ������ 1�ȴ��ص� ��� ������ �״�� ����
                           //�� (�۽� ���� txdone=1����) -> wr�� �ϰ�����->txhold����, "txdatardy=1"->txreg�� ����->txdone=0->"txdatardy=0"->������ �۽� ������ txdone=1->��� �ݺ�
end

//�۽ſ� ����Ʈ Ŭ�� txclk �����
//1��Ʈ ���� �� clk16�� �ʿ�, ���� 8��Ʈ ���� ��۽��� �� 16��Ʈ �ֱ� ����� ��
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
            txclk <= ~txclk;//8��Ʈ���� ���, 16��Ʈ �ֱ��� txclk�������
            clk_count <= 0;
        end
    end
end

//�۽� ����Ʈ
always @(posedge txclk or negedge rst)
begin : txshift
    if(!rst)
    begin
        txreg <= 0;
        txtag1 <= 0;
        txtag2 <= 0;
        txparity <= 0;
    end
    else//txclk ��� �𼭸�����
        if((txdone & txdatardy)==1)//�۽� ������ ������, wr�ϰ��� ���� txhold�� ������ �Ƿ� ������
        begin
            txreg <= txhold;
            txtag2 <= 1;
            txtag1 <= 1;
            txparity <= 1;
        end
        else//txreg�� ��������� txdone=0�̸� �̿� ���� txdatardy�� 0
        begin
            txreg <= {txtag1, txreg[7:1]};
            txtag1 <= txtag2;
            txtag2 <= 0;
            txparity <= txparity ^ txreg[0];//���� txparity�� 1:���� txparity���� ���ļ� 1�� Ȧ����, 0: 1�� ¦����
        end
end
//���ڱ� �� �� ������ �����Ǹ鼭 txreg�� ���簡 �ɱ�? -> �� �� �� ���� ������ txdone=1, wr�ϰ��� ���� txhold�� �����ϸ鼭 txdatardy=1 �Ǳ� ����
//�׷��ٸ� ����Ÿ �帧���� 1->0 �� �� ����


//�۽�
always @(posedge txclk or negedge rst)
begin : tx_out
    if(!rst)    txd<=1;//reset�̸� �۽� ��ȣ Ŭ����, �ֳ�? �����Ʈ���� ���� ������ txd��� 1�̴� �׶��� ���ٰ� ���� ��
    else if(txdatardy)  txd<=0;//�� ��ŸƮ ��Ʈ ���� �긲
    else if(paritycycle)    txd<=txparity;//�ʱ� txtag2=1�� txreg[1]�� �������� �� txparity ���
    else if(txdone) txd<=1;//���� ��Ʈ ���
    else txd <= txreg[0];
end

//txtag2�� txreg[1]�� �������� �� paritycycle = 1
//�ʱ� txtag2=1�� txreg[1]�� ����������, �� ������� ��Ʈ���� ��� 0�̾�� ��
assign paritycycle = txreg[1] & ~(txtag2 | txtag1 | (| txreg[5:2]));
//|�Ƿ� 1�� �ϳ��� ������ 0, �� �ʱ� ����(txtag2=1�� �� ���������� txdone�� 0, ������ ������ �׶� 1
assign txdone = ~(txtag2 | txtag1 | (| txreg[7:0]));//������ ������ ��Ʈ���� ���°Ŷ� 000111�̷��� �� 111�� ������ �Ǵ°�..!! 10000011�̰� ���� ���ݾ�.
assign txrdy = ~txdatardy;

endmodule