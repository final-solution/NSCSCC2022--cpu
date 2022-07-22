`default_nettype none

module thinpad_top(
    input wire clk_50M,           //50MHz ʱ������
    input wire clk_11M0592,       //11.0592MHz ʱ�����루���ã��ɲ��ã�

    input wire clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input wire reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4����ť���أ�����ʱΪ1
    input  wire[31:0] dip_sw,     //32λ���뿪�أ�������ON��ʱΪ1
    output wire[15:0] leds,       //16λLED�����ʱ1����
    output wire[7:0]  dpy0,       //����ܵ�λ�źţ�����С���㣬���1����
    output wire[7:0]  dpy1,       //����ܸ�λ�źţ�����С���㣬���1����

    //BaseRAM�ź�
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

    //ֱ�������ź�
    output wire txd,  //ֱ�����ڷ��Ͷ�
    input  wire rxd,  //ֱ�����ڽ��ն�

    //Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0]flash_a,      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
    inout  wire [15:0]flash_d,      //Flash����
    output wire flash_rp_n,         //Flash��λ�źţ�����Ч
    output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,         //FlashƬѡ�źţ�����Ч
    output wire flash_oe_n,         //Flash��ʹ���źţ�����Ч
    output wire flash_we_n,         //Flashдʹ���źţ�����Ч
    output wire flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

    //ͼ������ź�
    output wire[2:0] video_red,    //��ɫ���أ�3λ
    output wire[2:0] video_green,  //��ɫ���أ�3λ
    output wire[1:0] video_blue,   //��ɫ���أ�2λ
    output wire video_hsync,       //��ͬ����ˮƽͬ�����ź�
    output wire video_vsync,       //��ͬ������ֱͬ�����ź�
    output wire video_clk,         //����ʱ�����
    output wire video_de           //��������Ч�źţ���������������
);

myCPU myCPU0(
	.clk(clk_10M),
	.rst(reset_of_clk10M),
    .stallreq_from_thinpad(stallreq),
    .stall_to_thinpad(stall),
	
	.rom_ce_o(inst_en),
	.rom_sel_o(inst_ben),
	.rom_addr_o(inst_addr),
	.rom_data_i(inst_rdata),
	
	.ram_ce_o(data_en),
	.ram_we_o(data_wen),
	.ram_sel_o(data_ben),
	.ram_addr_o(data_addr),
	.ram_data_o(data_wdata),
	.ram_data_i(data_rdata)
);



/* =========== Demo code begin =========== */

// PLL��Ƶʾ��
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // �ⲿʱ������
  // Clock out ports
  .clk_out1(clk_10M), // ʱ�����1��Ƶ����IP���ý���������
  .clk_out2(clk_20M), // ʱ�����2��Ƶ����IP���ý���������
  // Status and control signals
  .reset(reset_btn), // PLL��λ����
  .locked(locked)    // PLL����ָʾ�����"1"��ʾʱ���ȶ���
                     // �󼶵�·��λ�ź�Ӧ���������ɣ����£�
 );

reg reset_of_clk10M;
// �첽��λ��ͬ���ͷţ���locked�ź�תΪ�󼶵�·�ĸ�λreset_of_clk10M
always@(posedge clk_10M or negedge locked) begin
    if(~locked) reset_of_clk10M <= 1'b1;
    else        reset_of_clk10M <= 1'b0;
end


//cpu��ָ��洢������
wire stallreq;
wire stall;
wire inst_en;			//ʹ���ź�
wire[3:0] inst_ben;		//ָ��洢���ֽ�ʹ���ź�
wire[31:0] inst_addr;	//ָ���ַ
wire[31:0] inst_rdata;	//��ȡ��ָ��

//cpu�����ݴ洢������
wire data_en;
wire data_wen;
wire[3:0] data_ben;
wire[31:0] data_addr;
wire[31:0] data_wdata;	//д����
wire[31:0] data_rdata;	//������

//��Ҫ�ļĴ���
reg stall_reg;

(* IOB = "true" *) reg[19:0] base_ram_addr_reg;
(* IOB = "true" *) reg[3:0] base_ram_be_n_reg;
(* IOB = "true" *) reg base_ram_ce_n_reg;
(* IOB = "true" *) reg base_ram_oe_n_reg;
(* IOB = "true" *) reg base_ram_we_n_reg;
(* IOB = "true" *) reg[31:0] base_ram_data_reg;

(* IOB = "true" *) reg[19:0] ext_ram_addr_reg;
(* IOB = "true" *) reg[3:0] ext_ram_be_n_reg;
(* IOB = "true" *) reg ext_ram_ce_n_reg;
(* IOB = "true" *) reg ext_ram_oe_n_reg;
(* IOB = "true" *) reg ext_ram_we_n_reg;
(* IOB = "true" *) reg[31:0] ext_ram_data_reg;

reg[31:0] inst_rdata_reg;
reg[31:0] data_rdata_reg;
reg[31:0] pre_inst_reg; //�洢��һ��ȡ����ָ��

reg inst_sel;       //1-ȡָ�0-ȡ����

//ֱ�����ڽ��շ�����ʾ����ֱ�������յ��������ٷ��ͳ�ȥ
wire [7:0] ext_uart_rx;
reg  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready, ext_uart_clear, ext_uart_busy;
reg ext_uart_start, ext_uart_avai;

wire[31:0] uart_rdata;
reg[31:0] uart_wdata;

reg uart_sel;       //�Ƿ�ѡ���ȡ����
reg uart_flag;      //1-ȡ����״̬��0-ȡ��������
reg cpu_data_avai;		//����cpu��д���������Ƿ���Ч

assign uart_rdata = uart_flag ? {30'b0,ext_uart_avai,~ext_uart_busy} : {24'b0,ext_uart_buffer};

//���Ӳ���
assign stallreq = ((data_addr >= 32'h80000000) && (data_addr <= 32'h803fffff)) ? 1'b1 : 1'b0;

assign data_rdata = data_rdata_reg;
assign inst_rdata = inst_rdata_reg;

assign base_ram_addr = base_ram_addr_reg;
assign base_ram_be_n = base_ram_be_n_reg;
assign base_ram_ce_n = base_ram_ce_n_reg;
assign base_ram_oe_n = base_ram_oe_n_reg;
assign base_ram_we_n = base_ram_we_n_reg;
assign base_ram_data = (base_ram_we_n_reg == `WriteEnable) ? base_ram_data_reg : 32'bz;

