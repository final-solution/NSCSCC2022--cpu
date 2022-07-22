`include "defines.v"
module mem_wb(
	input wire rst,
	input wire clk,
	
	//来自访存阶段的信号
	input wire[`RegAddrBus] mem_wd,
	input wire mem_wreg,
	input wire[`RegBus] mem_wdata,
	
	//暂停信号
	input wire stall_pre,	//前一个阶段的暂停信号
	input wire stall_next,	//后一个阶段的暂停信号
	
	//传递给回写阶段的信号
	output reg[`RegAddrBus] wb_wd,
	output reg wb_wreg,
	output reg[`RegBus] wb_wdata
);

always@(posedge clk) begin
	if(rst == `RstEnable) begin
		wb_wd <= `NOPRegAddr;
		wb_wreg <= `WriteDisable;
		wb_wdata <= `ZeroWord;
		end
	else if(stall_pre == 1'b1 && stall_next == 1'b0) begin	//访存暂停，回写继续
		wb_wd <= `NOPRegAddr;
		wb_wreg <= `WriteDisable;
		wb_wdata <= `ZeroWord;
		end
	else if(stall_pre == 1'b0) begin
		wb_wd <= mem_wd;
		wb_wreg <= mem_wreg;
		wb_wdata <= mem_wdata;
		end
end

endmodule		
		