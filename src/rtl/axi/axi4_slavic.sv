module axi4lite_slave #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 32
)(
    input logic S_AXI_clk,
    input logic S_AXI_rst_n,
    
    // AW Channel
    input logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input logic [3:0]                    S_AXI_AWCACHE,
    input logic [2:0]                    S_AXI_AWPROT,
    input logic                          S_AXI_AWVALID,
    output logic                         S_AXI_AWREADY,
    
    // W Channel
    input logic [C_S_AXI_DATA_WIDTH-1:0]     S_AXI_WDATA,
    input logic [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input logic                               S_AXI_WVALID,
    output logic                              S_AXI_WREADY,
    
    // B Channel
    output logic [1:0] S_AXI_BRESP,
    output logic       S_AXI_BVALID,
    input logic        S_AXI_BREADY,
    
    // AR Channel
    input logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input logic [3:0]                    S_AXI_ARCACHE,
    input logic [2:0]                    S_AXI_ARPROT,
    input logic                          S_AXI_ARVALID,
    output logic                         S_AXI_ARREADY,
    
    // R Channel
    output logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output logic [1:0]                    S_AXI_RRESP,
    output logic                          S_AXI_RVALID,
    input logic                           S_AXI_RREADY,
    
    // Bus Interface
    axi4lite_bus_interface.AXI_SLAVE bus_if
);

    // AXI4-Lite response types
    localparam [1:0] RESP_OKAY   = 2'b00;
    localparam [1:0] RESP_EXOKAY = 2'b01;
    localparam [1:0] RESP_SLVERR = 2'b10;
    localparam [1:0] RESP_DECERR = 2'b11;
    
    // State machine types
    typedef enum logic [1:0] {
        WRITE_IDLE,
        WRITE_DATA,  
        WRITE_RESP
    } write_state_t;
    
    typedef enum logic [1:0] {
        READ_IDLE,
        READ_DATA
    } read_state_t;
    
    // Internal signals
    write_state_t write_state;
    read_state_t read_state;
    
    logic [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    logic [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    logic axi_awready;
    logic axi_wready;
    logic axi_bvalid;
    logic [1:0] axi_bresp;
    logic axi_arready;
    logic [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    logic axi_rvalid;
    logic [1:0] axi_rresp;
    
    // Connect bus interface clock and reset
    assign bus_if.clk = S_AXI_clk;
    assign bus_if.reset = ~S_AXI_rst_n;
    
    // Assign AXI outputs
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;
    
    //==========================================================================
    // Write Transaction State Machine
    //==========================================================================
    always_ff @(posedge S_AXI_clk) begin
        if (!S_AXI_rst_n) begin
            write_state <= WRITE_IDLE;
            axi_awready <= 1'b0;
            axi_wready  <= 1'b0;
            axi_bvalid  <= 1'b0;
            axi_bresp   <= RESP_OKAY;
            axi_awaddr  <= 0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    if (S_AXI_AWVALID && S_AXI_WVALID) begin
                        // Both address and data are valid, start transaction
                        write_state <= WRITE_DATA;
                        axi_awready <= 1'b1;
                        axi_wready  <= 1'b1; 
                        axi_awaddr  <= S_AXI_AWADDR;
                    end
                end
                
                WRITE_DATA: begin
                    // Complete the handshakes
                    axi_awready <= 1'b0;
                    axi_wready  <= 1'b0;
                    write_state <= WRITE_RESP;
                    
                    // Generate response based on bus interface result
                    if (bus_if.bus_err) begin
                        axi_bresp <= RESP_SLVERR;
                    end else begin
                        axi_bresp <= RESP_OKAY;
                    end
                    axi_bvalid <= 1'b1;
                end
                
                WRITE_RESP: begin
                    if (S_AXI_BREADY && axi_bvalid) begin
                        // Master accepted response
                        axi_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
            endcase
        end
    end
    
    //==========================================================================
    // Read Transaction State Machine  
    //==========================================================================
    always_ff @(posedge S_AXI_clk) begin
        if (!S_AXI_rst_n) begin
            read_state  <= READ_IDLE;
            axi_arready <= 1'b0;
            axi_rvalid  <= 1'b0;
            axi_rresp   <= RESP_OKAY;
            axi_rdata   <= 0;
            axi_araddr  <= 0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (S_AXI_ARVALID) begin
                        // Address is valid, start transaction
                        read_state  <= READ_DATA;
                        axi_arready <= 1'b1;
                        axi_araddr  <= S_AXI_ARADDR;
                    end
                end
                
                READ_DATA: begin
                    // Complete address handshake and wait for bus response
                    axi_arready <= 1'b0;
                    
                    if (bus_if.bus_ready) begin
                        // Bus transaction completed
                        axi_rvalid <= 1'b1;
                        axi_rdata  <= bus_if.bus_rd_data;
                        
                        if (bus_if.bus_err) begin
                            axi_rresp <= RESP_SLVERR;
                        end else begin
                            axi_rresp <= RESP_OKAY;
                        end
                        
                        if (S_AXI_RREADY) begin
                            // Master is ready, complete transaction
                            read_state <= READ_IDLE;
                            axi_rvalid <= 1'b0;
                        end
                    end
                end
            endcase
        end
    end
    
    //==========================================================================
    // Bus Interface Outputs
    //==========================================================================
    always_comb begin
        // Write transaction
        bus_if.bus_req = (write_state == WRITE_DATA) || 
                        (read_state == READ_DATA && axi_arready);
        
        bus_if.bus_req_is_wr = (write_state == WRITE_DATA);
        
        if (write_state == WRITE_DATA) begin
            bus_if.bus_addr     = axi_awaddr;
            bus_if.bus_wr_data  = S_AXI_WDATA;
            bus_if.bus_wr_strobe = S_AXI_WSTRB;
        end else begin
            bus_if.bus_addr     = axi_araddr;
            bus_if.bus_wr_data  = '0;
            bus_if.bus_wr_strobe = '0;
        end
    end

endmodule