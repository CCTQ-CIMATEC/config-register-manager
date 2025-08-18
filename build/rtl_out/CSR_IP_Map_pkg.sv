// Package CSR_IP_Map_pkg - Gerado automaticamente em 2025-08-18 09:56:22
// Estruturas typedef para interface CSR

package CSR_IP_Map_pkg;

    // Input structures (Hardware -> Register)
    typedef struct {
        logic next;
        logic we;
    } CSR_IP_Map__ctrl2__resetn__in_t;

    typedef struct {
        logic next;
        logic we;
    } CSR_IP_Map__stat2__err__in_t;

    typedef struct {
        logic next;
        logic we;
    } CSR_IP_Map__stat2__ready__in_t;

    typedef struct {
        logic [15:0] next;
        logic we;
    } CSR_IP_Map__data2__out__in_t;

    typedef struct {
        logic next;
        logic we;
    } CSR_IP_Map__ctrl__master__in_t;

    typedef struct {
        logic next;
        logic we;
    } CSR_IP_Map__status__wrcol__in_t;

    typedef struct {
        logic next;
        logic we;
    } CSR_IP_Map__status__if__in_t;

    typedef struct {
        logic [8:0] next;
        logic we;
    } CSR_IP_Map__data__rdata__in_t;

    typedef struct {
        CSR_IP_Map__ctrl2__resetn__in_t resetn;
    } CSR_IP_Map__ctrl2__in_t;

    typedef struct {
        CSR_IP_Map__stat2__err__in_t err;
        CSR_IP_Map__stat2__ready__in_t ready;
    } CSR_IP_Map__stat2__in_t;

    typedef struct {
        CSR_IP_Map__data2__out__in_t out;
    } CSR_IP_Map__data2__in_t;

    typedef struct {
        CSR_IP_Map__ctrl__master__in_t master;
    } CSR_IP_Map__ctrl__in_t;

    typedef struct {
        CSR_IP_Map__status__wrcol__in_t wrcol;
        CSR_IP_Map__status__if__in_t if;
    } CSR_IP_Map__status__in_t;

    typedef struct {
        CSR_IP_Map__data__rdata__in_t rdata;
    } CSR_IP_Map__data__in_t;

    typedef struct {
        CSR_IP_Map__ctrl2__in_t ctrl2;
        CSR_IP_Map__stat2__in_t stat2;
        CSR_IP_Map__data2__in_t data2;
        CSR_IP_Map__ctrl__in_t ctrl;
        CSR_IP_Map__status__in_t status;
        CSR_IP_Map__data__in_t data;
    } CSR_IP_Map__in_t;

    // Output structures (Register -> Hardware)
    typedef struct {
        logic [1:0] value;
    } CSR_IP_Map__ctrl2__mode2__out_t;

    typedef struct {
        logic [1:0] value;
    } CSR_IP_Map__ctrl2__priority__out_t;

    typedef struct {
        logic value;
    } CSR_IP_Map__ctrl2__enable2__out_t;

    typedef struct {
        logic value;
    } CSR_IP_Map__ctrl2__resetn__out_t;

    typedef struct {
        logic [7:0] value;
    } CSR_IP_Map__cfg__clockdiv__out_t;

    typedef struct {
        logic value;
    } CSR_IP_Map__stat2__err__out_t;

    typedef struct {
        logic value;
    } CSR_IP_Map__stat2__ready__out_t;

    typedef struct {
        logic [15:0] value;
    } CSR_IP_Map__data2__out__out_t;

    typedef struct {
        logic [1:0] value;
    } CSR_IP_Map__ctrl__prescaler__out_t;

    typedef struct {
        logic [1:0] value;
    } CSR_IP_Map__ctrl__mode__out_t;

    typedef struct {
        logic value;
    } CSR_IP_Map__ctrl__master__out_t;

    typedef struct {
        logic value;
    } CSR_IP_Map__ctrl__dord__out_t;

    typedef struct {
        logic value;
    } CSR_IP_Map__ctrl__enable__out_t;

    typedef struct {
        logic value;
    } CSR_IP_Map__ctrl__clk2x__out_t;

    typedef struct {
        logic [1:0] value;
    } CSR_IP_Map__intctrl__intlvl__out_t;

    typedef struct {
        logic value;
    } CSR_IP_Map__status__wrcol__out_t;

    typedef struct {
        logic value;
    } CSR_IP_Map__status__if__out_t;

    typedef struct {
        logic [8:0] value;
    } CSR_IP_Map__data__rdata__out_t;

    typedef struct {
        CSR_IP_Map__ctrl2__mode2__out_t mode2;
        CSR_IP_Map__ctrl2__priority__out_t priority;
        CSR_IP_Map__ctrl2__enable2__out_t enable2;
        CSR_IP_Map__ctrl2__resetn__out_t resetn;
    } CSR_IP_Map__ctrl2__out_t;

    typedef struct {
        CSR_IP_Map__cfg__clockdiv__out_t clockdiv;
    } CSR_IP_Map__cfg__out_t;

    typedef struct {
        CSR_IP_Map__stat2__err__out_t err;
        CSR_IP_Map__stat2__ready__out_t ready;
    } CSR_IP_Map__stat2__out_t;

    typedef struct {
        CSR_IP_Map__data2__out__out_t out;
    } CSR_IP_Map__data2__out_t;

    typedef struct {
        CSR_IP_Map__ctrl__prescaler__out_t prescaler;
        CSR_IP_Map__ctrl__mode__out_t mode;
        CSR_IP_Map__ctrl__master__out_t master;
        CSR_IP_Map__ctrl__dord__out_t dord;
        CSR_IP_Map__ctrl__enable__out_t enable;
        CSR_IP_Map__ctrl__clk2x__out_t clk2x;
    } CSR_IP_Map__ctrl__out_t;

    typedef struct {
        CSR_IP_Map__intctrl__intlvl__out_t intlvl;
    } CSR_IP_Map__intctrl__out_t;

    typedef struct {
        CSR_IP_Map__status__wrcol__out_t wrcol;
        CSR_IP_Map__status__if__out_t if;
    } CSR_IP_Map__status__out_t;

    typedef struct {
        CSR_IP_Map__data__rdata__out_t rdata;
    } CSR_IP_Map__data__out_t;

    typedef struct {
        CSR_IP_Map__ctrl2__out_t ctrl2;
        CSR_IP_Map__cfg__out_t cfg;
        CSR_IP_Map__stat2__out_t stat2;
        CSR_IP_Map__data2__out_t data2;
        CSR_IP_Map__ctrl__out_t ctrl;
        CSR_IP_Map__intctrl__out_t intctrl;
        CSR_IP_Map__status__out_t status;
        CSR_IP_Map__data__out_t data;
    } CSR_IP_Map__out_t;

endpackage