assign ext_ram_addr = ext_ram_addr_reg;
assign ext_ram_be_n = ext_ram_be_n_reg;
assign ext_ram_ce_n = ext_ram_ce_n_reg;
assign ext_ram_oe_n = ext_ram_oe_n_reg;
assign ext_ram_we_n = ext_ram_we_n_reg;
assign ext_ram_data = (ext_ram_we_n_reg == `WriteEnable) ? ext_ram_data_reg : 32'bz;

//��ȡ����
always@(*) begin
    if(reset_of_clk10M) begin
        inst_rdata_reg = `ZeroWord;
        data_rdata_reg = `ZeroWord;
    end else begin
        inst_rdata_reg = (inst_sel & ~base_ram_oe_n_reg & ~stall_reg) ? base_ram_data : pre_inst_reg;
        data_rdata_reg = uart_sel ? uart_rdata :
                            inst_sel ? (~ext_ram_oe_n_reg ? ext_ram_data : `ZeroWord) : 
                                        (~base_ram_oe_n_reg ? base_ram_data : `ZeroWord);
    end                                    
end    

always@(posedge clk_10M) begin
    if(reset_of_clk10M) begin
        stall_reg <= 1'b0;
        pre_inst_reg <= `ZeroWord;
    end else if(stall) begin
        stall_reg <= 1'b1;
        pre_inst_reg <= inst_rdata_reg;
    end else begin
        stall_reg <= 1'b0;
        pre_inst_reg <= inst_rdata_reg;
    end            
end

//ͬ��SRAM����
always@(posedge clk_10M) begin
    if(reset_of_clk10M) begin
        base_ram_addr_reg <= 20'b0;
        base_ram_be_n_reg <= 4'b0;
        base_ram_ce_n_reg <= `ChipDisable;
        base_ram_oe_n_reg <= `ReadDisable;
        base_ram_we_n_reg <= `WriteDisable;
        base_ram_data_reg <= `ZeroWord;
        inst_sel <= 1'b1;
    end else if((data_addr >= 32'h80000000) && (data_addr <= 32'h803fffff)) begin
        base_ram_addr_reg <= data_addr[21:2];
        base_ram_be_n_reg <= data_ben;
        base_ram_ce_n_reg <= data_en;
        base_ram_oe_n_reg <= ~data_wen;
        base_ram_we_n_reg <= data_wen;
        base_ram_data_reg <= data_wdata;
        inst_sel <= 1'b0;
    end else begin
        base_ram_addr_reg <= inst_addr[21:2];
        base_ram_be_n_reg <= inst_ben;
        base_ram_ce_n_reg <= inst_en;
        base_ram_oe_n_reg <= inst_en;
        base_ram_we_n_reg <= `WriteDisable;
        base_ram_data_reg <= `ZeroWord;
        inst_sel <= 1'b1;    
    end
end

always@(posedge clk_10M) begin
    if(reset_of_clk10M) begin
        ext_ram_addr_reg <= 20'b0;
        ext_ram_be_n_reg <= 4'b0;
        ext_ram_ce_n_reg <= `ChipDisable;
        ext_ram_oe_n_reg <= `ReadDisable;
        ext_ram_we_n_reg <= `WriteDisable;
        ext_ram_data_reg <= `ZeroWord;
    end else if((data_addr >= 32'h80400000) && (data_addr <= 32'h807fffff)) begin
        ext_ram_addr_reg <= data_addr[21:2];
        ext_ram_be_n_reg <= data_ben;
        ext_ram_ce_n_reg <= data_en;
        ext_ram_oe_n_reg <= ~data_wen;
        ext_ram_we_n_reg <= data_wen;
        ext_ram_data_reg <= data_wdata;
    end else begin
        ext_ram_addr_reg <= 20'b0;
        ext_ram_be_n_reg <= 4'b0;
        ext_ram_ce_n_reg <= `ChipDisable;
        ext_ram_oe_n_reg <= `ReadDisable;
        ext_ram_we_n_reg <= `WriteDisable;
        ext_ram_data_reg <= `ZeroWord;
    end           
end    

//���ڿ�������Ҫ���ź�

always@(posedge clk_10M) begin
    if(reset_of_clk10M) begin
        uart_sel <= 1'b0;
        uart_flag <= 1'b0;
        cpu_data_avai <= 1'b0;
        uart_wdata <= `ZeroWord;
    end else if(data_addr == 32'hBFD003F8 && data_en == `ChipEnable) begin
        uart_sel <= 1'b1;
        uart_flag <= 1'b0;
        cpu_data_avai <= (data_wen == `WriteEnable) ? 1'b1 : 1'b0;
        uart_wdata <= data_wdata;
    end else if(data_addr == 32'hBFD003FC && data_en == `ChipEnable) begin
        uart_sel <= 1'b1;
        uart_flag <= 1'b1;
        cpu_data_avai <= 1'b0;
        uart_wdata <= `ZeroWord;
    end else begin
        uart_sel <= 1'b0;
        uart_flag <= 1'b0;
        cpu_data_avai <= 1'b0;
        uart_wdata <= `ZeroWord;       
    end
