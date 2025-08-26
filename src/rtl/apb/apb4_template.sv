module apb4_slave #(
    parameter ADDR_WIDTH = 3,
    parameter DATA_WIDTH = 32
)(
    bus_interface intf,
    Bus2Master_intf s_apb4
);

    //--------------------------------------------------------------------------
    // State Machine, (não sei se é a melhor opção mas achei que seria interessantemanter pela maquina de estado da documnetação)
    //--------------------------------------------------------------------------
    typedef enum logic [1:0] {
        IDLE   = 2'b00,  // PSELx=0, PENABLE=0
        SETUP  = 2'b01,  // PSELx=1, PENABLE=0  
        ACCESS = 2'b10   // PSELx=1, PENABLE=1
    } apb_state_t;
    
    apb_state_t current_state, next_state;
    logic transaction_complete;

    //--------------------------------------------------------------------------
    // Next State Logic (isso esta na doc)
    //--------------------------------------------------------------------------
    always_comb begin
        case (current_state)
            IDLE: begin
                // transição: quando PSEL=1 e PENABLE=0
                if (s_apb.psel && !s_apb.penable) 
                    next_state = SETUP;
                else
                    next_state = IDLE;
            end
            
            SETUP: begin
                // doc: "always moves to the ACCESS state on the next rising edge" achei interessante fazer assim
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
                        next_state = SETUP;  // next tranction
                    else
                        next_state = IDLE;
                end else begin
                    next_state = ACCESS;  // wait states
                end
            end
            
            default: next_state = IDLE;
        endcase
    end

    //--------------------------------------------------------------------------
    // State Register
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
    // Transaction Completion Detection
    //--------------------------------------------------------------------------
    assign transaction_complete = (i_bus_rd_ack | i_bus_wr_ack) & s_apb.pready;

    //--------------------------------------------------------------------------
    // APB4 Response Signals -  doc: só válido no access
    //--------------------------------------------------------------------------
    assign s_apb4.pready  = bus_rd_ack | bus_wr_ack;
    assign s_apb4.prdata  = intf.bus_rd_data;
    assign s_apb4.pslverr = bus_rd_err | bus_wr_err;

    //--------------------------------------------------------------------------
    // Stall signals
    //--------------------------------------------------------------------------
    assign o_bus_req_stall_wr = 1'b0;
    assign o_bus_req_stall_rd = 1'b0;

endmodule