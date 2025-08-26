interface axi4_lite #(
    parameter DATA_WIDTH = 31,
    parameter ADDR_WIDTH = 31
) (
    input logic ACLK,
    input logic ARESETN
);
    
    // Read Address Channel - AR
    logic [ADDR_WIDTH:0]    ARADDR;
    logic [3:0]             ARCACHE;
    logic [2:0]             ARPROT;
    logic                   ARVALID;
    logic                   ARREADY;

    //Read Data Channel - R
    logic [DATA_WIDTH:0]    RDATA;
    logic                   RRESP;
    logic                   RVALID;
    logic                   RREADY;

    //Write Address Channel - AW
    logic [ADDR_WIDTH:0]    AWADDR;
    logic [3:0]             AWCACHE;
    logic [2:0]             AWPROT;
    logic                   AWVALID;
    logic                   AWREADY;

    //Write Data Channel - W
    logic [DATA_WIDTH]      WDATA;
    logic [3:0]             WSTRB;

    //Write Response Channel - B
    logic                   BRESP;
    logic                   BVALID;
    logic                   BREADY;

    modport master_ports (
        input ACLK, ARESETN,
        input ARREADY, RDATA, RRESP,
        input RVALID, AWREADY, BRESP,
        input BVALID,
        output ARADDR, ARCACHE, ARPROT, ARVALID,
        output RREADY, AWADDR, AWCACHE, AWPROT,
        output AWVALID, WDATA, WSTRB, BREADY
    );

    modport slave_ports (
        input ACLK, ARESETN,
        input ARADDR, ARCACHE, ARPROT, ARVALID,
        input RREADY, AWADDR, AWCACHE, AWPROT,
        input AWVALID, WDATA, WSTRB, BREADY
        output ARREADY, RDATA, RRESP,
        output RVALID, AWREADY, BRESP,
        output BVALID
    );


endinterface //axi4_lite