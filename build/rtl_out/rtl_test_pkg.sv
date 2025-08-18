// Package rtl_test_pkg - Gerado automaticamente em 2025-08-18 10:33:03
// Estruturas typedef para interface CSR

package rtl_test_pkg;

    // Input structures (Hardware -> Register)
    typedef struct {
        logic next;
        logic we;
    } rtl_test__CTRL__MASTER__in_t;

    typedef struct {
        logic next;
        logic we;
    } rtl_test__STATUS__WRCOL__in_t;

    typedef struct {
        logic next;
        logic we;
    } rtl_test__STATUS__IF__in_t;

    typedef struct {
        logic [7:0] next;
        logic we;
    } rtl_test__DATA__RDATA__in_t;

    typedef struct {
        rtl_test__CTRL__MASTER__in_t MASTER;
    } rtl_test__CTRL__in_t;

    typedef struct {
        rtl_test__STATUS__WRCOL__in_t WRCOL;
        rtl_test__STATUS__IF__in_t IF;
    } rtl_test__STATUS__in_t;

    typedef struct {
        rtl_test__DATA__RDATA__in_t RDATA;
    } rtl_test__DATA__in_t;

    typedef struct {
        rtl_test__CTRL__in_t CTRL;
        rtl_test__STATUS__in_t STATUS;
        rtl_test__DATA__in_t DATA;
    } rtl_test__in_t;

    // Output structures (Register -> Hardware)
    typedef struct {
        logic [1:0] value;
    } rtl_test__CTRL__PRESCALER__out_t;

    typedef struct {
        logic [1:0] value;
    } rtl_test__CTRL__MODE__out_t;

    typedef struct {
        logic value;
    } rtl_test__CTRL__MASTER__out_t;

    typedef struct {
        logic value;
    } rtl_test__CTRL__DORD__out_t;

    typedef struct {
        logic value;
    } rtl_test__CTRL__ENABLE__out_t;

    typedef struct {
        logic value;
    } rtl_test__CTRL__CLK2X__out_t;

    typedef struct {
        logic [1:0] value;
    } rtl_test__INTCTRL__INTLVL__out_t;

    typedef struct {
        logic value;
    } rtl_test__STATUS__WRCOL__out_t;

    typedef struct {
        logic value;
    } rtl_test__STATUS__IF__out_t;

    typedef struct {
        logic [7:0] value;
    } rtl_test__DATA__RDATA__out_t;

    typedef struct {
        rtl_test__CTRL__PRESCALER__out_t PRESCALER;
        rtl_test__CTRL__MODE__out_t MODE;
        rtl_test__CTRL__MASTER__out_t MASTER;
        rtl_test__CTRL__DORD__out_t DORD;
        rtl_test__CTRL__ENABLE__out_t ENABLE;
        rtl_test__CTRL__CLK2X__out_t CLK2X;
    } rtl_test__CTRL__out_t;

    typedef struct {
        rtl_test__INTCTRL__INTLVL__out_t INTLVL;
    } rtl_test__INTCTRL__out_t;

    typedef struct {
        rtl_test__STATUS__WRCOL__out_t WRCOL;
        rtl_test__STATUS__IF__out_t IF;
    } rtl_test__STATUS__out_t;

    typedef struct {
        rtl_test__DATA__RDATA__out_t RDATA;
    } rtl_test__DATA__out_t;

    typedef struct {
        rtl_test__CTRL__out_t CTRL;
        rtl_test__INTCTRL__out_t INTCTRL;
        rtl_test__STATUS__out_t STATUS;
        rtl_test__DATA__out_t DATA;
    } rtl_test__out_t;

endpackage
