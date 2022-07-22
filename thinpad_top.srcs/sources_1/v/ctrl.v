`include "defines.v"
module ctrl(
	input wire rst,
	
	//��ͣ����
	input wire req_from_id,
	input wire req_from_thinpad,
	
	//��ͣ���
	output reg[5:0] stall
);

//stall�ź�Ϊ1Ϊ��ͣ
//stall[0]����pc,1~5���������ˮ�߽׵�
always@(*) begin
	if(rst == `RstEnable) begin
		stall = 6'b0;
	end else if(req_from_id | req_from_thinpad) begin
		stall = 6'b000111;		
	end	else begin
		stall = 6'b0;
		end
end
endmodule		
		