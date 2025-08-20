module {{MODULE_NAME}} (
        input wire clk,
        input wire rst,

        apb4_intf.slave s_apb,

        // Hardware Interface
        input {{PACKAGE_NAME}}::{{MODULE_NAME}}__in_t hwif_in,
        output {{PACKAGE_NAME}}::{{MODULE_NAME}}__out_t hwif_out
    );

    //--------------------------------------------------------------------------
    // CPU Bus interface logic
    //--------------------------------------------------------------------------
    logic cpuif_req;
    logic cpuif_req_is_wr;
    logic [{{ADDR_WIDTH-1}}:0] cpuif_addr;
    logic [{{DATA_WIDTH-1}}:0] cpuif_wr_data;
    logic [{{DATA_WIDTH-1}}:0] cpuif_wr_biten;
    logic cpuif_req_stall_wr;
    logic cpuif_req_stall_rd;

    logic cpuif_rd_ack;
    logic cpuif_rd_err;
    logic [{{DATA_WIDTH-1}}:0] cpuif_rd_data;

    logic cpuif_wr_ack;
    logic cpuif_wr_err;

    //--------------------------------------------------------------------------
    // Assertions for Interface Validation
    //--------------------------------------------------------------------------
    `ifndef SYNTHESIS
        initial begin
            assert_bad_addr_width: assert($bits(s_apb_paddr) >= {{PACKAGE_NAME}}::{{MIN_ADDR_WIDTH_PARAM}})
                else $error("Interface address width of %0d is too small. Shall be at least %0d bits", $bits(s_apb_paddr), {{PACKAGE_NAME}}::{{MIN_ADDR_WIDTH_PARAM}});
            assert_bad_data_width: assert($bits(s_apb_pwdata) == {{PACKAGE_NAME}}::{{DATA_WIDTH_PARAM}})
                else $error("Interface data width of %0d is incorrect. Shall be %0d bits", $bits(s_apb_pwdata), {{PACKAGE_NAME}}::{{DATA_WIDTH_PARAM}});
        end
    `endif

    // Request handling state machine
    logic is_active;
    always_ff @(posedge clk) begin
        if(rst) begin
            is_active <= '0;
            cpuif_req <= '0;
            cpuif_req_is_wr <= '0;
            cpuif_addr <= '0;
            cpuif_wr_data <= '0;
            cpuif_wr_biten <= '0;
        end else begin
            if(~is_active) begin
                if(s_apb_psel) begin
                    is_active <= '1;
                    cpuif_req <= '1;
                    cpuif_req_is_wr <= s_apb_pwrite;
                    cpuif_addr <= s_apb_paddr[{{ADDR_WIDTH-1}}:0];
                    cpuif_wr_data <= s_apb_pwdata;
                    for(int i=0; i<1; i++) begin
                        cpuif_wr_biten[i*8 +: 8] <= {8{s_apb.PSTRB[i]}};
                    end
                end
            end else begin
                cpuif_req <= '0;
                if(cpuif_rd_ack || cpuif_wr_ack) begin
                    is_active <= '0;
                end
            end
        end
    end

    // APB4 Response signals
    assign s_apb_pready = cpuif_rd_ack | cpuif_wr_ack;
    assign s_apb_prdata = cpuif_rd_data;
    assign s_apb_pslverr = cpuif_rd_err | cpuif_wr_err;

    logic cpuif_req_masked;

    // Read & write latencies are balanced. Stalls not required
    assign cpuif_req_stall_rd = '0;
    assign cpuif_req_stall_wr = '0;
    assign cpuif_req_masked = cpuif_req
                            & !(!cpuif_req_is_wr & cpuif_req_stall_rd)
                            & !(cpuif_req_is_wr & cpuif_req_stall_wr);

    //--------------------------------------------------------------------------
    // Address Decode
    //--------------------------------------------------------------------------
    typedef struct {
        {{REGISTER_DECODE_STRUCT}}
    } decoded_reg_strb_t;
    
    decoded_reg_strb_t decoded_reg_strb;
    logic decoded_req;
    logic decoded_req_is_wr;
    logic [{{DATA_WIDTH-1}}:0] decoded_wr_data;
    logic [{{DATA_WIDTH-1}}:0] decoded_wr_biten;

    always_comb begin
        {{REGISTER_DECODE_LOGIC}}
    end

    // Pass down signals to next stage
    assign decoded_req = cpuif_req_masked;
    assign decoded_req_is_wr = cpuif_req_is_wr;
    assign decoded_wr_data = cpuif_wr_data;
    assign decoded_wr_biten = cpuif_wr_biten;

    //--------------------------------------------------------------------------
    // Register Field Storage
    //--------------------------------------------------------------------------
    {{FIELD_STORAGE_DECLARATION}}

    //--------------------------------------------------------------------------
    // Register Field Logic
    //--------------------------------------------------------------------------
    {{REGISTER_LOGIC}}

    //--------------------------------------------------------------------------
    // Hardware Interface Assignments
    //--------------------------------------------------------------------------
    {{HWIF_ASSIGNMENTS}}

    //--------------------------------------------------------------------------
    // Write response
    //--------------------------------------------------------------------------
    assign cpuif_wr_ack = decoded_req & decoded_req_is_wr;
    // Writes are always granted with no error response
    assign cpuif_wr_err = '0;

    //--------------------------------------------------------------------------
    // Readback Logic
    //--------------------------------------------------------------------------
    logic readback_err;
    logic readback_done;
    logic [{{DATA_WIDTH-1}}:0] readback_data;

    // Assign readback values to a flattened array
    logic [{{DATA_WIDTH-1}}:0] readback_array[{{NUM_REGISTERS}}];
    
    {{READBACK_ASSIGNMENTS}}

    // Reduce the array
    always_comb begin
        automatic logic [{{DATA_WIDTH-1}}:0] readback_data_var;
        readback_done = decoded_req & ~decoded_req_is_wr;
        readback_err = '0;
        readback_data_var = '0;
        for(int i=0; i<{{NUM_REGISTERS}}; i++) readback_data_var |= readback_array[i];
        readback_data = readback_data_var;
    end

    assign cpuif_rd_ack = readback_done;
    assign cpuif_rd_data = readback_data;
    assign cpuif_rd_err = readback_err;

endmodule