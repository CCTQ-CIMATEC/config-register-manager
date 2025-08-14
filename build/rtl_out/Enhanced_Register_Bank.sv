// Módulo Enhanced_Register_Bank - Gerado automaticamente em 2025-08-14 14:27:23
// Interface APB com registros para UART e PWM

`timescale 1ns/1ps

module Enhanced_Register_Bank (
    // Interface APB
    input logic          PCLK,
    input logic          PRESETn,
    input logic          PSEL,
    input logic          PENABLE,
    input logic [31:0]   PADDR,
    input logic          PWRITE,
    input logic [31:0]   PWDATA,
    output logic [31:0]  PRDATA,
    output logic         PREADY,
    output logic         PSLVERR,

    // Sinais externos
    input logic pwm_duty,
    input logic pwm_period,
    input logic uart_baud_div,
    output logic uart_rx_empty,
    input logic uart_rx_enable,
    input logic uart_tx_enable,
    output logic uart_tx_full
);

    // Decodificador de endereços
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PRDATA <= 32'h0;
            PREADY <= 1'b0;
        end
        else if (PSEL && !PENABLE) begin
            PREADY <= 1'b1;
            if (PADDR == 32'h0x4000000) begin
                if (PWRITE) begin
                    uart_tx_enable <= PWDATA[0:0];
                    uart_rx_enable <= PWDATA[1:1];
                    uart_baud_div <= PWDATA[15:8];
                end else begin
                    PRDATA <= '0;
                    PRDATA[0:0] <= uart_tx_enable;
                    PRDATA[1:1] <= uart_rx_enable;
                    PRDATA[15:8] <= uart_baud_div;
                end
            end
            if (PADDR == 32'h0x4000004) begin
                PRDATA <= '0;
                PRDATA[0:0] <= uart_tx_full;
                PRDATA[1:1] <= uart_rx_empty;
            end
            if (PADDR == 32'h0x4000100) begin
                if (PWRITE) begin
                    pwm_period <= PWDATA[31:0];
                end else begin
                    PRDATA <= '0;
                    PRDATA[31:0] <= pwm_period;
                end
            end
            if (PADDR == 32'h0x4000104) begin
                if (PWRITE) begin
                    pwm_duty <= PWDATA[31:0];
                end else begin
                    PRDATA <= '0;
                    PRDATA[31:0] <= pwm_duty;
                end
            end
        end else begin
            PREADY <= 1'b0;
        end
    end

    assign PSLVERR = 1'b0;  // Sem erros
endmodule
