module axi4lite_csr_top #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    
    // AXI4-Lite Interface
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input wire [3:0]                    S_AXI_AWCACHE,
    input wire [2:0]                    S_AXI_AWPROT,
    input wire                          S_AXI_AWVALID,
    output wire                         S_AXI_AWREADY,
    
    input wire [C_S_AXI_DATA_WIDTH-1:0]     S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input wire                               S_AXI_WVALID,
    output wire                              S_AXI_WREADY,
    
    output wire [1:0] S_AXI_BRESP,
    output wire       S_AXI_BVALID,
    input wire        S_AXI_BREADY,
    
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input wire [3:0]                    S_AXI_ARCACHE,
    input wire [2:0]                    S_AXI_ARPROT,
    input wire                          S_AXI_ARVALID,
    output wire                         S_AXI_ARREADY,
    
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0]                    S_AXI_RRESP,
    output wire                          S_AXI_RVALID,
    input wire                           S_AXI_RREADY,
    
    // Hardware Interface (pass-through to your CSR module)
    input  CSR_IP_Map__in_t  hwif_in,
    output CSR_IP_Map__out_t hwif_out
);

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    localparam ADDR_WIDTH = C_S_AXI_ADDR_WIDTH;
    localparam DATA_WIDTH = C_S_AXI_DATA_WIDTH;
    
    //--------------------------------------------------------------------------
    // Bus Interface Instance
    //--------------------------------------------------------------------------
    axi4lite_bus_interface #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) axi4lite_intf (
        .clk(clk), 
        .reset(rst)
    );
    
    //--------------------------------------------------------------------------
    // AXI4-Lite Slave Instance
    //--------------------------------------------------------------------------
    axi4lite_slave #(
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
    ) u_axi4lite_slave (
        // AXI4-Lite Interface
        .S_AXI_clk      (clk),
        .S_AXI_rst_n    (~rst),
        
        // Write Address Channel
        .S_AXI_AWADDR   (S_AXI_AWADDR),
        .S_AXI_AWCACHE  (S_AXI_AWCACHE),
        .S_AXI_AWPROT   (S_AXI_AWPROT),
        .S_AXI_AWVALID  (S_AXI_AWVALID),
        .S_AXI_AWREADY  (S_AXI_AWREADY),
        
        // Write Data Channel
        .S_AXI_WDATA    (S_AXI_WDATA),
        .S_AXI_WSTRB    (S_AXI_WSTRB),
        .S_AXI_WVALID   (S_AXI_WVALID),
        .S_AXI_WREADY   (S_AXI_WREADY),
        
        // Write Response Channel
        .S_AXI_BRESP    (S_AXI_BRESP),
        .S_AXI_BVALID   (S_AXI_BVALID),
        .S_AXI_BREADY   (S_AXI_BREADY),
        
        // Read Address Channel
        .S_AXI_ARADDR   (S_AXI_ARADDR),
        .S_AXI_ARCACHE  (S_AXI_ARCACHE),
        .S_AXI_ARPROT   (S_AXI_ARPROT),
        .S_AXI_ARVALID  (S_AXI_ARVALID),
        .S_AXI_ARREADY  (S_AXI_ARREADY),
        
        // Read Data Channel
        .S_AXI_RDATA    (S_AXI_RDATA),
        .S_AXI_RRESP    (S_AXI_RRESP),
        .S_AXI_RVALID   (S_AXI_RVALID),
        .S_AXI_RREADY   (S_AXI_RREADY),
        
        // Bus Interface Connection
        .bus_if         (axi4lite_intf.AXI_SLAVE)
    );
    
    //--------------------------------------------------------------------------
    // CSR_IP_Map Instance (Your register map module)
    //--------------------------------------------------------------------------
    CSR_IP_Map u_csr_ip_map (
        // Bus Interface Connection
        .bus_interface  (axi4lite_intf.REG_MAP),
        
        // Hardware interface (pass-through)
        .hwif_in        (hwif_in),
        .hwif_out       (hwif_out)
    );

endmodule