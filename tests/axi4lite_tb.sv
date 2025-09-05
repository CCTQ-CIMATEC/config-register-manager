module axi4lite_tb;

    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter CSR_ADDR_WIDTH = 32;
    parameter CLK_PERIOD = 10; // 100 MHz
    parameter MEM_DEPTH = 1024; // Add this parameter for the slave module

    logic clk;
    logic rst_n;
    
    // Hardware Interface
    CSR_IP_Map__in_t  hwif_in;
    CSR_IP_Map__out_t hwif_out;
    
    // Test variables
    logic [DATA_WIDTH-1:0] expected_data;
    logic [DATA_WIDTH-1:0] expected_data_writed;
    logic [ADDR_WIDTH-1:0] test_address;
    logic test_passed;

    // AXI4-Lite Interface instance
    Bus2Master_intf #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) s_axi4_lite (
        .ACLK(clk),
        .ARESETN(rst_n)
    );

    axi4lite_csr_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .CSR_ADDR_WIDTH(CSR_ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst_n),
        
        // APB4 Interface
        .axi4lite2Master_intf(s_axi4_lite.slave),
        
        // Hardware Interface
        .hwif_in(hwif_in),
        .hwif_out(hwif_out)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Reset Generation
    initial begin
        rst_n = 0;
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD);
    end

    // AXI4-Lite Write Task using interface clocking block
    task axi4_lite_write;

        /*
            
        1. The Master places an address on the Write Address channel and the data on the Write Data channel. 
        At the same time, it asserts AWVALID and WVALID, indicating that the address and data on their respective channels are valid. 
        BREADY is also asserted by the Master, indicating that it is ready to receive a response.

        2. The Slave asserts AWREADY and WREADY on the Write Address and Write Data channels, respectively.

        3. Since the Valid and Ready signals are present on both channels (Write Address and Write Data), 
        a handshake occurs on these channels, and the associated Valid and Ready signals can be deasserted. 
        (After both handshakes, the slave already has the write address and data).

        4. The Slave then asserts BVALID, indicating that there is a valid response on the Write Response channel 
        (in this case, the response is 2’b00, which corresponds to ‘OKAY’).

        5. On the next rising clock edge, the transaction is completed, with both Ready and Valid signals high on the Write Response channel.
            
        */

        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        input [(DATA_WIDTH/8)-1:0] strb;
        begin
            // Address Write Channel
            @(s_axi4_lite.master_cb);
            s_axi4_lite.master_cb.AWADDR  <= addr;
            s_axi4_lite.master_cb.AWPROT  <= 3'b000;
            s_axi4_lite.master_cb.AWVALID <= 1'b1;
            
            // Write Data Channel
            s_axi4_lite.master_cb.WDATA   <= data;
            s_axi4_lite.master_cb.WSTRB   <= strb;
            // Write strobes. 4-bit signal indicating which of the 4-bytes of Write Data. Slaves can choose assume all bytes are valid
            s_axi4_lite.master_cb.WVALID  <= 1'b1;
            
            // Write Response Channel
            // BREADY 	M→SM→S 	Response ready. Master generates this signal when it can accept a write response
            s_axi4_lite.master_cb.BREADY  <= 1'b1;
            
            // Wait for address and data handshakes
            // AWREADY - Write address ready. Slave generates this signal when it can accept Write Address and control signals
            // WREADY - 
            while (!(s_axi4_lite.master_cb.AWREADY && s_axi4_lite.master_cb.WREADY)) begin
                @(s_axi4_lite.master_cb);
            end

            // Deassert AWVALID and WVALID after handshake
            @(s_axi4_lite.master_cb);
            s_axi4_lite.master_cb.AWVALID <= 1'b0;
            s_axi4_lite.master_cb.WVALID  <= 1'b0;
            
            // Wait for write response
            while (!s_axi4_lite.master_cb.BVALID) begin
                @(s_axi4_lite.master_cb);
            end
            
            // Check write response
            if (s_axi4_lite.master_cb.BRESP != 2'b00) begin
                $display("[%0t] AXI4-Lite WRITE WARNING: BRESP=0x%h (not OKAY)", $time, s_axi4_lite.master_cb.BRESP);
            end
            
            // End transaction
            @(s_axi4_lite.master_cb);
            s_axi4_lite.master_cb.BREADY <= 1'b0;
            
            $display("[%0t] AXI4-Lite WRITE: Addr=0x%h, Data=0x%h, STRB=0x%h, BRESP=0x%h", 
                     $time, addr, data, strb, s_axi4_lite.master_cb.BRESP);
        end
    endtask

    // AXI4-Lite Read Task using interface clocking block
    task axi4_lite_read;

    /*  
    1. The Master places an address on the Read Address channel and asserts ARVALID, 
       indicating that the address is valid. It also asserts RREADY, indicating that it is ready to receive data from the Slave.

    2. The Slave asserts ARREADY, indicating that it is ready to accept the address on the bus.

    3. Since ARVALID and ARREADY are asserted, a handshake occurs on the next rising clock edge. 
       After that, the Master and Slave deassert ARVALID and ARREADY, respectively. 
       (At this point, the Slave has already received the requested address).

    4. The Slave places the requested data on the Read Data channel and asserts RVALID, 
       indicating that the data on the channel is valid. 
       The Slave may also place a response on RRESP, although this does not occur in this case.

    5. Since RREADY and RVALID are asserted, the next rising clock edge completes the transaction. 
       RREADY and RVALID can then be deasserted.
    */

        input [ADDR_WIDTH-1:0] addr;
        output [DATA_WIDTH-1:0] data;
        output [1:0] resp;
        begin
            // Address Read Channel
            @(s_axi4_lite.master_cb);
            s_axi4_lite.master_cb.ARADDR  <= addr;
            s_axi4_lite.master_cb.ARPROT  <= 3'b000;
            s_axi4_lite.master_cb.ARVALID <= 1'b1;
            s_axi4_lite.master_cb.RREADY  <= 1'b1;
            
            // Wait for address handshake
            while (!s_axi4_lite.master_cb.ARREADY) begin
                @(s_axi4_lite.master_cb);
            end
            
            // Deassert ARVALID after handshake
            @(s_axi4_lite.master_cb);
            s_axi4_lite.master_cb.ARVALID <= 1'b0;
            
            // Wait for read data
            while (!s_axi4_lite.master_cb.RVALID) begin
                @(s_axi4_lite.master_cb);
            end
            
            // Capture data and response
            data = s_axi4_lite.master_cb.RDATA;
            resp = s_axi4_lite.master_cb.RRESP;
            
            // End transaction
            @(s_axi4_lite.master_cb);
            s_axi4_lite.master_cb.RREADY <= 1'b0;
            
            $display("[%0t] AXI4-Lite READ: Addr=0x%h, Data=0x%h, RRESP=0x%h", $time, addr, data, resp);
        end
    endtask

    // Test Sequence
    initial begin
        // Initialize signals
        // hwif_in     <= '0;
        test_passed <= 1;
        
        // Initialize AXI4-Lite interface through modport
        s_axi4_lite.master_cb.ARADDR  <= '0;
        s_axi4_lite.master_cb.ARPROT  <= '0;
        s_axi4_lite.master_cb.ARVALID <= 1'b0;
        s_axi4_lite.master_cb.RREADY  <= 1'b0;
        s_axi4_lite.master_cb.AWADDR  <= '0;
        s_axi4_lite.master_cb.AWPROT  <= '0;
        s_axi4_lite.master_cb.AWVALID <= 1'b0;
        s_axi4_lite.master_cb.WDATA   <= '0;
        s_axi4_lite.master_cb.WSTRB   <= '0;
        s_axi4_lite.master_cb.WVALID  <= 1'b0;
        s_axi4_lite.master_cb.BREADY  <= 1'b0;
        
        // Wait for reset to complete
        wait(rst_n == 1);
        #(CLK_PERIOD * 2);
        
        $display("==========================================");
        $display("Starting AXI4-Lite CSR Top Testbench");
        $display("Using AXI4-Lite Interface with modports");
        $display("==========================================");
        
        // Test 1: Write to a register using clocking block
        $display("\nTest 1: Writing to register address 0x00000000 (Clocking Block)");
        test_address = 32'h40000000;
        expected_data = 32'hEF;
        
        // Perform AXI4-Lite write using clocking block (full word write)
        axi4_lite_write(test_address, expected_data, 4'hF);

        expected_data_writed = pack_ctrl(hwif_out.ctrl);
        if (expected_data_writed === expected_data) begin
            $display("✅ WRITE PASSED: Expected=0x%h, Got=0x%h", expected_data, expected_data_writed);
        end else begin
            $display("❌ WRITE 2 FAILED: Expected=0x%h, Got=0x%h", expected_data, expected_data_writed);
            test_passed = 0;
        end

        $display("Checking hardware interface signals...");
        $display("Expected data written: 0x%h", expected_data);

        // Allow some time for the write to propagate
        //#(CLK_PERIOD * 2);
        
        // Test 2: Read back the same register using clocking block
        $display("\nTest 2: Reading back from register address 0x00000000 (Clocking Block)");
        begin
            logic [DATA_WIDTH-1:0] read_data;
            logic [1:0] read_resp;
            axi4_lite_read(test_address, read_data, read_resp);
            
            if (read_data === expected_data && read_resp === 2'b00) begin
                $display("✅ READBACK PASSED: Expected=0x%h, Got=0x%h, RRESP=0x%h", expected_data, read_data, read_resp);
            end else begin
                $display("❌ READBACK FAILED: Expected=0x%h, Got=0x%h, RRESP=0x%h", expected_data, read_data, read_resp);
                test_passed = 0;
            end
        end
        
        // Summary
        $display("\n==========================================");
        if (test_passed) begin
            $display("✅ ALL TESTS PASSED!");
        end else begin
            $display("❌ SOME TESTS FAILED!");
        end
        $display("==========================================");
        
        #(CLK_PERIOD * 5);
        $finish;
    end

    // Monitoring using interface monitor modport
    initial begin
        $timeformat(-9, 0, " ns", 6);
        forever begin
            @(posedge clk);
            
            // Monitor Read Address Channel
            if (s_axi4_lite.ARVALID && s_axi4_lite.ARREADY) begin
                $display("[%0t] AXI4-Lite AR: ARADDR=0x%h, ARPROT=0x%h", 
                         $time, s_axi4_lite.ARADDR, s_axi4_lite.ARPROT);
            end
            
            // Monitor Read Data Channel
            if (s_axi4_lite.RVALID && s_axi4_lite.RREADY) begin
                $display("[%0t] AXI4-Lite R: RDATA=0x%h, RRESP=0x%h", 
                         $time, s_axi4_lite.RDATA, s_axi4_lite.RRESP);
            end
            
            // Monitor Write Address Channel
            if (s_axi4_lite.AWVALID && s_axi4_lite.AWREADY) begin
                $display("[%0t] AXI4-Lite AW: AWADDR=0x%h, AWPROT=0x%h", 
                         $time, s_axi4_lite.AWADDR, s_axi4_lite.AWPROT);
            end
            
            // Monitor Write Data Channel
            if (s_axi4_lite.WVALID && s_axi4_lite.WREADY) begin
                $display("[%0t] AXI4-Lite W: WDATA=0x%h, WSTRB=0x%h", 
                         $time, s_axi4_lite.WDATA, s_axi4_lite.WSTRB);
            end
            
            // Monitor Write Response Channel
            if (s_axi4_lite.BVALID && s_axi4_lite.BREADY) begin
                $display("[%0t] AXI4-Lite B: BRESP=0x%h", 
                         $time, s_axi4_lite.BRESP);
            end
        end
    end

    // State Monitoring
    /*initial begin
        forever begin
            @(posedge clk);
            if (s_axi4_lite.ARVALID || s_axi4_lite.RVALID || 
                s_axi4_lite.AWVALID || s_axi4_lite.WVALID || s_axi4_lite.BVALID) begin
                $display("[%0t] AXI4-Lite State: Read=%s, Write=%s",
                         $time, s_axi4_lite.get_read_state(), s_axi4_lite.get_write_state());
            end
        end
    end*/

    // Assertion Monitoring
    initial begin
        // Wait for reset to complete
        wait(rst_n == 1);
        $display("AXI4-Lite Protocol Assertions enabled");
    end

    // Simulation Control
    initial begin
        #2000; // Timeout protection
        $display("❌ SIMULATION TIMEOUT");
        $finish;
    end

    function automatic logic [31:0] pack_ctrl(CSR_IP_Map__ctrl__out_t ctrl);
        return { ctrl.clk2x.value,
                ctrl.enable.value,
                ctrl.dord.value,
                ctrl.master.value,
                ctrl.mode.value,
                ctrl.prescaler.value };
    endfunction

    function automatic logic [31:0] pack_data(CSR_IP_Map__data__out_t data);
        return { 
            data.rdata.value,
            8'b0
        };
    endfunction
endmodule