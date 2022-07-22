`include "defines.v"
module regfile(
	input wire clk,
	input wire rst,
	
	//写请求
	input wire we,
	input wire[`RegAddrBus] waddr,
	input wire[`RegBus] wdata,
	
	//读请求与读出的数据
	input wire re1,
	input wire[`RegAddrBus] raddr1,
	output reg[`RegBus] rdata1,
	input wire re2,
	input wire[`RegAddrBus] raddr2,
	output reg[`RegBus] rdata2
);

reg[`RegBus] regs[0:`RegNum-1];	//寄存器堆

//写数据
always@(posedge clk) begin
	if(rst == `RstDisable) begin
		if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
			regs[waddr] <= wdata;
		end	
	end
end
	
//读取第一个操作数	
always@(*) begin
	if(rst == `RstEnable)
		rdata1 = `ZeroWord;
	else if(raddr1 == `RegNumLog2'h0)
		rdata1 = `ZeroWord;
	else if((raddr1 == waddr) && (re1 == `ReadEnable) && (we == `WriteEnable)) 	//模拟先写后读
		rdata1 = wdata;
	else if(re1 == `ReadEnable)
		rdata1 = regs[raddr1];
	else rdata1 = `ZeroWord;
end	

//读取第二个操作数
always@(*) begin
	if(rst == `RstEnable)
		rdata2 = `ZeroWord;
	else if(raddr2 == `RegNumLog2'h0)
		rdata2 = `ZeroWord;
	else if((raddr2 == waddr) && (re2 == `ReadEnable) && (we == `WriteEnable)) 	//模拟先写后读
		rdata2 = wdata;
	else if(re2 == `ReadEnable)
		rdata2 = regs[raddr2];
	else rdata2 = `ZeroWord;
end	

endmodule