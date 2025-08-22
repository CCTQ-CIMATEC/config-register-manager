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
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    //--------------------------------------------------------------------------
    // Transaction Logic - só no estado access
    //--------------------------------------------------------------------------
    always_ff @(posedge intf.clk or posedge intf.rst) begin
        if (rst) begin
            intf.o_bus_req        <= 1'b0;
            intf.o_bus_req_is_wr  <= 1'b0;
            intf.o_bus_addr       <= '0;
            intf.o_bus_wr_data    <= '0;
            intf.o_bus_wr_biten   <= '0;
        end else begin
            // doc: transação só inicia no estado access (PSEL=1 AND PENABLE=1)
            if (current_state == ACCESS && next_state == ACCESS && !intf.o_bus_req) begin
                // primeira entrada no access - inicia transação
                intf.o_bus_req        <= 1'b1;
                intf.o_bus_req_is_wr  <= s_apb4.pwrite;
                intf.o_bus_addr       <= s_apb4.paddr[ADDR_WIDTH-1:0];
                intf.o_bus_wr_data    <= s_apb4.pwdata;
                intf.o_bus_wr_biten   <= s_apb4.pstrb;
            end else if (current_state == ACCESS) begin
                // clear request after one cycle
                intf.o_bus_req <= 1'b0;
            end
        end
    end

    //--------------------------------------------------------------------------
    // Transaction Completion Detection
    //--------------------------------------------------------------------------
    assign transaction_complete = (intf.i_bus_rd_ack | intf.i_bus_wr_ack) & s_apb4.pready;

    //--------------------------------------------------------------------------
    // APB4 Response Signals -  doc: só válido no access
    //--------------------------------------------------------------------------
    assign s_apb.pready  = (current_state == ACCESS) ? (i_bus_rd_ack | i_bus_wr_ack) : 1'b0;
    assign s_apb.prdata  = (current_state == ACCESS) ? i_bus_rd_data : '0;
    assign s_apb.pslverr = (current_state == ACCESS) ? (i_bus_rd_err | i_bus_wr_err) : 1'b0;

    //--------------------------------------------------------------------------
    // Stall signals
    //--------------------------------------------------------------------------
    assign o_bus_req_stall_wr = 1'b0;
    assign o_bus_req_stall_rd = 1'b0;

endmodule