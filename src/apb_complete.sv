module apb4_csr_top (
    input wire clk,
    input wire rst,
    
    // APB4 Interface
    apb4_intf.slave s_apb,
);

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    localparam ADDR_WIDTH = 3;
    localparam DATA_WIDTH = 32;

    //--------------------------------------------------------------------------
    // Signals between APB slave and CSR module
    //--------------------------------------------------------------------------
    bus_interface #(
        .P_DATA_WIDTH(P_DATA_WIDTH),
        .P_DMEM_ADDR_WIDTH(P_DMEM_ADDR_WIDTH)
    ) apb4_intf(clk, reset);

    CSR_IP_Map__in_t  hwif_in,
    CSR_IP_Map__out_t hwif_out

    //--------------------------------------------------------------------------
    // APB4 Slave Instance
    //--------------------------------------------------------------------------
    apb4_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_apb4_slave (
        
        .s_apb            (s_apb),
        .bus_interface    (apb4_intf.BUS)
    );


    //--------------------------------------------------------------------------
    // CSR_IP_Map Instance
    //--------------------------------------------------------------------------
    CSR_IP_Map u_csr_ip_map (
        .bus_interface    (apb4_intf.REG_MAP)
        
        // Hardware interface (pass-through)
        .hwif_in         (hwif_in),
        .hwif_out        (hwif_out)
    );

endmodule