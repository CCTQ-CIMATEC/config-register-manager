module apb4_slave #(
    parameter ADDR_WIDTH = 3,
    parameter DATA_WIDTH = 32
)(
    input  logic clk,
    input  logic rst,
    input  apb4_intf.slave s_apb,
    bus_interface.BUS intf
);

    //---------
    // FSM 
    //---------
    typedef enum logic [1:0] {
        IDLE   = 2'b00,
        SETUP  = 2'b01,
        ACCESS = 2'b10
    } apb_state_t;

    apb_state_t current_state, next_state;

    logic transaction_complete;

    always_comb begin
        case (current_state)
            IDLE: begin
                if (s_apb.psel && !s_apb.penable)
                    next_state = SETUP;
                else
                    next_state = IDLE;
            end
            SETUP: begin
                if (s_apb.psel && s_apb.penable)
                    next_state = ACCESS;
                else if (!s_apb.psel)
                    next_state = IDLE;
                else
                    next_state = SETUP;
            end
            ACCESS: begin
                if (transaction_complete) begin
                    if (s_apb.psel && !s_apb.penable)
                        next_state = SETUP;
                    else
                        next_state = IDLE;
                end else
                    next_state = ACCESS;
            end
            default: next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always_comb begin
        // defaults
        intf.o_bus_req        = 1'b0;
        intf.o_bus_req_is_wr  = 1'b0;
        intf.o_bus_addr       = '0;
        intf.o_bus_wr_data    = '0;
        intf.o_bus_wr_biten   = '0;

        case (current_state)
            ACCESS: begin
                // iniciar transação no access
                if (!intf.o_bus_req) begin
                    intf.o_bus_req       = 1'b1;
                    intf.o_bus_req_is_wr = s_apb.pwrite;
                    intf.o_bus_addr      = s_apb.paddr[ADDR_WIDTH-1:0];
                    intf.o_bus_wr_data   = s_apb.pwdata;
                    intf.o_bus_wr_biten  = s_apb.pstrb;
                end
            end
        endcase
    end

    //--------------------------------------------------------------------------
    // Transaction Completion
    //--------------------------------------------------------------------------
    assign transaction_complete = (intf.bus_ready);

    //--------------------------------------------------------------------------
    // APB Response Signals
    //--------------------------------------------------------------------------
    assign s_apb.pready  = (current_state == ACCESS) ? transaction_complete : 1'b0;
    assign s_apb.prdata  = (current_state == ACCESS) ? intf.bus_rd_data : '0;
    assign s_apb.pslverr = (current_state == ACCESS) ? intf.bus_err : 1'b0;

    //--------------------------------------------------------------------------
    // Stall signals
    //--------------------------------------------------------------------------
    assign intf.bus_req_stall_wr = 1'b0;
    assign intf.bus_req_stall_rd = 1'b0;

endmodule