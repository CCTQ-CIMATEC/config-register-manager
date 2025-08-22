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
    logic bus_req;
    logic bus_req_is_wr;
    logic [ADDR_WIDTH-1:0] bus_addr;
    logic [DATA_WIDTH-1:0] bus_wr_data;
    logic [DATA_WIDTH-1:0] bus_wr_biten;
    logic bus_rd_ack;
    logic bus_rd_err;
    logic [DATA_WIDTH-1:0] bus_rd_data;
    logic bus_wr_ack;
    logic bus_wr_err;

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
        .i_bus_rd_ack     (bus_rd_ack),
        .i_bus_rd_err     (bus_rd_err),
        .i_bus_rd_data    (bus_rd_data),
        .i_bus_wr_ack     (bus_wr_ack),
        .i_bus_wr_err     (bus_wr_err),

        // CPU Interface outputs
        .o_bus_req          (bus_req),
        .o_bus_req_is_wr    (bus_req_is_wr),
        .o_bus_addr         (bus_addr),
        .o_bus_wr_data      (bus_wr_data),
        .o_bus_wr_biten     (bus_wr_biten),
        .o_bus_req_stall_wr (bus_req_stall_wr),
        .o_bus_req_stall_rd (bus_req_stall_rd)
    );


    //--------------------------------------------------------------------------
    // CSR_IP_Map Instance
    //--------------------------------------------------------------------------
    CSR_IP_Map u_csr_ip_map (
        .clk             (clk),
        .rst             (rst),
        
        // Register interface from APB slave
        .i_req_enable    (bus_req),
        .i_write_enable  (bus_req_is_wr),
        .i_addr          (bus_addr),
        .i_wdata         (bus_wr_data),
        .i_wdata_biten   (bus_wr_biten),
        .o_pready        (bus_req),  // Sempre ready quando há requisição
        .o_rdata         (bus_rd_data),
        .o_err           (bus_rd_err),
        
        // Hardware interface (pass-through)
        .hwif_in         (hwif_in),
        .hwif_out        (hwif_out)
    );

    //--------------------------------------------------------------------------
    // Write Response Assignment
    //--------------------------------------------------------------------------
    // Para writes, assumimos que sempre são completados imediatamente
    assign bus_wr_ack = bus_req & bus_req_is_wr;
    assign bus_wr_err = 1'b0;  // Writes nunca geram erro

endmodule