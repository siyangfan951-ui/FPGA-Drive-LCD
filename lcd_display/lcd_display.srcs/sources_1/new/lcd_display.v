`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/08 16:03:48
// Design Name: 
// Module Name: lcd_display
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



module lcd_display(
    input             	lcd_pclk	,//时钟
    input             	rst_n		,//复位，低电平有效

	input		[2	:0]	filter_type	,//滤波器的类型 000:未知,001:低通,010:高通,011:带通,100:带阻
    input      	[10	:0] pixel_xpos	,//像素点横坐标
    input      	[10	:0] pixel_ypos	,//像素点纵坐标    
    output reg 	[23	:0] pixel_data   //像素点数据,
);                                   

//parameter define                                        
localparam	CHAR_X_START		= 11'd10		;//字符起始点横坐标
localparam	CHAR_Y_START		= 11'd120		;//字符起始点纵坐标
localparam	CHAR_X_START_LX		= 11'd220		;//类型的横坐标
localparam	CHAR_Y_START_LBQLX	= 11'd50		;//滤波器类型起始的纵坐标
localparam	CHAR_WIDTH  		= 11'd128		;//字符宽度,4个字符:32*4
localparam	CHAR_WIDTH_LBQLX	= 11'd192		;//滤波器类型： 字符宽度：32*6
localparam	CHAR_WIDTH_LX		= 11'd64		;//类型         字符宽度：32*2
localparam	CHAR_HEIGHT 		= 11'd32		;//字符高度
                       
localparam	BACK_COLOR  		= 24'hE0FFFF	;//背景色，浅蓝色
localparam	CHAR_COLOR  		= 24'hff0000	;//字符颜色，红色
localparam	AXIS_COLOR	 		= 24'h000000  	;//坐标系的颜色，黑色

//坐标轴定义
localparam	AXIS_X0     		= 11'd100		;//坐标轴的x轴的起始坐标
localparam	AXIS_Y0				= 11'd450		;//坐标轴的y轴的起始坐标
localparam  AXIS_WIDTH 			= 11'd2			;//坐标轴宽度（2个像素，避免太细）
localparam  SCALE_SPACING	 	= 11'd32		;//坐标轴刻度间距（每32个像素一个刻度）
localparam  SCALE_LENGTH    	= 11'd10		;//刻度线长度（10个像素）

//显示数字的位置
localparam  NUM0_X_START    	= AXIS_X0 - 4	;//数字0起始横坐标（8位宽，居中显示在原点X轴）
localparam  NUM0_Y_START    	= AXIS_Y0 + 15	;//数字0起始纵坐标（原点Y轴下方15个像素）
localparam  NUM0_WIDTH      	= 11'd8			;//数字0宽度（8像素，匹配num_0的8位宽）
localparam  NUM0_HEIGHT     	= 11'd16		;//数字0高度（16像素，匹配num_0的16行）

// Y轴刻度数字显示定义
localparam 	Y_LABEL_WIDTH   	= 11'd24			;         // 三个字符的宽度 (8*3)
localparam 	Y_LABEL_HEIGHT  	= 11'd16			;         // 字符高度
localparam 	Y_LABEL_X_END   	= AXIS_X0 - 11'd10	; // 距离刻度线左边10个像素，避免重合
localparam 	Y_LABEL_X_START 	= Y_LABEL_X_END - Y_LABEL_WIDTH	;

// X轴刻度数字显示定义 
localparam  X_LABEL_WIDTH       = 11'd32            ; // 4个字符宽度 (8*4, 支撑到4500)
localparam  X_LABEL_HEIGHT      = 11'd16            ; // 字符高度
localparam  X_LABEL_Y_START     = AXIS_Y0 + 15      ; // Y起始位置，和原点0处于同一水平
localparam  X_LABEL_X_OFFSET    = 11'd16            ; // 偏移量：32/2，使4位数中心对准刻度线

// 滤波器类型编码
localparam 	TYPE_UNKNOWN 		=	3'b000		;
localparam 	TYPE_LPF     		=	3'b001		;
localparam 	TYPE_HPF     		=	3'b010		;
localparam 	TYPE_BPF     		=	3'b011		;
localparam 	TYPE_BEF     		=	3'b100		;

//reg define
//定义为Block RAM 或分布式 ROM
(* rom_style = "block" *)	reg	[127:0]		char [31:0]		;//字符数组
(* rom_style = "block" *)	reg	[191:0]		char1[31:0]		;
(* rom_style = "block" *)	reg	[63	:0]		char2[31:0]		;
(* rom_style = "block" *)	reg	[63	:0]		char3[31:0]		;
(* rom_style = "block" *)	reg	[63	:0]		char4[31:0]		;
(* rom_style = "block" *)	reg	[63	:0]		char5[31:0]		;
(* rom_style = "block" *)	reg	[63	:0]		char6[31:0]		;


//存储0-9的数字
(* rom_style = "block" *)	reg	[7	:0]		num_0[15:0]		;//数字数组
(* rom_style = "block" *)	reg	[7	:0]		num_1[15:0]		;//数字数组
(* rom_style = "block" *)	reg	[7	:0]		num_2[15:0]		;//数字数组
(* rom_style = "block" *)	reg	[7	:0]		num_3[15:0]		;//数字数组
(* rom_style = "block" *)	reg	[7	:0]		num_4[15:0]		;//数字数组
(* rom_style = "block" *)	reg	[7	:0]		num_5[15:0]		;//数字数组
(* rom_style = "block" *)	reg	[7	:0]		num_6[15:0]		;//数字数组
(* rom_style = "block" *)	reg	[7	:0]		num_7[15:0]		;//数字数组
(* rom_style = "block" *)	reg	[7	:0]		num_8[15:0]		;//数字数组
(* rom_style = "block" *)	reg	[7	:0]		num_9[15:0]		;//数字数组

(* rom_style = "block" *)	reg	[7	:0]		char_p[15:0]	;//字符 .

//wire define   
wire[10	:0]  	x_cnt_lbqlx		;
wire[10	:0]		y_cnt_lbqlx		;

wire[10	:0]		x_cnt_lx		;

wire			is_lbqlx_area	;
wire			is_type_area	;


//坐标系判断信号
wire 			is_x_axis		;// 是否是X轴像素
wire 			is_y_axis		;// 是否是Y轴像素
wire 			is_x_scale		;// 是否是X轴刻度线
wire 			is_y_scale		;// 是否是Y轴刻度线

wire[10	:0]		x_cnt_num0		;//数字0区域内的横坐标偏移
wire[10	:0]		y_cnt_num0		;//数字0区域内的纵坐标偏移
wire 			is_num0_area	;// 是否在数字0的显示区域内

//y轴显示的数据
wire[10	:0]		y_label_idx		;// 第几个刻度 (1-10)
wire[10	:0]		x_cnt_y_label	;// 标签区域内横坐标 (0-23)
wire[10	:0]		y_cnt_y_label	;// 标签区域内纵坐标 (0-15)
wire[3	:0] 	y_label_digit_h	;// 整数位数字
wire[3	:0] 	y_label_digit_l	;// 小数位数字
wire      		is_y_label_area	;// 是否在Y轴标签区域
wire[10	:0]		y_offset_from_axis	;
wire[10	:0] 	raw_idx			;
wire 			is_in_slot		;

// =============== X轴显示的数据 =============== 
wire[10 :0]     x_dist          ;// 相对于X轴原点的调整距离
wire[10 :0]     x_label_idx     ;// 第几个X刻度 (1-15)
wire[10 :0]     x_cnt_x_label   ;// X轴标签区域内横坐标 (0-31)
wire[3  :0]     y_cnt_x_label   ;// X轴标签区域内纵坐标 (0-15)
wire            is_in_x_slot    ;// 是否落在 32 像素的字符槽内
wire            is_x_label_area ;// 是否在X轴标签区域 (只判定 1~15 刻度)

// X 轴数值映射表变量 (硬件 LUT 替代除法)
reg [3:0]       x_dig3, x_dig2, x_dig1, x_dig0;
reg [3:0]       x_label_cur_dig ;
reg             x_label_show_flag;


//*****************************************************
//**                    main code
//*****************************************************


assign	x_cnt_lbqlx	= pixel_xpos + 11'b1 - CHAR_X_START	;//像素点相对于字符区域起始点水平坐标
assign	y_cnt_lbqlx	= pixel_ypos - CHAR_Y_START_LBQLX	;//像素点相对于字符区域起始点垂直坐标

assign	x_cnt_lx	= pixel_xpos + 11'b1 - CHAR_X_START_LX	;

assign x_cnt_num0 = pixel_xpos - NUM0_X_START;	//数字0区域内的横坐标偏移（0~7）
assign y_cnt_num0 = pixel_ypos - NUM0_Y_START;	//数字0区域内的纵坐标偏移（0~15）



// 区域标志位预判
assign is_lbqlx_area = (pixel_xpos >= CHAR_X_START - 11'b1) && 
                     (pixel_xpos < CHAR_WIDTH_LBQLX + CHAR_X_START - 11'b1) && 
                     (pixel_ypos >= CHAR_Y_START_LBQLX) && 
                     (pixel_ypos < CHAR_Y_START_LBQLX + CHAR_HEIGHT);

assign is_type_area  = (pixel_xpos >= CHAR_X_START_LX - 11'b1) && 
                     (pixel_xpos < CHAR_WIDTH_LX + CHAR_X_START_LX - 11'b1) && 
                     (pixel_ypos >= CHAR_Y_START_LBQLX) && 
                     (pixel_ypos < CHAR_Y_START_LBQLX + CHAR_HEIGHT);



//坐标系绘制逻辑
// 1. 判断是否是X轴（原点Y±AXIS_WIDTH，全屏幕X范围）
assign is_x_axis = (pixel_ypos >= AXIS_Y0 - (AXIS_WIDTH >> 1)) && 
                   (pixel_ypos <= AXIS_Y0 + (AXIS_WIDTH >> 1)) &&
                   (pixel_xpos >= 100) && (pixel_xpos <= 1092);

// 2. 判断是否是Y轴（原点X±AXIS_WIDTH，全屏幕Y范围）
assign is_y_axis = (pixel_xpos >= AXIS_X0 - (AXIS_WIDTH >> 1)) && 
                   (pixel_xpos <= AXIS_X0 + (AXIS_WIDTH >> 1)) &&
                   (pixel_ypos >= 110) && (pixel_ypos <= 449);

// 3. 判断是否是X轴刻度线（X轴上，每隔SCALE_SPACING_X个像素画一条竖线）
wire[10	:0]	x_offset = pixel_xpos - AXIS_X0	;

assign is_x_scale = (pixel_ypos >= AXIS_Y0 - (SCALE_LENGTH >> 1)) && 
                    (pixel_ypos <= AXIS_Y0 + (SCALE_LENGTH >> 1)) &&
                    (x_offset[5:0] == 6'd0) &&//取余为64
                    (pixel_xpos >= 100) && (pixel_xpos <= 1092);

// 4. 判断是否是Y轴刻度线（Y轴上，每隔SCALE_SPACING_Y个像素画一条横线）
wire[10	:0]	y_offset = pixel_ypos - AXIS_Y0	;

assign is_y_scale = (pixel_xpos >= AXIS_X0 - (SCALE_LENGTH >> 1)) && 
                    (pixel_xpos <= AXIS_X0 + (SCALE_LENGTH >> 1)) &&
                    (y_offset[4:0] == 5'd0) &&
                    (pixel_ypos >= 110) && (pixel_ypos <= 449);

assign is_num0_area = (pixel_xpos >= NUM0_X_START) && (pixel_xpos < NUM0_X_START + NUM0_WIDTH) &&
                      (pixel_ypos >= NUM0_Y_START) && (pixel_ypos < NUM0_Y_START + NUM0_HEIGHT);
					  
					  
//判定 Y 轴标签显示区域 (110 到 425，避开 450 原点)
assign is_y_label_area = (pixel_xpos >= Y_LABEL_X_START) && (pixel_xpos < Y_LABEL_X_END) &&
                         (pixel_ypos >= 110) && (pixel_ypos <= AXIS_Y0 - 25); 

//这里的偏移量计算保持不变
assign y_offset_from_axis = AXIS_Y0 - pixel_ypos					;
assign raw_idx = (y_offset_from_axis + 8) >> 5			;

//判定是否在 16 像素高度内
wire[10	:0]	is_in_slot_offset = y_offset_from_axis + 8	;

assign is_in_slot = (is_in_slot_offset[4:0]) < 5'd16	;

assign y_label_idx   = (is_in_slot && raw_idx > 0) ? raw_idx : 11'd0; 
assign x_cnt_y_label = pixel_xpos - Y_LABEL_X_START;

// 这里算出的是 0-15 的相对高度 
wire[10	:0]	y_cnt_raw_offset = y_offset_from_axis + 8	;

wire [3:0] y_cnt_raw = y_cnt_raw_offset[3:0];
// 因为 Y 轴坐标系反转，这里必须用 15 减去原始索引来纠正上下颠倒 
assign y_cnt_y_label = 4'd15 - y_cnt_raw; 

//数字计算
wire[10	:0]	y_label_digit_l_offset = y_label_idx << 1 ;

assign y_label_digit_h = (y_label_idx << 1) >> 3;
assign y_label_digit_l = {1'b0,(y_label_digit_l_offset[2:0])};

// =============== X 轴数据区域解析逻辑 ===============
// 计算 X 轴偏移距离，防欠位：(pixel_xpos + 16(偏移) - 100(起点))
assign x_dist = (pixel_xpos + X_LABEL_X_OFFSET >= AXIS_X0) ? (pixel_xpos + X_LABEL_X_OFFSET - AXIS_X0) : 11'd0;
assign x_label_idx   = x_dist >> 6;          // 当前第几个刻度
assign x_cnt_x_label = x_dist[5:0];          // 距离当前槽的局部像素位移(0-49)
assign is_in_x_slot  = (x_cnt_x_label < X_LABEL_WIDTH); // 0-31 为真实绘制区，32-49 为空白间隙

// X轴判定区域：只显示刻度 1(300) 到 15(4500)
assign is_x_label_area = (pixel_ypos >= X_LABEL_Y_START) &&
                         (pixel_ypos < X_LABEL_Y_START + X_LABEL_HEIGHT) &&
                         (pixel_xpos >= AXIS_X0 + SCALE_SPACING - X_LABEL_X_OFFSET) && // 至少跨过第一个刻度的一半
                         (pixel_xpos <= 1092) &&
                         is_in_x_slot &&
                         (x_label_idx > 0) && (x_label_idx <= 15);

// X轴的纵坐标
assign y_cnt_x_label = pixel_ypos - X_LABEL_Y_START; 


// =============== X 轴硬件 LUT 映射 (1~15 映射到 300~4500) =============== 
// 避免FPGA生成复杂的除法电路（/1000, /100）
always @(*) begin
    case(x_label_idx)
        1:  begin x_dig3 = 0; x_dig2 = 3; x_dig1 = 0; x_dig0 = 0; end // 300
        2:  begin x_dig3 = 0; x_dig2 = 6; x_dig1 = 0; x_dig0 = 0; end // 600
        3:  begin x_dig3 = 0; x_dig2 = 9; x_dig1 = 0; x_dig0 = 0; end // 900
        4:  begin x_dig3 = 1; x_dig2 = 2; x_dig1 = 0; x_dig0 = 0; end // 1200
        5:  begin x_dig3 = 1; x_dig2 = 5; x_dig1 = 0; x_dig0 = 0; end // 1500
        6:  begin x_dig3 = 1; x_dig2 = 8; x_dig1 = 0; x_dig0 = 0; end // 1800
        7:  begin x_dig3 = 2; x_dig2 = 1; x_dig1 = 0; x_dig0 = 0; end // 2100
        8:  begin x_dig3 = 2; x_dig2 = 4; x_dig1 = 0; x_dig0 = 0; end // 2400
        9:  begin x_dig3 = 2; x_dig2 = 7; x_dig1 = 0; x_dig0 = 0; end // 2700
        10: begin x_dig3 = 3; x_dig2 = 0; x_dig1 = 0; x_dig0 = 0; end // 3000
        11: begin x_dig3 = 3; x_dig2 = 3; x_dig1 = 0; x_dig0 = 0; end // 3300
        12: begin x_dig3 = 3; x_dig2 = 6; x_dig1 = 0; x_dig0 = 0; end // 3600
        13: begin x_dig3 = 3; x_dig2 = 9; x_dig1 = 0; x_dig0 = 0; end // 3900
        14: begin x_dig3 = 4; x_dig2 = 2; x_dig1 = 0; x_dig0 = 0; end // 4200
        15: begin x_dig3 = 4; x_dig2 = 5; x_dig1 = 0; x_dig0 = 0; end // 4500
        default: begin x_dig3 = 0; x_dig2 = 0; x_dig1 = 0; x_dig0 = 0; end
    endcase
end

// 解析当前在画哪一个位 (消隐 300, 600, 900 前面的 0)
always @(*) begin
    if(x_cnt_x_label < 8) begin          // 千位区域
        x_label_cur_dig 	= x_dig3				;
        x_label_show_flag 	= (x_label_idx >= 4)	; // >= 1200 时才显示千位，否则透明隐藏
    end
    else if(x_cnt_x_label < 16) begin    // 百位区域
        x_label_cur_dig 	= x_dig2				;
        x_label_show_flag 	= 1'b1					;               // 百位永不隐藏
    end
    else if(x_cnt_x_label < 24) begin    // 十位区域
        x_label_cur_dig 	= x_dig1				;
        x_label_show_flag 	= 1'b1					;               // 十位永不隐藏
    end
    else begin                           // 个位区域
        x_label_cur_dig 	= x_dig0				;
        x_label_show_flag 	= 1'b1					;               // 个位永不隐藏
    end
end


//曲线的判断
// ================== 显示波形（平滑曲线） ==================
// 比例: 1v = 160 像素
// 更新: 64个采样点，每点占据16像素，频率步进75Hz
(* rom_style = "block" *)	reg [9:0] mag_lut [63:0]; 

initial begin
	mag_lut[0 ] = 10'd0				;
	mag_lut[1 ] = 10'd1        		;
	mag_lut[2 ] = 10'd15       		;
	mag_lut[3 ] = 10'd83       		;
	mag_lut[4 ] = 10'd225		    ;
	mag_lut[5 ] = 10'd304         	;
	mag_lut[6 ] = 10'd317         	;
	mag_lut[7 ] = 10'd320         	;
	mag_lut[8 ] = 10'd320         	;
	mag_lut[9 ] = 10'd320         	;
	mag_lut[10] = 10'd320         	;
	mag_lut[11] = 10'd320         	;
	mag_lut[12] = 10'd320         	;
	mag_lut[13] = 10'd320         	;
	mag_lut[14] = 10'd320         	;
	mag_lut[15] = 10'd320         	;
	mag_lut[16] = 10'd320         	;
	mag_lut[17] = 10'd320         	;
	mag_lut[18] = 10'd320         	;
	mag_lut[19] = 10'd320         	;
	mag_lut[20] = 10'd320         	;
	mag_lut[21] = 10'd320         	;
	mag_lut[22] = 10'd320         	;
	mag_lut[23] = 10'd320         	;
	mag_lut[24] = 10'd320         	;
	mag_lut[25] = 10'd320         	;
	mag_lut[26] = 10'd320         	;
	mag_lut[27] = 10'd320         	;
	mag_lut[28] = 10'd320         	;
	mag_lut[29] = 10'd320         	;
	mag_lut[30] = 10'd317       	;
	mag_lut[31] = 10'd317       	;
	mag_lut[32] = 10'd315       	;
	mag_lut[33] = 10'd313      		;
	mag_lut[34] = 10'd310       	;
	mag_lut[35] = 10'd307       	;
	mag_lut[36] = 10'd304         	;
	mag_lut[37] = 10'd301       	;
	mag_lut[38] = 10'd294       	;
	mag_lut[39] = 10'd288         	;
	mag_lut[40] = 10'd283       	;
	mag_lut[41] = 10'd272         	;
	mag_lut[42] = 10'd262      		;
	mag_lut[43] = 10'd249       	;
	mag_lut[44] = 10'd240         	;
	mag_lut[45] = 10'd229       	;
	mag_lut[46] = 10'd217       	;
	mag_lut[47] = 10'd205      		;
	mag_lut[48] = 10'd192         	;
	mag_lut[49] = 10'd182       	;
	mag_lut[50] = 10'd169       	;
	mag_lut[51] = 10'd157       	;
	mag_lut[52] = 10'd147      		;
	mag_lut[53] = 10'd138       	;
	mag_lut[54] = 10'd128         	;
	mag_lut[55] = 10'd118       	;
	mag_lut[56] = 10'd112         	;
	mag_lut[57] = 10'd104         	;
	mag_lut[58] = 10'd96         	;
	mag_lut[59] = 10'd91       		;
	mag_lut[60] = 10'd85        	;
	mag_lut[61] = 10'd78        	;
	mag_lut[62] = 10'd75       		;
	mag_lut[63] = 10'd69        	;

end

// ================== 2. 曲线插值逻辑 (适配 16 像素间距，64采样点) ==================
wire [10:0] curve_x_offset = (pixel_xpos >= AXIS_X0) ? (pixel_xpos - AXIS_X0) : 11'd0;

// 像素偏移除以16 (>>4) 获得LUT索引。最大索引防止越过62 (留1个给+1插值)
wire [6:0]  curve_idx_raw = curve_x_offset >> 4; 
wire [5:0]  curve_idx     = (curve_idx_raw > 62) ? 6'd62 : curve_idx_raw[5:0]; 
wire [3:0]  curve_dx      = curve_x_offset[3:0]; // 局部像素偏移 0~15

// 获取相邻点高度
wire [9:0] y_h0 = mag_lut[curve_idx];
wire [9:0] y_h1 = mag_lut[curve_idx + 1]; 

// 平滑插值计算 (适配 W=16 的三次平滑多项式插值)
// 权重公式映射到 0~64: (dx^2 * (48 - 2*dx)) / 64
wire [7:0]  dx_sq = curve_dx * curve_dx;              // 4bit * 4bit = 8bit
wire [5:0]  term2 = 6'd48 - (curve_dx << 1);          // 48 - 2*dx
wire [13:0] blend_weight_full = dx_sq * term2;        // 8bit * 6bit = 14bit
wire [6:0]  blend_weight = blend_weight_full >> 6;    // 缩放到 0~64 范围

// 高度过渡计算 
wire [10:0] y_diff   = (y_h1 >= y_h0) ? (y_h1 - y_h0) : (y_h0 - y_h1);
wire [17:0] y_prod   = y_diff * blend_weight;         // 11bit * 7bit = 18bit
wire [10:0] y_interp = y_prod >> 6;                   // 除以64得到实际高度差

wire [10:0] curve_y_offset = (y_h1 >= y_h0) ? (y_h0 + y_interp) : (y_h0 - y_interp);
wire [10:0] curve_y_pos    = AXIS_Y0 - curve_y_offset;

// ================== 修改点开始 ==================
// 动态计算曲线线宽补偿：(y_diff >> 4) 相当于 y_diff / 16，即当前区间的平均斜率。
// 斜率越大，上下延伸的像素越多，完美填补相邻 X 像素间的 Y 轴断层。
// 基础线宽保留为 1（与原代码一致）。
wire [10:0] curve_thickness = (y_diff >> 4) + 11'd1;

// 绘制范围限制
// 注意：为了避免无符号数在 0 附近做减法发生下溢，原先的 (pixel_ypos >= curve_y_pos - ...) 
// 变换为加法逻辑：(pixel_ypos + curve_thickness >= curve_y_pos)
wire is_curve_area = (pixel_xpos >= AXIS_X0 && pixel_xpos <= 1092) && 
                     (pixel_ypos + curve_thickness >= curve_y_pos) && 
                     (pixel_ypos <= curve_y_pos + curve_thickness);
// ==========================================================


//为LCD不同显示区域绘制图片、字符和背景色
always @(posedge lcd_pclk or negedge rst_n) begin
    if (!rst_n)
        pixel_data <= BACK_COLOR			;
	//滤波器类型：
	else if(is_lbqlx_area) begin
		pixel_data <= char1[y_cnt_lbqlx][CHAR_WIDTH_LBQLX - 11'b1 - x_cnt_lbqlx] ? CHAR_COLOR : BACK_COLOR;
	end
	//未知 低通 高通 带通 带阻
	else if(is_type_area) begin
		case (filter_type)
            TYPE_UNKNOWN	:	pixel_data <= char2[y_cnt_lbqlx][CHAR_WIDTH_LX - 1 - x_cnt_lx] ? CHAR_COLOR : BACK_COLOR;
            TYPE_LPF		:   pixel_data <= char3[y_cnt_lbqlx][CHAR_WIDTH_LX - 1 - x_cnt_lx] ? CHAR_COLOR : BACK_COLOR;
            TYPE_HPF		:   pixel_data <= char4[y_cnt_lbqlx][CHAR_WIDTH_LX - 1 - x_cnt_lx] ? CHAR_COLOR : BACK_COLOR;
            TYPE_BPF		:   pixel_data <= char5[y_cnt_lbqlx][CHAR_WIDTH_LX - 1 - x_cnt_lx] ? CHAR_COLOR : BACK_COLOR;
            TYPE_BEF		:   pixel_data <= char6[y_cnt_lbqlx][CHAR_WIDTH_LX - 1 - x_cnt_lx] ? CHAR_COLOR : BACK_COLOR;
            default			:   pixel_data <= BACK_COLOR;
        endcase		
	end
	//显示的数字
	else if(is_num0_area) begin
		pixel_data <= num_0[y_cnt_num0][7 - x_cnt_num0] ? AXIS_COLOR : BACK_COLOR;
	end
// Y 轴刻度标签 
    else if(is_y_label_area && y_label_idx > 0) begin
        if(x_cnt_y_label < 8) begin // 整数位
            case(y_label_digit_h)
                0: pixel_data <= num_0[y_cnt_y_label][7 - x_cnt_y_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                1: pixel_data <= num_1[y_cnt_y_label][7 - x_cnt_y_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                2: pixel_data <= num_2[y_cnt_y_label][7 - x_cnt_y_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                default: pixel_data <= BACK_COLOR;
            endcase
        end
        else if(x_cnt_y_label < 16) begin // 小数点 "."
            pixel_data <= char_p[y_cnt_y_label][7 - x_cnt_y_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
        end
        else begin // 小数位
            case(y_label_digit_l)
                0: pixel_data <= num_0[y_cnt_y_label][7 - x_cnt_y_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                2: pixel_data <= num_2[y_cnt_y_label][7 - x_cnt_y_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                4: pixel_data <= num_4[y_cnt_y_label][7 - x_cnt_y_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                6: pixel_data <= num_6[y_cnt_y_label][7 - x_cnt_y_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                8: pixel_data <= num_8[y_cnt_y_label][7 - x_cnt_y_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                default: pixel_data <= BACK_COLOR;
            endcase
        end
    end
// =============== X 轴刻度标签 (300 到 4500) =============== 
    else if(is_x_label_area) begin
        if(!x_label_show_flag) begin // 如果是 300 的前导 0，显示背景色
            pixel_data <= BACK_COLOR;
        end
        else begin
            // 正常显示数字。注意：这里使用的是 y_cnt_x_label（顺序0到15），不会再颠倒！
            case(x_label_cur_dig)
                0: pixel_data <= num_0[y_cnt_x_label][7 - x_cnt_x_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                1: pixel_data <= num_1[y_cnt_x_label][7 - x_cnt_x_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                2: pixel_data <= num_2[y_cnt_x_label][7 - x_cnt_x_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                3: pixel_data <= num_3[y_cnt_x_label][7 - x_cnt_x_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                4: pixel_data <= num_4[y_cnt_x_label][7 - x_cnt_x_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                5: pixel_data <= num_5[y_cnt_x_label][7 - x_cnt_x_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                6: pixel_data <= num_6[y_cnt_x_label][7 - x_cnt_x_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                7: pixel_data <= num_7[y_cnt_x_label][7 - x_cnt_x_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                8: pixel_data <= num_8[y_cnt_x_label][7 - x_cnt_x_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                9: pixel_data <= num_9[y_cnt_x_label][7 - x_cnt_x_label[2:0]] ? AXIS_COLOR : BACK_COLOR;
                default: pixel_data <= BACK_COLOR;
            endcase
        end
    end
	//显示的曲线
	else if (is_curve_area) begin
        pixel_data <= 24'h000000; // 曲线显示为黄色
    end
	//绘制滤波器的幅频特性曲线
	else if(is_x_axis || is_y_axis) 
		pixel_data	<=	AXIS_COLOR			;
	else if(is_x_scale || is_y_scale)
		pixel_data	<=	AXIS_COLOR			;
    else
        pixel_data <= BACK_COLOR			;//屏幕背景色
end

//显示的是 ： 滤波器类型：
initial begin
	char1[0 ] = 192'h000000000000000000000000000000000000000000000000;
	char1[1 ] = 192'h000000000000000000000000000000000000000000000000;
	char1[2 ] = 192'h000010000000180000000000000180000000002000000000;
	char1[3 ] = 192'h000018000C001800000400400101C1800000803000000000;
	char1[4 ] = 192'h040010000600180003FE3FE000C181C00FFFC03000000000;
	char1[5 ] = 192'h0300106003001800020C30C0007183000086043000000000;
	char1[6 ] = 192'h03801FF003001800020C30C0003186000086063000000000;
	char1[7 ] = 192'h0180100001081810020C30C0003184000086063000000000;
	char1[8 ] = 192'h01201008001FFFF8020C30C0002188180086063000000000;
	char1[9 ] = 192'h002FFFFC002C183803FC3FC03FFFFFFC0086663000000000;
	char1[10] = 192'h002C3018202C1820020C30C0000780001FFFF63000000000;
	char1[11] = 192'h304C3010184C184002030C00000DF0000086063000000000;
	char1[12] = 192'h184C31A01C4C18000003071000198E000086063000000000;
	char1[13] = 192'h1C49FF100C4C180000060338003183C00186063000000000;
	char1[14] = 192'h0C8A30100C8C18203FFFFFFC006180F00186063000000000;
	char1[15] = 192'h08883010008FFFF0000C200001C180700106043000000000;
	char1[16] = 192'h00883030010C806000181800030100300306003000000000;
	char1[17] = 192'h01081FF0010C80C000300C001C0300100206043007000000;
	char1[18] = 192'h01080000010C40C00060070020038008040603F00F000000;
	char1[19] = 192'h03080800020C418001C003E000030018080100600F000000;
	char1[20] = 192'h02180E0002082180070400FC7FFFFFFC1001C04007000000;
	char1[21] = 192'h06184600060833001BFE7FF8000240000001808000000000;
	char1[22] = 192'h0E1972203C181E00630460C000062000000181C000000000;
	char1[23] = 192'h1E1162180C100E00030460C00006300003FFFFE000000000;
	char1[24] = 192'h0413604C0C100C00030460C0000C18000001800000000000;
	char1[25] = 192'h0432604C0C201F00030460C000180C000001800007000000;
	char1[26] = 192'h0C2660440C607380030460C000380700000180000F000000;
	char1[27] = 192'h0C4E60440C40C1E003FC7FC0007003E0000180000F000000;
	char1[28] = 192'h0C4070700C83807C030460C001C000FE0001803006000000;
	char1[29] = 192'h0C803FE0050E003802006080070000703FFFFFF800000000;
	char1[30] = 192'h010000000230000000000000380000000000000000000000;
	char1[31] = 192'h000000000000000000000000000000000000000000000000;
end


//显示的是 ：未知
initial begin
	char2[0 ] = 64'h0000000000000000;
	char2[1 ] = 64'h0000000000000000;
	char2[2 ] = 64'h0003800001000000;
	char2[3 ] = 64'h0003E00001800000;
	char2[4 ] = 64'h0003C00001000000;
	char2[5 ] = 64'h0003C00003000000;
	char2[6 ] = 64'h0003C18003000000;
	char2[7 ] = 64'h0003C3C002020010;
	char2[8 ] = 64'h07FFFFE007FF1FFC;
	char2[9 ] = 64'h0303C00004601018;
	char2[10] = 64'h0003C00004601018;
	char2[11] = 64'h0003C00008601018;
	char2[12] = 64'h0003C00008601018;
	char2[13] = 64'h0003C03010601018;
	char2[14] = 64'h0003C07800601018;
	char2[15] = 64'h3FFFFFFC00619018;
	char2[16] = 64'h0007E0003FFF9018;
	char2[17] = 64'h000FF00000601018;
	char2[18] = 64'h001FF00000601018;
	char2[19] = 64'h001FF80000601018;
	char2[20] = 64'h003FDC0000501018;
	char2[21] = 64'h007BDE0000C81018;
	char2[22] = 64'h00F3CF0000CC1018;
	char2[23] = 64'h01E3C7C000871018;
	char2[24] = 64'h0383C3E001831FF8;
	char2[25] = 64'h0703C1FC01039018;
	char2[26] = 64'h1E03C0FE03019018;
	char2[27] = 64'h3803C07806011018;
	char2[28] = 64'h6003C0000C001010;
	char2[29] = 64'h0003C00010000000;
	char2[30] = 64'h0003800020000000;
	char2[31] = 64'h0000000000000000;  
end

//显示的是 ：低通
initial begin
	char3[0 ] = 64'h0000000000000000;
	char3[1 ] = 64'h0000000000000000;
	char3[2 ] = 64'h01C0000000000040;
	char3[3 ] = 64'h01E000C0080FFFE0;
	char3[4 ] = 64'h01E001E00C0001E0;
	char3[5 ] = 64'h03C00FF006008300;
	char3[6 ] = 64'h03987F8007007400;
	char3[7 ] = 64'h039FFC0003003800;
	char3[8 ] = 64'h071E1C0002101820;
	char3[9 ] = 64'h071C1C00001FFFF8;
	char3[10] = 64'h0F9C1C0000181030;
	char3[11] = 64'h0F1C1C0000181030;
	char3[12] = 64'h1F1C1C0001181030;
	char3[13] = 64'h1F1C1C007F9FFFF0;
	char3[14] = 64'h3F1C1C3803181030;
	char3[15] = 64'h771FFFFC03181030;
	char3[16] = 64'h671C1C0003181030;
	char3[17] = 64'h071C1C0003181030;
	char3[18] = 64'h071C1E00031FFFF0;
	char3[19] = 64'h071C0E0003181030;
	char3[20] = 64'h071C0E0003181030;
	char3[21] = 64'h071C0E0003181030;
	char3[22] = 64'h071C0F0003181030;
	char3[23] = 64'h071C370C03181030;
	char3[24] = 64'h071C778C031811F0;
	char3[25] = 64'h071DE3CC0C900060;
	char3[26] = 64'h071FE3FC38600000;
	char3[27] = 64'h071F71FC703E000E;
	char3[28] = 64'h071E78FC200FFFF8;
	char3[29] = 64'h070C387C0000FFF0;
	char3[30] = 64'h0700181C00000000;
	char3[31] = 64'h0000000000000000;
end

//显示的是 ：高通
initial begin
	char4[0 ] = 64'h0000000000000000;
	char4[1 ] = 64'h0000000000000000;
	char4[2 ] = 64'h000F000000000040;
	char4[3 ] = 64'h00078000080FFFE0;
	char4[4 ] = 64'h0003C0000C0001E0;
	char4[5 ] = 64'h0003801C06008300;
	char4[6 ] = 64'h3FFFFFFE07007400;
	char4[7 ] = 64'h1800000003003800;
	char4[8 ] = 64'h00C0060002101820;
	char4[9 ] = 64'h00FFFF00001FFFF8;
	char4[10] = 64'h00E00F0000181030;
	char4[11] = 64'h00E00F0000181030;
	char4[12] = 64'h00E00F0001181030;
	char4[13] = 64'h00FFFF007F9FFFF0;
	char4[14] = 64'h00E00F0003181030;
	char4[15] = 64'h00C0040003181030;
	char4[16] = 64'h0C00003003181030;
	char4[17] = 64'h0FFFFFF803181030;
	char4[18] = 64'h0E000078031FFFF0;
	char4[19] = 64'h0E301C7803181030;
	char4[20] = 64'h0E3FFE7803181030;
	char4[21] = 64'h0E381C7803181030;
	char4[22] = 64'h0E381C7803181030;
	char4[23] = 64'h0E381C7803181030;
	char4[24] = 64'h0E381C78031811F0;
	char4[25] = 64'h0E3FFC780C900060;
	char4[26] = 64'h0E381C7838600000;
	char4[27] = 64'h0E301878703E000E;
	char4[28] = 64'h0E0007F0200FFFF8;
	char4[29] = 64'h0E0001F00000FFF0;
	char4[30] = 64'h0C00007000000000;
	char4[31] = 64'h0000000000000000;
end

//显示的是 ：带通
initial begin
	char5[0 ] = 64'h0000000000000000;
	char5[1 ] = 64'h0000000000000000;
	char5[2 ] = 64'h00E1860000000040;
	char5[3 ] = 64'h00F1C780080FFFE0;
	char5[4 ] = 64'h00F1C7000C0001E0;
	char5[5 ] = 64'h00F1C73006008300;
	char5[6 ] = 64'h00F1C77807007400;
	char5[7 ] = 64'h3FFFFFFC03003800;
	char5[8 ] = 64'h08F1C70002101820;
	char5[9 ] = 64'h00F1C700001FFFF8;
	char5[10] = 64'h00F1C70000181030;
	char5[11] = 64'h00E1C70000181030;
	char5[12] = 64'h0C00001C01181030;
	char5[13] = 64'h0FFFFFFC7F9FFFF0;
	char5[14] = 64'h1C01C03E03181030;
	char5[15] = 64'h3C01C03803181030;
	char5[16] = 64'h7C01C06003181030;
	char5[17] = 64'h3181C1C003181030;
	char5[18] = 64'h01FFFFE0031FFFF0;
	char5[19] = 64'h01C1C1C003181030;
	char5[20] = 64'h01C1C1C003181030;
	char5[21] = 64'h01C1C1C003181030;
	char5[22] = 64'h01C1C1C003181030;
	char5[23] = 64'h01C1C1C003181030;
	char5[24] = 64'h01C1C1C0031811F0;
	char5[25] = 64'h01C1C1C00C900060;
	char5[26] = 64'h01C1FFC038600000;
	char5[27] = 64'h01C1CF80703E000E;
	char5[28] = 64'h01C1C780200FFFF8;
	char5[29] = 64'h0001C0000000FFF0;
	char5[30] = 64'h0001C00000000000;
	char5[31] = 64'h0000000000000000;
end


//显示的是 ：带阻
initial begin
	char6[0 ] = 64'h0000000000000000;
	char6[1 ] = 64'h0000000000000000;
	char6[2 ] = 64'h00E1860000000000;
	char6[3 ] = 64'h00F1C78010200040;
	char6[4 ] = 64'h00F1C7001FF9FFE0;
	char6[5 ] = 64'h00F1C730183180E0;
	char6[6 ] = 64'h00F1C778186180C0;
	char6[7 ] = 64'h3FFFFFFC184180C0;
	char6[8 ] = 64'h08F1C700184180C0;
	char6[9 ] = 64'h00F1C70018C180C0;
	char6[10] = 64'h00F1C700188180C0;
	char6[11] = 64'h00E1C700188180C0;
	char6[12] = 64'h0C00001C1901FFC0;
	char6[13] = 64'h0FFFFFFC188180C0;
	char6[14] = 64'h1C01C03E184180C0;
	char6[15] = 64'h3C01C038182180C0;
	char6[16] = 64'h7C01C060182180C0;
	char6[17] = 64'h3181C1C0183180C0;
	char6[18] = 64'h01FFFFE0183180C0;
	char6[19] = 64'h01C1C1C0183180C0;
	char6[20] = 64'h01C1C1C01831FFC0;
	char6[21] = 64'h01C1C1C0183180C0;
	char6[22] = 64'h01C1C1C019F180C0;
	char6[23] = 64'h01C1C1C018E180C0;
	char6[24] = 64'h01C1C1C0180180C0;
	char6[25] = 64'h01C1C1C0180180C0;
	char6[26] = 64'h01C1FFC0180180C0;
	char6[27] = 64'h01C1CF80180180CC;
	char6[28] = 64'h01C1C780183FFFFC;
	char6[29] = 64'h0001C00018000000;
	char6[30] = 64'h0001C00010000000;
	char6[31] = 64'h0000000000000000;
end

//数字0
initial begin
	num_0[0 ] = 8'h00;
	num_0[1 ] = 8'h00;
	num_0[2 ] = 8'h00;
	num_0[3 ] = 8'h18;
	num_0[4 ] = 8'h24;
	num_0[5 ] = 8'h42;
	num_0[6 ] = 8'h42;
	num_0[7 ] = 8'h42;
	num_0[8 ] = 8'h42;
	num_0[9 ] = 8'h42;
	num_0[10] = 8'h42;
	num_0[11] = 8'h42;
	num_0[12] = 8'h24;
	num_0[13] = 8'h18;
	num_0[14] = 8'h00;
	num_0[15] = 8'h00;
end

//数字1
initial begin
	num_1[0 ] = 8'h00;
	num_1[1 ] = 8'h00;
	num_1[2 ] = 8'h00;
	num_1[3 ] = 8'h08;
	num_1[4 ] = 8'h38;
	num_1[5 ] = 8'h08;
	num_1[6 ] = 8'h08;
	num_1[7 ] = 8'h08;
	num_1[8 ] = 8'h08;
	num_1[9 ] = 8'h08;
	num_1[10] = 8'h08;
	num_1[11] = 8'h08;
	num_1[12] = 8'h08;
	num_1[13] = 8'h3E;
	num_1[14] = 8'h00;
	num_1[15] = 8'h00;
end

//数字2
initial begin
	num_2[0 ] = 8'h00;
	num_2[1 ] = 8'h00;
	num_2[2 ] = 8'h00;
	num_2[3 ] = 8'h3C;
	num_2[4 ] = 8'h42;
	num_2[5 ] = 8'h42;
	num_2[6 ] = 8'h42;
	num_2[7 ] = 8'h02;
	num_2[8 ] = 8'h04;
	num_2[9 ] = 8'h08;
	num_2[10] = 8'h10;
	num_2[11] = 8'h20;
	num_2[12] = 8'h42;
	num_2[13] = 8'h7E;
	num_2[14] = 8'h00;
	num_2[15] = 8'h00;
end

//数字3
initial begin
	num_3[0 ] = 8'h00;
	num_3[1 ] = 8'h00;
	num_3[2 ] = 8'h00;
	num_3[3 ] = 8'h3C;
	num_3[4 ] = 8'h42;
	num_3[5 ] = 8'h42;
	num_3[6 ] = 8'h02;
	num_3[7 ] = 8'h04;
	num_3[8 ] = 8'h18;
	num_3[9 ] = 8'h04;
	num_3[10] = 8'h02;
	num_3[11] = 8'h42;
	num_3[12] = 8'h42;
	num_3[13] = 8'h3C;
	num_3[14] = 8'h00;
	num_3[15] = 8'h00;
end

//数字4
initial begin
	num_4[0 ] = 8'h00;
	num_4[1 ] = 8'h00;
	num_4[2 ] = 8'h00;
	num_4[3 ] = 8'h04;
	num_4[4 ] = 8'h0C;
	num_4[5 ] = 8'h0C;
	num_4[6 ] = 8'h14;
	num_4[7 ] = 8'h24;
	num_4[8 ] = 8'h24;
	num_4[9 ] = 8'h44;
	num_4[10] = 8'h7F;
	num_4[11] = 8'h04;
	num_4[12] = 8'h04;
	num_4[13] = 8'h1F;
	num_4[14] = 8'h00;
	num_4[15] = 8'h00;
end

//数字5
initial begin
	num_5[0 ] = 8'h00;
	num_5[1 ] = 8'h00;
	num_5[2 ] = 8'h00;
	num_5[3 ] = 8'h7E;
	num_5[4 ] = 8'h40;
	num_5[5 ] = 8'h40;
	num_5[6 ] = 8'h40;
	num_5[7 ] = 8'h78;
	num_5[8 ] = 8'h44;
	num_5[9 ] = 8'h02;
	num_5[10] = 8'h02;
	num_5[11] = 8'h42;
	num_5[12] = 8'h44;
	num_5[13] = 8'h38;
	num_5[14] = 8'h00;
	num_5[15] = 8'h00;
end


//数字6
initial begin
	num_6[0 ] = 8'h00;
	num_6[1 ] = 8'h00;
	num_6[2 ] = 8'h00;
	num_6[3 ] = 8'h18;
	num_6[4 ] = 8'h24;
	num_6[5 ] = 8'h40;
	num_6[6 ] = 8'h40;
	num_6[7 ] = 8'h5C;
	num_6[8 ] = 8'h62;
	num_6[9 ] = 8'h42;
	num_6[10] = 8'h42;
	num_6[11] = 8'h42;
	num_6[12] = 8'h22;
	num_6[13] = 8'h1C;
	num_6[14] = 8'h00;
	num_6[15] = 8'h00;
end


//数字7
initial begin
	num_7[0 ] = 8'h00;
	num_7[1 ] = 8'h00;
	num_7[2 ] = 8'h00;
	num_7[3 ] = 8'h7E;
	num_7[4 ] = 8'h42;
	num_7[5 ] = 8'h04;
	num_7[6 ] = 8'h04;
	num_7[7 ] = 8'h08;
	num_7[8 ] = 8'h08;
	num_7[9 ] = 8'h10;
	num_7[10] = 8'h10;
	num_7[11] = 8'h10;
	num_7[12] = 8'h10;
	num_7[13] = 8'h10;
	num_7[14] = 8'h00;
	num_7[15] = 8'h00;
end


//数字8
initial begin
	num_8[0 ] = 8'h00;
	num_8[1 ] = 8'h00;
	num_8[2 ] = 8'h00;
	num_8[3 ] = 8'h3C;
	num_8[4 ] = 8'h42;
	num_8[5 ] = 8'h42;
	num_8[6 ] = 8'h42;
	num_8[7 ] = 8'h24;
	num_8[8 ] = 8'h18;
	num_8[9 ] = 8'h24;
	num_8[10] = 8'h42;
	num_8[11] = 8'h42;
	num_8[12] = 8'h42;
	num_8[13] = 8'h3C;
	num_8[14] = 8'h00;
	num_8[15] = 8'h00;
end

//数字9
initial begin
	num_9[0 ] = 8'h00;
	num_9[1 ] = 8'h00;
	num_9[2 ] = 8'h00;
	num_9[3 ] = 8'h38;
	num_9[4 ] = 8'h44;
	num_9[5 ] = 8'h42;
	num_9[6 ] = 8'h42;
	num_9[7 ] = 8'h42;
	num_9[8 ] = 8'h46;
	num_9[9 ] = 8'h3A;
	num_9[10] = 8'h02;
	num_9[11] = 8'h02;
	num_9[12] = 8'h24;
	num_9[13] = 8'h18;
	num_9[14] = 8'h00;
	num_9[15] = 8'h00;
end

//字符 .
initial begin
	char_p[0 ] = 8'h00;
	char_p[1 ] = 8'h00;
	char_p[2 ] = 8'h00;
	char_p[3 ] = 8'h00;
	char_p[4 ] = 8'h00;
	char_p[5 ] = 8'h00;
	char_p[6 ] = 8'h00;
	char_p[7 ] = 8'h00;
	char_p[8 ] = 8'h00;
	char_p[9 ] = 8'h00;
	char_p[10] = 8'h00;
	char_p[11] = 8'h00;
	char_p[12] = 8'h60;
	char_p[13] = 8'h60;
	char_p[14] = 8'h00;
	char_p[15] = 8'h00;
end



endmodule
