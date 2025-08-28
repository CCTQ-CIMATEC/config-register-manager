interface Bus2Reg_intf #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    input logic clk,
    input logic rst_n
);
    
   logic                    bus_req;
   logic                    bus_req_is_wr;
   logic [ADDR_WIDTH-1:0]   bus_addr;
   logic [DATA_WIDTH-1:0]   bus_wr_data;
   logic [DATA_WIDTH-1:0]   bus_wr_biten;
   logic                    bus_req_stall_wr;
   logic                    bus_req_stall_rd;

   logic                    bus_ready;
   logic [DATA_WIDTH-1:0]   bus_rd_data;
   
   modport BUS (
       input  clk,
       input  rst_n,

       input  bus_ready,
       input  bus_rd_data,

       output bus_req,
       output bus_req_is_wr,
       output bus_addr,
       output bus_wr_data,
       output bus_wr_biten,
       output bus_req_stall_wr,
       output bus_req_stall_rd
   );

   modport REG_MAP (
       input  clk,
       input  rst_n,

       input  bus_req,
       input  bus_req_is_wr,
       input  bus_addr,
       input  bus_wr_data,
       input  bus_wr_biten,

       output bus_ready,
       output bus_rd_data
   );


endinterface