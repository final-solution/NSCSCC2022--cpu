`include "defines.v"
module mem(
	input wire rst,
	
	//继续传递至回写阶段
	input wire[`RegAddrBus] wd_i,
	input wire wreg_i,
	input wire[`RegBus] wdata_i,
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output reg[`RegBus] wdata_o,
	
	//访存需要的信号
	input wire[`AluOpBus] aluop_i,
	(* DONT_TOUCH = "1" *) input wire[`RegBus] mem_addr_i,
	input wire[`RegBus] mem_data_i	//访存获得的数据
	
);

always@(*) begin
	if(rst == `RstEnable) begin
		wd_o = `NOPRegAddr;
		wreg_o = `WriteDisable;
		wdata_o = `ZeroWord;
		end
	else begin
		wd_o = wd_i;
		wreg_o = wreg_i;
		wdata_o = wdata_i;
		case(aluop_i) 
			`LB_OP:begin
				case(mem_addr_i[1:0])
					2'b11:begin
						wdata_o = {{24{mem_data_i[31]}},mem_data_i[31:24]};
						end
					2'b10:begin
						wdata_o = {{24{mem_data_i[23]}},mem_data_i[23:16]};
						end
					2'b01:begin
						wdata_o = {{24{mem_data_i[15]}},mem_data_i[15:8]};
						end
					2'b00:begin
						wdata_o = {{24{mem_data_i[7]}},mem_data_i[7:0]};
						end
					default:begin
						wdata_o = `ZeroWord;
						end
				endcase
			end
			`LW_OP:begin
				wdata_o = mem_data_i;
			end
			default:begin
			end
		endcase
	end
end

endmodule		