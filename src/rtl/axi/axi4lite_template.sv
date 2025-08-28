module axilite_slave #(
    parameter logic DATA_WIDTH = 32,
    parameter logic ADDR_WIDTH = 32,
    parameter logic MEM_DEPTH = 32  // Not used anymore, but kept for compatibility
)(
    Bus2Reg_intf.BUS intf,          // This module is the BUS master
    Bus2Master_intf SAXI            // This module is the AXI slave
);
    
    // Internal registers for address phases
    logic [ADDR_WIDTH-1:0] read_addr;
    logic [ADDR_WIDTH-1:0] write_addr;
    logic [DATA_WIDTH-1:0] write_data;
    logic [3:0] write_strobe;
    
    // State machines for read and write channels
    typedef enum logic [1:0] {
        READ_IDLE,
        READ_WAIT_REGMAP,
        READ_DATA
    } read_state_t;
    
    typedef enum logic [2:0] {
        WRITE_IDLE,
        WRITE_WAIT_REGMAP,
        WRITE_RESP
    } write_state_t;
    
    read_state_t read_state, read_state_next;
    write_state_t write_state, write_state_next;
    
    // Convert byte strobes to bit enables
    function automatic logic [DATA_WIDTH-1:0] strb_to_biten(logic [3:0] strb);
        logic [DATA_WIDTH-1:0] biten = '0;
        for (int i = 0; i < 4; i++) begin
            if (strb[i]) begin
                biten[i*8 +: 8] = 8'hFF;  // Set all bits in the byte
            end
        end
        return biten;
    endfunction
    
    // Sequential logic
    always_ff @(posedge SAXI.ACLK or negedge SAXI.ARESETN) begin
        if (!SAXI.ARESETN) begin
            read_state <= READ_IDLE;
            write_state <= WRITE_IDLE;
            read_addr <= '0;
            write_addr <= '0;
            write_data <= '0;
            write_strobe <= '0;
        end else begin
            read_state <= read_state_next;
            write_state <= write_state_next;
            
            // Capture read address
            if (SAXI.ARVALID && SAXI.ARREADY) begin
                read_addr <= SAXI.ARADDR;
            end
            
            // Capture write address and data
            if (SAXI.AWVALID && SAXI.AWREADY) begin
                write_addr <= SAXI.AWADDR;
            end
            if (SAXI.WVALID && SAXI.WREADY) begin
                write_data <= SAXI.WDATA;
                write_strobe <= SAXI.WSTRB;
            end
        end
    end
    
    // Read channel state machine
    always_comb begin
        read_state_next = read_state;
        
        case (read_state)
            READ_IDLE: begin
                if (SAXI.ARVALID && SAXI.ARREADY) begin
                    read_state_next = READ_WAIT_REGMAP;
                end
            end
            
            READ_WAIT_REGMAP: begin
                if (intf.bus_ready) begin
                    read_state_next = READ_DATA;
                end
            end
            
            READ_DATA: begin
                if (SAXI.RVALID && SAXI.RREADY) begin
                    read_state_next = READ_IDLE;
                end
            end
        endcase
    end
    
    // Write channel state machine
    always_comb begin
        write_state_next = write_state;
        
        case (write_state)
            WRITE_IDLE: begin
                if (SAXI.AWVALID && SAXI.AWREADY && SAXI.WVALID && SAXI.WREADY) begin
                    write_state_next = WRITE_WAIT_REGMAP;
                end
            end
            
            WRITE_WAIT_REGMAP: begin
                if (intf.bus_ready) begin
                    write_state_next = WRITE_RESP;
                end
            end
            
            WRITE_RESP: begin
                if (SAXI.BVALID && SAXI.BREADY) begin
                    write_state_next = WRITE_IDLE;
                end
            end
        endcase
    end
    
    // Bus2Reg interface outputs (we are the BUS master)
    assign intf.bus_req = (read_state == READ_WAIT_REGMAP) || (write_state == WRITE_WAIT_REGMAP);
    assign intf.bus_req_is_wr = (write_state == WRITE_WAIT_REGMAP);
    
    always_comb begin
        if (write_state == WRITE_WAIT_REGMAP) begin
            intf.bus_addr = write_addr;
        end else begin
            intf.bus_addr = read_addr;
        end
    end
    
    assign intf.bus_wr_data = write_data;
    assign intf.bus_wr_biten = strb_to_biten(write_strobe);
    
    // Stall signals - for now, never stall (you might need these later for flow control)
    assign intf.bus_req_stall_wr = 1'b0;
    assign intf.bus_req_stall_rd = 1'b0;
    
    // AXI4-Lite signal assignments
    
    // Read Address Channel
    assign SAXI.ARREADY = (read_state == READ_IDLE);
    
    // Read Data Channel  
    assign SAXI.RDATA = intf.bus_rd_data;
    assign SAXI.RRESP = 2'b00;  // Always OKAY for now (regmap should handle errors)
    assign SAXI.RVALID = (read_state == READ_DATA);
    
    // Write Address Channel
    assign SAXI.AWREADY = (write_state == WRITE_IDLE);
    
    // Write Data Channel
    assign SAXI.WREADY = (write_state == WRITE_IDLE);
    
    // Write Response Channel
    assign SAXI.BRESP = 2'b00;  // Always OKAY for now (regmap should handle errors)
    assign SAXI.BVALID = (write_state == WRITE_RESP);

endmodule