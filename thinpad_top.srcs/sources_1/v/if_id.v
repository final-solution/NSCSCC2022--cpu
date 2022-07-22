`include "defines.v"
module if_id(
	input wire rst,
	input wire clk,
	
	//来自取指阶段的信�?
	input wire[`InstAddrBus] if_pc,
	
	//暂停信号
	input wire stall_pre,	//前一个阶段的暂停信号
	input wire stall_next,	//后一个阶段的暂停信号
	
	//传�?�给译码阶段的信�?
	output reg[`InstAddrBus] id_pc
);

always@(posedge clk) begin
	if(rst == `RstEnable) begin
		id_pc <= `ZeroWord;
		end
	else if(stall_pre == 1'b1 && stall_next == 1'b0) begin	//取指暂停,译码继续
		id_pc <= `ZeroWord;
		end	
	else if(stall_pre == 1'b0) begin
		id_pc <= if_pc;
		end
	else begin	//默认保持信号不变
		id_pc <= id_pc;
		end
end

endmodule		