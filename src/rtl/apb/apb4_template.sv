module apb4_slave #(
    parameter ADDR_WIDTH = 3,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input apb4_intf.slave s_apb,

    // BUS Interface inputs
    input  logic                    i_bus_rd_ack,
    input  logic                    i_bus_rd_err,
    input  logic [DATA_WIDTH-1:0]   i_bus_rd_data,
    input  logic                    i_bus_wr_ack,
    input  logic                    i_bus_wr_err,

    // BUS Interface outputs
    output logic                    o_bus_req,
    output logic                    o_bus_req_is_wr,
    output logic [ADDR_WIDTH-1:0]   o_bus_addr,
    output logic [DATA_WIDTH-1:0]   o_bus_wr_data,
    output logic [DATA_WIDTH-1:0]   o_bus_wr_biten,
    output logic                    o_bus_req_stall_wr,
    output logic                    o_bus_req_stall_rd

    
);

    //--------------------------------------------------------------------------
    // Internal signals
    //--------------------------------------------------------------------------
    logic is_active;
    logic psel_prev;

    //--------------------------------------------------------------------------
    // APB4 Request Detection
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            is_active        <= 1'b0;
            psel_prev        <= 1'b0;
            o_bus_req        <= 1'b0;
            o_bus_req_is_wr  <= 1'b0;
            o_bus_addr       <= '0;
            o_bus_wr_data    <= '0;
            o_bus_wr_biten   <= '0;
        end else begin
            // Store previous psel for edge detection
            psel_prev <= s_apb.psel;

            if (!is_active) begin
                // Detect rising edge of psel to start new transaction
                if (s_apb.psel && !psel_prev) begin
                    is_active           <= 1'b1;
                    o_bus_req           <= 1'b1;
                    o_bus_req_is_wr     <= s_apb.pwrite;
                    o_bus_addr          <= s_apb.paddr[ADDR_WIDTH-1:0];
                    o_bus_wr_data       <= s_apb.pwdata;
                    o_bus_wr_biten      <= s_apb.pstrb;
                end else begin
                    o_bus_req <= 1'b0;
                end
            end else begin
                // Clear request after one cycle
                o_bus_req <= 1'b0;
                
                // End transaction when response is received
                if (i_bus_rd_ack || i_bus_wr_ack) begin
                    is_active <= 1'b0;
                end
            end
        end
    end

    //--------------------------------------------------------------------------
    // APB4 Response Signals
    //--------------------------------------------------------------------------
    assign s_apb.pready  = i_bus_rd_ack | i_bus_wr_ack;
    assign s_apb.prdata  = i_bus_rd_data;
    assign s_apb.pslverr = i_bus_rd_err | i_bus_wr_err;

    //--------------------------------------------------------------------------
    // Stall signals (not used in this implementation)
    //--------------------------------------------------------------------------
    assign o_bus_req_stall_wr = 1'b0;
    assign o_bus_req_stall_rd = 1'b0;

endmodule