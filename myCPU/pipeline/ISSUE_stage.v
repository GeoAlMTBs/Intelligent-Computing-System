`include "../mycpu.h"
`define BUF_LEN 3
`define INST_BUF_SIZE (1 << 4)
module issue_stage(
    input                           clk             ,
    input                           reset           ,
    //ds
    output                         issue_allowin,
    input                          ds_to_issue_valid_0,
    input                          ds_to_issue_valid_1,
    input [`DECODE_BUS_WD -1:0]    ds_to_issue_bus_0 ,
    input [`DECODE_BUS_WD -1:0]    ds_to_issue_bus_1 ,
    //es
    input                           es_allowin      ,
    input                           es_flush        ,
    output [`SIMPLE_ES_BUS_WD-1 :0] simple_es_bus,
    output [`COMPLEX_ES_BUS_WD-1:0] complex_es_bus,
    output                          simple_es_bus_valid,
    output                          complex_es_bus_valid,
    //to regfile
    output [ 4                :0]   rf_raddr0    ,
    output [ 4                :0]   rf_raddr1    ,
    output [ 4                :0]   rf_raddr2    ,
    output [ 4                :0]   rf_raddr3    ,
    input  [31                :0]   rf_rdata0    ,
    input  [31                :0]   rf_rdata1    ,
    input  [31                :0]   rf_rdata2    ,
    input  [31                :0]   rf_rdata3    ,
    //forwarding
    input  [`ES_FWD_BUS-1     :0]   es_fwd_bus_0,
    input  [`ES_FWD_BUS-1     :0]   es_fwd_bus_1,
    input  [`M1S_FWD_BUS-1    :0]   m1s_fwd_bus_0,
    input  [`M1S_FWD_BUS-1    :0]   m1s_fwd_bus_1,
    input  [`M2S_FWD_BUS-1    :0]   m2s_fwd_bus_0,
    input  [`M2S_FWD_BUS-1    :0]   m2s_fwd_bus_1,

    input                           es_res_from_cp0,
    input                           m1s_res_from_cp0,
    input                           m2s_res_from_cp0,
    input                           es_mem_read,
    input                           m1s_mem_read,
    input                           m2s_mem_read,
    input                           m2s_res_from_mem_ok

             
);



wire [1:0] issue_mode;

//================================== issue quene ==================================

//input
wire                        fifo_valid_0;
wire                        fifo_valid_1;
wire [`DECODE_BUS_WD -1:0]  fifo_out_0;
wire [`DECODE_BUS_WD -1:0]  fifo_out_1;

wire                        fifo_ready_go;


//inst buffer size
reg [`DECODE_BUS_WD -1:0] buffer [0:`INST_BUF_SIZE-1];
reg [`INST_BUF_SIZE-1 : 0] valid;
reg [`BUF_LEN : 0] head;
reg [`BUF_LEN : 0] tail;
reg [`BUF_LEN+1 : 0] i;
wire        full;  
// wire        empty;
assign full  = valid[tail + `BUF_LEN'b1];

//EnQuene
always@(posedge clk)begin
    if(reset || es_flush)
        tail <= 0;
    else if(ds_to_issue_valid_0 && ds_to_issue_valid_1 && !full)
        tail <= tail + `BUF_LEN'h2;
    else if(ds_to_issue_valid_0 && !full)
        tail <= tail + `BUF_LEN'b1;
end

always@(posedge clk)begin
    if(ds_to_issue_valid_0 && ds_to_issue_valid_1 && !full)begin
        buffer[tail]                  <= ds_to_issue_bus_0;
        buffer[tail+`BUF_LEN'b1]      <= ds_to_issue_bus_1;
    end
    else if(ds_to_issue_valid_0 && !full)begin
        buffer[tail]                  <= ds_to_issue_bus_0;
    end
end

always@(posedge clk)begin
    if(reset || es_flush)begin
        valid          <= 0;
    end
    else begin
        if(ds_to_issue_valid_0 && ds_to_issue_valid_1 && !full)begin
            valid[tail]                 <= 1'b1;
            valid[tail+`BUF_LEN'b1]     <= 1'b1;
        end
        else if(ds_to_issue_valid_0 && !full)
            valid[tail]                 <= 1'b1;
        
        if(issue_mode == `DUAL)begin
            valid[head]                 <= 1'b0;
            valid[head+ `BUF_LEN'h1]    <= 1'b0;
        end
        else if(issue_mode == `SIGNLE)
            valid[head]                 <= 1'b0;
    end
end

//issue
always@(posedge clk)begin
    if(reset || es_flush)
        head <= 0;
    else if(issue_mode == `DUAL)
        head <= head + `BUF_LEN'h2;
    else if(issue_mode == `SIGNLE)
        head <= head + `BUF_LEN'h1;
end




// IF stage
assign fifo_valid_0         = valid[head];
assign fifo_valid_1         = valid[head + `BUF_LEN'b1];
assign issue_allowin        = !full;
assign fifo_out_0           = buffer[head];
assign fifo_out_1           = buffer[head + `BUF_LEN'b1];











//================================== issue quene ==================================
wire  [31:                 0]   es_alu_result_0;
wire  [31:                 0]   es_alu_result_1;
wire  [31:                 0]   m1s_alu_result_0;
wire  [31:                 0]   m1s_alu_result_1;
wire  [31:                 0]   m2s_alu_result_0;
wire  [31:                 0]   m2s_alu_result_1;
wire  [4                 :0]    es_rd_0       ;
wire  [4                 :0]    es_rd_1       ;
wire  [4                 :0]    m1s_rd_0       ;
wire  [4                 :0]    m1s_rd_1       ;
wire  [4                 :0]    m2s_rd_0       ;
wire  [4                 :0]    m2s_rd_1       ;
wire                            es_reg_write_0;
wire                            es_reg_write_1;
wire                            m1s_reg_write_0;
wire                            m1s_reg_write_1;
wire                            m2s_reg_write_0;
wire                            m2s_reg_write_1;
wire                            es_valid_0    ;
wire                            es_valid_1    ;
wire                            m1s_valid_0    ;
wire                            m1s_valid_1    ;
wire                            m2s_valid_0    ;
wire                            m2s_valid_1    ;

wire  [4                 :0]    iss_rs1_0       ;
wire  [4                 :0]    iss_rs2_0       ;
wire  [4                 :0]    iss_rs1_1       ;
wire  [4                 :0]    iss_rs2_1       ;
wire  [4                 :0]    iss_rd_0       ;
wire  [4                 :0]    iss_rd_1       ;
wire [`ISSUE_BUS_WD-1     : 0]  issue_bus_0;
wire [`ISSUE_BUS_WD-1     : 0]  issue_bus_1;
wire                            b_or_j_0;
wire                            b_or_j_1;
wire                            sub_1_is_bd;
wire                            iss_ex_0;
wire                            iss_ex_1;

wire                        rd_after_wr;
wire                        wr_after_wr;
wire                        dual_issue;
wire                        signle_issue;

assign {
        es_valid_0,
        es_reg_write_0,
        es_rd_0,
        es_alu_result_0} = es_fwd_bus_0;
assign {
        es_valid_1,
        es_reg_write_1,
        es_rd_1,
        es_alu_result_1} = es_fwd_bus_1;
assign {
        m1s_valid_0,
        m1s_reg_write_0,
        m1s_rd_0,
        m1s_alu_result_0} = m1s_fwd_bus_0;
assign {
        m1s_valid_1,
        m1s_reg_write_1,
        m1s_rd_1,
        m1s_alu_result_1} = m1s_fwd_bus_1;
assign {
        m2s_valid_0,
        m2s_reg_write_0,
        m2s_rd_0,
        m2s_alu_result_0} = m2s_fwd_bus_0;
assign {
        m2s_valid_1,
        m2s_reg_write_1,
        m2s_rd_1,
        m2s_alu_result_1} = m2s_fwd_bus_1;

issue_sub id_sub_0(
    //ds
    .valid_i                        (fifo_valid_0       ),
    .decode_bus_i                   (fifo_out_0         ),
    .first                          (1'b1               ),
    
    .inst_type                      (inst_type_0        ), //simple or complex
    .ready_go                       (sub_0_ready_go     ),
    .issue_bus                      (issue_bus_0        ),
    .special_inst                   (special_inst_0     ),
    .iss_ex                         (iss_ex_0           ),

    .iss_rs1                        (iss_rs1_0           ),
    .iss_rs2                        (iss_rs2_0           ),
    .iss_rd                         (iss_rd_0            ),
    //to regfile
    .rf_raddr0                      (rf_raddr0          ),
    .rf_rdata0                      (rf_rdata0          ),
    .rf_raddr1                      (rf_raddr1          ),
    .rf_rdata1                      (rf_rdata1          ),

    //forwarding
    .es_alu_result_0                (es_alu_result_0    ),
    .es_alu_result_1                (es_alu_result_1    ),
    .m1s_alu_result_0               (m1s_alu_result_0   ),
    .m1s_alu_result_1               (m1s_alu_result_1   ),
    .m2s_alu_result_0               (m2s_alu_result_0   ),
    .m2s_alu_result_1               (m2s_alu_result_1   ),
    .es_rd_0                        (es_rd_0            ),
    .es_rd_1                        (es_rd_1            ),
    .m1s_rd_0                       (m1s_rd_0           ),
    .m1s_rd_1                       (m1s_rd_1           ),
    .m2s_rd_0                       (m2s_rd_0           ),
    .m2s_rd_1                       (m2s_rd_1           ),
    .es_reg_write_0                 (es_reg_write_0     ),
    .es_reg_write_1                 (es_reg_write_1     ),
    .m1s_reg_write_0                (m1s_reg_write_0    ),
    .m1s_reg_write_1                (m1s_reg_write_1    ),
    .m2s_reg_write_0                (m2s_reg_write_0    ),
    .m2s_reg_write_1                (m2s_reg_write_1    ),
    .es_valid_0                     (es_valid_0         ),
    .es_valid_1                     (es_valid_1         ),
    .m1s_valid_0                    (m1s_valid_0        ),
    .m1s_valid_1                    (m1s_valid_1        ),
    .m2s_valid_0                    (m2s_valid_0        ),
    .m2s_valid_1                    (m2s_valid_1        ),

    .es_res_from_cp0                (es_res_from_cp0    ),
    .m1s_res_from_cp0               (m1s_res_from_cp0   ),
    .m2s_res_from_cp0               (m2s_res_from_cp0   ),
    .es_mem_read                    (es_mem_read        ),
    .m1s_mem_read                   (m1s_mem_read       ),
    .m2s_mem_read                   (m2s_mem_read       ),
    .m2s_res_from_mem_ok            (m2s_res_from_mem_ok),



    .b_or_j                         (b_or_j_0           ),
    .preinst_is_bj                  (1'b0               ),
    .iss_bd                         (                   )
);

issue_sub id_sub_1(
    //ds
    .valid_i                        (fifo_valid_1 ),
    .decode_bus_i                   (fifo_out_1   ),
    .first                          (1'b0               ),
    
    .inst_type                      (inst_type_1        ), //simple or complex
    .ready_go                       (sub_1_ready_go     ),
    .issue_bus                      (issue_bus_1        ),
    .special_inst                   (special_inst_1     ),
    .iss_ex                         (iss_ex_1           ),
    
    .iss_rs1                        (iss_rs1_1          ),
    .iss_rs2                        (iss_rs2_1          ),
    .iss_rd                         (iss_rd_1           ),
    //to regfile
    .rf_raddr0                      (rf_raddr2          ),
    .rf_rdata0                      (rf_rdata2          ),
    .rf_raddr1                      (rf_raddr3          ),
    .rf_rdata1                      (rf_rdata3          ),

    //forwarding
    .es_alu_result_0                (es_alu_result_0    ),
    .es_alu_result_1                (es_alu_result_1    ),
    .m1s_alu_result_0               (m1s_alu_result_0   ),
    .m1s_alu_result_1               (m1s_alu_result_1   ),
    .m2s_alu_result_0               (m2s_alu_result_0   ),
    .m2s_alu_result_1               (m2s_alu_result_1   ),
    .es_rd_0                        (es_rd_0            ),
    .es_rd_1                        (es_rd_1            ),
    .m1s_rd_0                       (m1s_rd_0           ),
    .m1s_rd_1                       (m1s_rd_1           ),
    .m2s_rd_0                       (m2s_rd_0           ),
    .m2s_rd_1                       (m2s_rd_1           ),
    .es_reg_write_0                 (es_reg_write_0     ),
    .es_reg_write_1                 (es_reg_write_1     ),
    .m1s_reg_write_0                (m1s_reg_write_0    ),
    .m1s_reg_write_1                (m1s_reg_write_1    ),
    .m2s_reg_write_0                (m2s_reg_write_0    ),
    .m2s_reg_write_1                (m2s_reg_write_1    ),
    .es_valid_0                     (es_valid_0         ),
    .es_valid_1                     (es_valid_1         ),
    .m1s_valid_0                    (m1s_valid_0        ),
    .m1s_valid_1                    (m1s_valid_1        ),
    .m2s_valid_0                    (m2s_valid_0        ),
    .m2s_valid_1                    (m2s_valid_1        ),

    .es_res_from_cp0                (es_res_from_cp0    ),
    .m1s_res_from_cp0               (m1s_res_from_cp0   ),
    .m2s_res_from_cp0               (m2s_res_from_cp0   ),
    .es_mem_read                    (es_mem_read        ),
    .m1s_mem_read                   (m1s_mem_read       ),
    .m2s_mem_read                   (m2s_mem_read       ),
    .m2s_res_from_mem_ok            (m2s_res_from_mem_ok),


    //
    .b_or_j                         (b_or_j_1           ),
    .preinst_is_bj                  (b_or_j_0           ),
    .iss_bd                         (sub_1_is_bd        )
);



assign iss_reg_write_0 = issue_bus_0[118];
assign iss_reg_write_1 = issue_bus_1[118];
assign rd_after_wr  = (iss_rd_0 == iss_rs1_1 || iss_rd_0 == iss_rs2_1) && iss_reg_write_0 && (iss_rd_0 != 0);
assign wr_after_wr  = (iss_rd_0 == iss_rd_1) && iss_reg_write_0 && iss_reg_write_1 && (iss_rd_0 != 0);
assign dual_issue   = (sub_0_ready_go & fifo_valid_0 & sub_1_ready_go & fifo_valid_1) && !(inst_type_0 && inst_type_1) 
                        && !b_or_j_1 && !rd_after_wr && !wr_after_wr && !(special_inst_0 | special_inst_1);
assign signle_issue = sub_0_ready_go & fifo_valid_0 & !(b_or_j_0 & !iss_ex_0);
// assign ds_to_issue_valid_0 = fifo_valid_0;
// assign ds_to_issue_valid_1 = fifo_valid_1;
assign issue_mode   = (dual_issue & es_allowin) ? `DUAL
                    : (signle_issue & es_allowin) ? `SIGNLE
                    : 0;

assign complex_es_bus = (issue_mode == `DUAL && inst_type_0)    ? {issue_bus_0[231],issue_bus_0[185:0]}
                      : (issue_mode == `DUAL)                   ? {issue_bus_1[231],issue_bus_1[185:0]}
                      : (issue_mode == `SIGNLE)                 ? {issue_bus_0[231],issue_bus_0[185:0]}
                      : 0;
assign simple_es_bus  = (issue_mode == `DUAL && inst_type_0) ? {issue_bus_1[231:186],issue_bus_1[150:118],issue_bus_1[116:0]}
                      : (issue_mode == `DUAL)                ? {issue_bus_0[231:186],issue_bus_0[150:118],issue_bus_0[116:0]}
                      : 0;

assign simple_es_bus_valid = (issue_mode == `DUAL) && !es_flush;
assign complex_es_bus_valid = ((issue_mode == `DUAL) || (issue_mode == `SIGNLE)) && !es_flush;

endmodule




 













