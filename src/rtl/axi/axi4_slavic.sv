module axi4lite_slave #(
    parameter integer DATA_WIDTH = 32,
    parameter integer ADDR_WIDTH = 32
)(
    input logic clk,
    input logic rst_n,
    axi4_lite.slave_ports SAXI;
);



endmodule