end

//ֱ�����ڽ��շ�����ʾ����ֱ�������յ��������ٷ��ͳ�ȥ

async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_r(
        .clk(clk_20M),                       //�ⲿʱ���ź�
        .RxD(rxd),                           //�ⲿ�����ź�����
        .RxD_data_ready(ext_uart_ready),  //���ݽ��յ���־
        .RxD_clear(ext_uart_clear),       //������ձ�־
        .RxD_data(ext_uart_rx)             //���յ���һ�ֽ�����
    );

assign ext_uart_clear = ext_uart_ready; //�յ����ݵ�ͬʱ�������־����Ϊ������ȡ��ext_uart_buffer��
always @(posedge clk_10M) begin //���յ�������ext_uart_buffer
	if(reset_of_clk10M) begin
		ext_uart_buffer <= 8'b0;
		ext_uart_avai <= 1'b0;
    end else if(ext_uart_ready) begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1'b1;
    end else if(data_addr == 32'hBFD003F8 && ~(&data_ben) && (data_en == `ChipEnable) && ext_uart_avai) begin 
        ext_uart_buffer <= ext_uart_buffer;
        ext_uart_avai <= 1'b0;
    end else begin
        ext_uart_buffer <= ext_uart_buffer;
        ext_uart_avai <= ext_uart_avai;
    end    
end
always @(posedge clk_10M) begin //��cpuд�봮�ڵ�����uart_wdata���ͳ�ȥ
	if(reset_of_clk10M) begin
		ext_uart_tx <= 8'b0;
		ext_uart_start <= 1'b0;
    end else if(!ext_uart_busy && cpu_data_avai)begin 
        ext_uart_tx <= uart_wdata[7:0];
        ext_uart_start <= 1'b1;
    end else begin 
        ext_uart_start <= 1'b0;
    end
end

async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_t(
        .clk(clk_10M),                  //�ⲿʱ���ź�
        .TxD(txd),                      //�����ź����
        .TxD_busy(ext_uart_busy),       //������æ״ָ̬ʾ
        .TxD_start(ext_uart_start),    //��ʼ�����ź�
        .TxD_data(ext_uart_tx)        //�����͵�����
    );




// ��������ӹ�ϵʾ��ͼ��dpy1ͬ��
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7���������������ʾ����number��16������ʾ�����������
// wire[7:0] number;
// SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0�ǵ�λ�����
// SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1�Ǹ�λ�����

// reg[15:0] led_bits;
// assign leds = led_bits;

// always@(posedge clock_btn or posedge reset_btn) begin
//     if(reset_btn)begin //��λ���£�����LEDΪ��ʼֵ
//         led_bits <= 16'h1;
//     end
//     else begin //ÿ�ΰ���ʱ�Ӱ�ť��LEDѭ������
//         led_bits <= {led_bits[14:0],led_bits[15]};
//     end
// end
// //ͼ�������ʾ���ֱ���800x600@75Hz������ʱ��Ϊ50MHz
// wire [11:0] hdata;
// assign video_red = hdata < 266 ? 3'b111 : 0; //��ɫ����
// assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //��ɫ����
// assign video_blue = hdata >= 532 ? 2'b11 : 0; //��ɫ����
// assign video_clk = clk_10M;
// vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
//     .clk(clk_20M), 
//     .hdata(hdata), //������
//     .vdata(),      //������
//     .hsync(video_hsync),
//     .vsync(video_vsync),
//     .data_enable(video_de)
// );
/* =========== Demo code end =========== */

endmodule
