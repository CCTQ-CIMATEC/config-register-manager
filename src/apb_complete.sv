module apb4_csr_top (
    input wire clk,
    input wire rst,
    
    // APB4 Interface
    apb4_intf.slave s_apb,
);

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    localparam ADDR_WIDTH = 3;
    localparam DATA_WIDTH = 32;

    //--------------------------------------------------------------------------
    // Signals between APB slave and CSR module
    //--------------------------------------------------------------------------
    logic cpuif_req;
    logic cpuif_req_is_wr;
    logic [ADDR_WIDTH-1:0] cpuif_addr;
    logic [DATA_WIDTH-1:0] cpuif_wr_data;
    logic [DATA_WIDTH-1:0] cpuif_wr_biten;
    logic cpuif_rd_ack;
    logic cpuif_rd_err;
    logic [DATA_WIDTH-1:0] cpuif_rd_data;
    logic cpuif_wr_ack;
    logic cpuif_wr_err;

    CSR_IP_Map__in_t  hwif_in,
    CSR_IP_Map__out_t hwif_out

    //--------------------------------------------------------------------------
    // APB4 Slave Instance
    //--------------------------------------------------------------------------
    apb4_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_apb4_slave (
        .clk              (clk),
        .rst              (rst),
        .s_apb            (s_apb),
        
        // CPU Interface inputs
        .cpuif_rd_ack     (cpuif_rd_ack),
        .cpuif_rd_err     (cpuif_rd_err),
        .cpuif_rd_data    (cpuif_rd_data),
        .cpuif_wr_ack     (cpuif_wr_ack),
        .cpuif_wr_err     (cpuif_wr_err),

        // CPU Interface outputs
        .cpuif_req          (cpuif_req),
        .cpuif_req_is_wr    (cpuif_req_is_wr),
        .cpuif_addr         (cpuif_addr),
        .cpuif_wr_data      (cpuif_wr_data),
        .cpuif_wr_biten     (cpuif_wr_biten),
        .cpuif_req_stall_wr (cpuif_req_stall_wr),
        .cpuif_req_stall_rd (cpuif_req_stall_rd)
    );


    //--------------------------------------------------------------------------
    // CSR_IP_Map Instance
    //--------------------------------------------------------------------------
    CSR_IP_Map u_csr_ip_map (
        .clk             (clk),
        .rst             (rst),
        
        // Register interface from APB slave
        .i_req_enable    (cpuif_req),
        .i_write_enable  (cpuif_req_is_wr),
        .i_addr          (cpuif_addr),
        .i_wdata         (cpuif_wr_data),
        .i_wdata_biten   (cpuif_wr_biten),
        .o_pready        (cpuif_req),  // Sempre ready quando há requisição
        .o_rdata         (cpuif_rd_data),
        .o_err           (cpuif_rd_err),
        
        // Hardware interface (pass-through)
        .hwif_in         (hwif_in),
        .hwif_out        (hwif_out)
    );

    //--------------------------------------------------------------------------
    // Write Response Assignment
    //--------------------------------------------------------------------------
    // Para writes, assumimos que sempre são completados imediatamente
    assign cpuif_wr_ack = cpuif_req & cpuif_req_is_wr;
    assign cpuif_wr_err = 1'b0;  // Writes nunca geram erro

endmodule