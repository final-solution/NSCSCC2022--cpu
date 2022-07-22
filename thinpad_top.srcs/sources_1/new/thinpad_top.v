`default_nettype none

module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入（备用，可不用）

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
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

// PLL分频示例
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // 外部时钟输入
  // Clock out ports
  .clk_out1(clk_10M), // 时钟输出1，频率在IP配置界面中设置
  .clk_out2(clk_20M), // 时钟输出2，频率在IP配置界面中设置
  // Status and control signals
  .reset(reset_btn), // PLL复位输入
  .locked(locked)    // PLL锁定指示输出，"1"表示时钟稳定，
                     // 后级电路复位信号应当由它生成（见下）
 );

reg reset_of_clk10M;
// 异步复位，同步释放，将locked信号转为后级电路的复位reset_of_clk10M
always@(posedge clk_10M or negedge locked) begin
    if(~locked) reset_of_clk10M <= 1'b1;
    else        reset_of_clk10M <= 1'b0;
end


//cpu的指令存储器控制
wire stallreq;
wire stall;
wire inst_en;			//使能信号
wire[3:0] inst_ben;		//指令存储器字节使能信号
wire[31:0] inst_addr;	//指令地址
wire[31:0] inst_rdata;	//读取的指令

//cpu的数据存储器控制
wire data_en;
wire data_wen;
wire[3:0] data_ben;
wire[31:0] data_addr;
wire[31:0] data_wdata;	//写数据
wire[31:0] data_rdata;	//读数据

//必要的寄存器
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
reg[31:0] pre_inst_reg; //存储上一条取出的指令

reg inst_sel;       //1-取指令，0-取数据

//直连串口接收发送演示，从直连串口收到的数据再发送出去
wire [7:0] ext_uart_rx;
reg  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready, ext_uart_clear, ext_uart_busy;
reg ext_uart_start, ext_uart_avai;

wire[31:0] uart_rdata;
reg[31:0] uart_wdata;

reg uart_sel;       //是否选择读取串口
reg uart_flag;      //1-取串口状态，0-取串口数据
reg cpu_data_avai;		//来自cpu的写串口数据是否有效

assign uart_rdata = uart_flag ? {30'b0,ext_uart_avai,~ext_uart_busy} : {24'b0,ext_uart_buffer};

//连接操作
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

//读取数据
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

//同步SRAM控制
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

//串口控制器需要的信号

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

//直连串口接收发送演示，从直连串口收到的数据再发送出去

async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //接收模块，9600无检验位
    ext_uart_r(
        .clk(clk_20M),                       //外部时钟信号
        .RxD(rxd),                           //外部串行信号输入
        .RxD_data_ready(ext_uart_ready),  //数据接收到标志
        .RxD_clear(ext_uart_clear),       //清除接收标志
        .RxD_data(ext_uart_rx)             //接收到的一字节数据
    );

assign ext_uart_clear = ext_uart_ready; //收到数据的同时，清除标志，因为数据已取到ext_uart_buffer中
always @(posedge clk_10M) begin //接收到缓冲区ext_uart_buffer
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
always @(posedge clk_10M) begin //将cpu写入串口的数据uart_wdata发送出去
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

async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //发送模块，9600无检验位
    ext_uart_t(
        .clk(clk_10M),                  //外部时钟信号
        .TxD(txd),                      //串行信号输出
        .TxD_busy(ext_uart_busy),       //发送器忙状态指示
        .TxD_start(ext_uart_start),    //开始发送信号
        .TxD_data(ext_uart_tx)        //待发送的数据
    );




// 数码管连接关系示意图，dpy1同理
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7段数码管译码器演示，将number用16进制显示在数码管上面
// wire[7:0] number;
// SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0是低位数码管
// SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1是高位数码管

// reg[15:0] led_bits;
// assign leds = led_bits;

// always@(posedge clock_btn or posedge reset_btn) begin
//     if(reset_btn)begin //复位按下，设置LED为初始值
//         led_bits <= 16'h1;
//     end
//     else begin //每次按下时钟按钮，LED循环左移
//         led_bits <= {led_bits[14:0],led_bits[15]};
//     end
// end
// //图像输出演示，分辨率800x600@75Hz，像素时钟为50MHz
// wire [11:0] hdata;
// assign video_red = hdata < 266 ? 3'b111 : 0; //红色竖条
// assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //绿色竖条
// assign video_blue = hdata >= 532 ? 2'b11 : 0; //蓝色竖条
// assign video_clk = clk_10M;
// vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
//     .clk(clk_20M), 
//     .hdata(hdata), //横坐标
//     .vdata(),      //纵坐标
//     .hsync(video_hsync),
//     .vsync(video_vsync),
//     .data_enable(video_de)
// );
/* =========== Demo code end =========== */

endmodule
