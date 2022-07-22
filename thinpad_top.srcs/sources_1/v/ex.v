`include "defines.v"
module ex(
	input wire rst,
	
	//��������
	input wire[`AluOpBus] aluop_i,
	input wire[`AluSelBus] alusel_i,
	
	//������
	input wire[`RegBus] reg1_i,
	input wire[`RegBus] reg2_i,
	
	//д����
	input wire[`RegAddrBus] wd_i,
	input wire wreg_i,
	
	//��ǰָ���Ƿ�Ϊ�ӳٲ�ָ��
	(* DONT_TOUCH = "1" *) input wire is_in_delayslot_i,
	
	//��Ҫ�����ڼĴ��������ӵ�ַ
	input wire[`RegBus] link_addr_i,
	
	//���ڱ��׶ε�ָ������
	(* DONT_TOUCH = "1" *) input wire[`RegBus] inst_i,
	
	//��д�׶���Ҫ��д�ź�
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output reg[`RegBus] wdata_o,
	
	//����load���
	output wire[`AluOpBus] aluop_o,

	//ֱ�ӷô�
	output reg[`RegBus] mem_addr_o,
	output reg[3:0] mem_sel_o,			//ÿһλ��Ӧһ�����е��ĸ��ֽ�
	output reg[`RegBus] mem_data_o,		//���洢����
	output reg mem_ce_o,				//ʹ���ź�
	output reg mem_we_o
);

//������ѡ��
reg[`RegBus] logicout;
reg[`RegBus] shiftres;
reg[`RegBus] arithres;
reg[`DoubleRegBus] mulres;


wire overflow;				//����������
wire reg1_lt_reg2;			//��һ���������Ƿ�С�ڵڶ���������
wire[`RegBus] reg2_i_neg;	//����ڶ��������෴������
wire[`RegBus] sum_res;		//�ӷ����
wire[`RegBus] data1_mul;	//������
wire[`RegBus] data2_mul;	//����
wire[`RegBus] mem_addr;

//�������з��űȽ�
assign reg2_i_neg = ((aluop_i == `SUB_OP) || 
					(aluop_i == `SLT_OP)) ? (~reg2_i)+1 : reg2_i;

assign sum_res = reg1_i + reg2_i_neg;

assign overflow = (!reg1_i[31] && !reg2_i_neg[31] && sum_res[31]) ||
					(reg1_i[31] && reg2_i_neg[31] && !sum_res[31]);
					
assign reg1_lt_reg2 = (reg1_i[31]&&!reg2_i[31])||
					(!reg1_i[31]&&!reg2_i[31]&&sum_res[31])||
					(reg1_i[31]&&reg2_i[31]&&sum_res[31]);	

//�˷�
assign data1_mul = aluop_i == `MUL_OP && reg1_i[31] ? (~reg1_i+1) : reg1_i;
assign data2_mul = aluop_i == `MUL_OP && reg2_i[31] ? (~reg2_i+1) : reg2_i;
 
//��ȡָ��ʹ��
assign aluop_o = aluop_i;
assign mem_addr = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};

//��������
always@(*) begin
	if(rst == `RstEnable) 
		arithres = `ZeroWord;
	else begin
		case(aluop_i)
			`SLT_OP:
				arithres = reg1_lt_reg2;
			`ADD_OP,`ADDU_OP,`SUB_OP:
				arithres = sum_res;
			default:
				arithres = `ZeroWord;
		endcase
		end
end		

//�˷�
always@(*) begin
	if(rst == `RstEnable)
		mulres = {`ZeroWord,`ZeroWord};
	else if(aluop_i == `MUL_OP) begin
		if(reg1_i[31]^reg2_i[31])
			mulres = ~(data1_mul*data2_mul)+1;
		else
			mulres = data1_mul*data2_mul;
		end
	else
		mulres = {`ZeroWord,`ZeroWord};
end		

//�߼�����
always@(*) begin
	if(rst == `RstEnable)
		logicout = `ZeroWord;
	else begin
		case(aluop_i)
			`OR_OP:
				logicout = reg1_i | reg2_i;
			`AND_OP:
				logicout = reg1_i & reg2_i;
			`XOR_OP:
				logicout = reg1_i ^ reg2_i;	
			default:
				logicout = `ZeroWord;
		endcase
		end
end

//��λ
always@(*) begin
	if(rst == `RstEnable)
		shiftres = `ZeroWord;
	else begin
		case(aluop_i) 
			`SLL_OP:
				shiftres = reg2_i << reg1_i[4:0];
			`SRL_OP:
				shiftres = reg2_i >> reg1_i[4:0];
			`SRA_OP:
				shiftres = ({32{reg2_i[31]}} << (6'd32 - {1'b0,reg1_i[4:0]})) | (reg2_i >> reg1_i[4:0]);
			default:
				shiftres = `ZeroWord;
		endcase
		end
end		

//��ô�д�������
always@(*) begin
	wd_o = wd_i;
	
	if((aluop_i==`ADD_OP || aluop_i==`SUB_OP) && overflow)	//�����д��
		wreg_o = `WriteDisable;
	else 	
		wreg_o = wreg_i;
		
	case(alusel_i)
		`RES_LOGIC:
			wdata_o = logicout;
		`RES_SHIFT:
			wdata_o = shiftres;
		`RES_ARITHMETIC:
			wdata_o = arithres;
		`RES_MUL:
			wdata_o = mulres[31:0];
		`RES_JUMP_BRANCH:
			wdata_o = link_addr_i;
		default:
			wdata_o = `ZeroWord;
	endcase
end

//����ô�
always@(*) begin
	if(rst == `RstEnable) begin
		mem_addr_o = `ZeroWord;
		mem_sel_o = 4'b1111;
		mem_data_o = `ZeroWord;
		mem_ce_o = `ChipDisable;
		mem_we_o = `WriteDisable;
	end else begin
		mem_addr_o = `ZeroWord;
		mem_sel_o = 4'b0000;
		mem_data_o = `ZeroWord;
		mem_ce_o = `ChipDisable;
		mem_we_o = `WriteDisable;
		case(aluop_i)
			`LB_OP:begin
				mem_addr_o = mem_addr;
				mem_we_o = `WriteDisable;
				mem_ce_o = `ChipEnable;
				case(mem_addr[1:0])
					2'b11:begin
						mem_sel_o = 4'b0111;
						end
					2'b10:begin
						mem_sel_o = 4'b1011;
						end
					2'b01:begin
						mem_sel_o = 4'b1101;
						end
					2'b00:begin
						mem_sel_o = 4'b1110;
						end
					default:begin
						mem_sel_o = 4'b0000;
						end
				endcase
			end
			`LW_OP:begin
				mem_addr_o = mem_addr;
				mem_we_o = `WriteDisable;
				mem_ce_o = `ChipEnable;
				end
			`SB_OP:begin
				mem_addr_o = mem_addr;
				mem_we_o = `WriteEnable;
				mem_ce_o = `ChipEnable;	
				mem_data_o = {{4{reg2_i[7:0]}}};
				case(mem_addr[1:0])
					2'b11:mem_sel_o = 4'b0111;
					2'b10:mem_sel_o = 4'b1011;
					2'b01:mem_sel_o = 4'b1101;
					2'b00:mem_sel_o = 4'b1110;
					default:mem_sel_o = 4'b1111;
				endcase
			end
			`SW_OP:begin
				mem_addr_o = mem_addr;
				mem_we_o = `WriteEnable;
				mem_data_o = reg2_i;
				mem_ce_o = `ChipEnable;	
			end	
		endcase
	end		
end

endmodule	
