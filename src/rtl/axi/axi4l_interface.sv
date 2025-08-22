// AXI4-Lite Bus Interface
interface axi4l_interface
#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)
(input logic clk, reset);

    // Signals between AXI4-Lite slave and register module
    logic bus_req;
    logic bus_req_is_wr;
    logic [ADDR_WIDTH-1:0] bus_addr;
    logic [DATA_WIDTH-1:0] bus_wr_data;
    logic [(DATA_WIDTH/8)-1:0] bus_wr_strobe;  // Byte enable strobes
    logic bus_ready;
    logic bus_err;
    logic [DATA_WIDTH-1:0] bus_rd_data;
    

    // modport declaration for AXI4-Lite slave (bus master side)
    modport AXI_SLAVE (
        input clk,
        input reset,
        
        // Register interface inputs
        input bus_ready,
        input bus_err, 
        input bus_rd_data,
        
        // Register interface outputs
        output bus_req,
        output bus_req_is_wr,
        output bus_addr,
        output bus_wr_data,
        output bus_wr_strobe
    );
    
    ////////////////////////////////////////////////////////////////////////////
    // modport declaration for Register map (bus slave side)
    //////////////////////////////////////////////////////////////////////////// 
    modport REG_MAP (
        input clk,
        input reset,
        
        // Bus interface inputs
        input bus_req,
        input bus_req_is_wr,
        input bus_addr,
        input bus_wr_data,
        input bus_wr_strobe,
        
        // Bus interface outputs
        output bus_ready,
        output bus_rd_data,
        output bus_err
    );
    
endinterface