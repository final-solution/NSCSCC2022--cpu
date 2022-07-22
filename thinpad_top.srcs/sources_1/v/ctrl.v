`include "defines.v"
module ctrl(
	input wire rst,
	
	//暂停请求
	input wire req_from_id,
	input wire req_from_thinpad,
	
	//暂停许可
	output reg[5:0] stall
);

//stall信号为1为暂停
//stall[0]代表pc,1~5代表五个流水线阶殿
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
		