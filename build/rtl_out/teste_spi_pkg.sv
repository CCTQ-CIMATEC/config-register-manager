// Package teste_spi_pkg - Gerado automaticamente em 2025-08-14 15:24:20
// Estruturas typedef para interface CSR

package teste_spi_pkg;

    // Input structures (Hardware -> Register)
    typedef struct {
        logic next;
        logic we;
    } teste_spi__CTRL__MASTER__in_t;

    typedef struct {
        logic next;
        logic we;
    } teste_spi__STATUS__WRCOL__in_t;

    typedef struct {
        logic next;
        logic we;
    } teste_spi__STATUS__IF__in_t;

    typedef struct {
        logic [7:0] next;
        logic we;
    } teste_spi__DATA__RDATA__in_t;

    typedef struct {
        teste_spi__CTRL__MASTER__in_t MASTER;
    } teste_spi__CTRL__in_t;

    typedef struct {
        teste_spi__STATUS__WRCOL__in_t WRCOL;
        teste_spi__STATUS__IF__in_t IF;
    } teste_spi__STATUS__in_t;

    typedef struct {
        teste_spi__DATA__RDATA__in_t RDATA;
    } teste_spi__DATA__in_t;

    typedef struct {
        teste_spi__CTRL__in_t CTRL;
        teste_spi__STATUS__in_t STATUS;
        teste_spi__DATA__in_t DATA;
    } teste_spi__in_t;

    // Output structures (Register -> Hardware)
    typedef struct {
        logic [1:0] value;
    } teste_spi__CTRL__PRESCALER__out_t;

    typedef struct {
        logic [1:0] value;
    } teste_spi__CTRL__MODE__out_t;

    typedef struct {
        logic value;
    } teste_spi__CTRL__MASTER__out_t;

    typedef struct {
        logic value;
    } teste_spi__CTRL__DORD__out_t;

    typedef struct {
        logic value;
    } teste_spi__CTRL__ENABLE__out_t;

    typedef struct {
        logic value;
    } teste_spi__CTRL__CLK2X__out_t;

    typedef struct {
        logic [1:0] value;
    } teste_spi__INTCTRL__INTLVL__out_t;

    typedef struct {
        logic value;
    } teste_spi__STATUS__WRCOL__out_t;

    typedef struct {
        logic value;
    } teste_spi__STATUS__IF__out_t;

    typedef struct {
        logic [7:0] value;
    } teste_spi__DATA__RDATA__out_t;

    typedef struct {
        teste_spi__CTRL__PRESCALER__out_t PRESCALER;
        teste_spi__CTRL__MODE__out_t MODE;
        teste_spi__CTRL__MASTER__out_t MASTER;
        teste_spi__CTRL__DORD__out_t DORD;
        teste_spi__CTRL__ENABLE__out_t ENABLE;
        teste_spi__CTRL__CLK2X__out_t CLK2X;
    } teste_spi__CTRL__out_t;

    typedef struct {
        teste_spi__INTCTRL__INTLVL__out_t INTLVL;
    } teste_spi__INTCTRL__out_t;

    typedef struct {
        teste_spi__STATUS__WRCOL__out_t WRCOL;
        teste_spi__STATUS__IF__out_t IF;
    } teste_spi__STATUS__out_t;

    typedef struct {
        teste_spi__DATA__RDATA__out_t RDATA;
    } teste_spi__DATA__out_t;

    typedef struct {
        teste_spi__CTRL__out_t CTRL;
        teste_spi__INTCTRL__out_t INTCTRL;
        teste_spi__STATUS__out_t STATUS;
        teste_spi__DATA__out_t DATA;
    } teste_spi__out_t;

endpackage
