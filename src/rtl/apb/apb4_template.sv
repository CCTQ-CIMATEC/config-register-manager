module apb4_slave #(
    parameter ADDR_WIDTH = 3,
    parameter DATA_WIDTH = 32
)(
    bus_interface intf,
    Bus2Master_intf s_apb4
);

    //--------------------------------------------------------------------------
    // Internal signals
    //--------------------------------------------------------------------------
    logic is_active;
    logic psel_prev;
    logic bus_wr_ack;
    logic bus_rd_ack;
    logic bus_wr_err;
    logic bus_rd_err;

    //--------------------------------------------------------------------------
    // Write Response Assignment
    //--------------------------------------------------------------------------
    // Para writes, assumimos que sempre são completados imediatamente
    assign bus_wr_ack = intf.bus_req & intf.bus_req_is_wr & intf.bus_ready;
    assign bus_rd_ack = intf.bus_req & !intf.bus_req_is_wr & intf.bus_ready;

    assign bus_wr_err = intf.bus_req & intf.bus_req_is_wr & intf.bus_err;
    assign bus_rd_err = intf.bus_req & !intf.bus_req_is_wr & intf.bus_err;

    //--------------------------------------------------------------------------
    // APB4 Request Detection
    //--------------------------------------------------------------------------
    always_ff @(posedge intf.clk or posedge intf.rst) begin
        if (intf.rst) begin
            is_active        <= 1'b0;
            psel_prev        <= 1'b0;
            intf.bus_req        <= 1'b0;
            intf.bus_req_is_wr  <= 1'b0;
            intf.bus_addr       <= '0;
            intf.bus_wr_data    <= '0;
            intf.bus_wr_biten   <= '0;
        end else begin
            // Store previous psel for edge detection
            psel_prev <= s_apb4.psel;

            if (!is_active) begin
                // Detect rising edge of psel to start new transaction
                if (s_apb4.psel && !psel_prev) begin
                    is_active           <= 1'b1;
                    intf.bus_req           <= 1'b1;
                    intf.bus_req_is_wr     <= s_apb4.pwrite;
                    intf.bus_addr          <= s_apb4.paddr[ADDR_WIDTH-1:0];
                    intf.bus_wr_data       <= s_apb4.pwdata;
                    intf.bus_wr_biten      <= s_apb4.pstrb;
                end else begin
                    intf.bus_req <= 1'b0;
                end
            end else begin
                // Clear request after one cycle
                intf.bus_req <= 1'b0;
                
                // End transaction when response is received
                if (bus_rd_ack || bus_wr_ack) begin
                    is_active <= 1'b0;
                end
            end
        end
    end

    //--------------------------------------------------------------------------
    // APB4 Response Signals
    //--------------------------------------------------------------------------
    assign s_apb4.pready  = bus_rd_ack | bus_wr_ack;
    assign s_apb4.prdata  = intf.bus_rd_data;
    assign s_apb4.pslverr = bus_rd_err | bus_wr_err;


    //--------------------------------------------------------------------------
    // Stall signals (not used in this implementation)
    //--------------------------------------------------------------------------
    assign intf.bus_req_stall_wr = 1'b0;
    assign intf.bus_req_stall_rd = 1'b0;

endmodule