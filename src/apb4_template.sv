module apb4_slave #(
    parameter ADDR_WIDTH = 3,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input apb4_intf.slave s_apb,

    // CPU Interface outputs
    output logic                    cpuif_req,
    output logic                    cpuif_req_is_wr,
    output logic [ADDR_WIDTH-1:0]   cpuif_addr,
    output logic [DATA_WIDTH-1:0]   cpuif_wr_data,
    output logic [DATA_WIDTH-1:0]   cpuif_wr_biten,
    output logic                    cpuif_req_stall_wr,
    output logic                    cpuif_req_stall_rd,

    // CPU Interface inputs
    input  logic                    cpuif_rd_ack,
    input  logic                    cpuif_rd_err,
    input  logic [DATA_WIDTH-1:0]   cpuif_rd_data,
    input  logic                    cpuif_wr_ack,
    input  logic                    cpuif_wr_err
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
            cpuif_req        <= 1'b0;
            cpuif_req_is_wr  <= 1'b0;
            cpuif_addr       <= '0;
            cpuif_wr_data    <= '0;
            cpuif_wr_biten   <= '0;
        end else begin
            // Store previous psel for edge detection
            psel_prev <= s_apb.psel;

            if (!is_active) begin
                // Detect rising edge of psel to start new transaction
                if (s_apb.psel && !psel_prev) begin
                    is_active           <= 1'b1;
                    cpuif_req           <= 1'b1;
                    cpuif_req_is_wr     <= s_apb.pwrite;
                    cpuif_addr          <= s_apb.paddr[ADDR_WIDTH-1:0];
                    cpuif_wr_data       <= s_apb.pwdata;
                    cpuif_wr_biten      <= s_apb.pstrb;
                end else begin
                    cpuif_req <= 1'b0;
                end
            end else begin
                // Clear request after one cycle
                cpuif_req <= 1'b0;
                
                // End transaction when response is received
                if (cpuif_rd_ack || cpuif_wr_ack) begin
                    is_active <= 1'b0;
                end
            end
        end
    end

    //--------------------------------------------------------------------------
    // APB4 Response Signals
    //--------------------------------------------------------------------------
    assign s_apb.pready  = cpuif_rd_ack | cpuif_wr_ack;
    assign s_apb.prdata  = cpuif_rd_data;
    assign s_apb.pslverr = cpuif_rd_err | cpuif_wr_err;

    //--------------------------------------------------------------------------
    // Stall signals (not used in this implementation)
    //--------------------------------------------------------------------------
    assign cpuif_req_stall_wr = 1'b0;
    assign cpuif_req_stall_rd = 1'b0;

endmodule