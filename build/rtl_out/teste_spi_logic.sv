// Lógica teste_spi - Gerado automaticamente em 2025-08-14 15:24:20
// Lógica dos registradores CSR

    //--------------------------------------------------------------------------
    // Field logic
    //--------------------------------------------------------------------------
    typedef struct {
        struct {
            struct {
                logic [1:0] next;
                logic load_next;
            } PRESCALER;
            struct {
                logic [1:0] next;
                logic load_next;
            } MODE;
            struct {
                logic next;
                logic load_next;
            } MASTER;
            struct {
                logic next;
                logic load_next;
            } DORD;
            struct {
                logic next;
                logic load_next;
            } ENABLE;
            struct {
                logic next;
                logic load_next;
            } CLK2X;
        } CTRL;
        struct {
            struct {
                logic [1:0] next;
                logic load_next;
            } INTLVL;
        } INTCTRL;
        struct {
            struct {
                logic next;
                logic load_next;
            } WRCOL;
            struct {
                logic next;
                logic load_next;
            } IF;
        } STATUS;
        struct {
            struct {
                logic [7:0] next;
                logic load_next;
            } WDATA;
            struct {
                logic [7:0] next;
                logic load_next;
            } RDATA;
        } DATA;
    } field_combo_t;
    field_combo_t field_combo;

    typedef struct {
        struct {
            struct {
                logic [1:0] value;
            } PRESCALER;
            struct {
                logic [1:0] value;
            } MODE;
            struct {
                logic value;
            } MASTER;
            struct {
                logic value;
            } DORD;
            struct {
                logic value;
            } ENABLE;
            struct {
                logic value;
            } CLK2X;
        } CTRL;
        struct {
            struct {
                logic [1:0] value;
            } INTLVL;
        } INTCTRL;
        struct {
            struct {
                logic value;
            } WRCOL;
            struct {
                logic value;
            } IF;
        } STATUS;
        struct {
            struct {
                logic [7:0] value;
            } WDATA;
            struct {
                logic [7:0] value;
            } RDATA;
        } DATA;
    } field_storage_t;
    field_storage_t field_storage;

    // Field: teste_spi.CTRL.PRESCALER
    always_comb begin
        automatic logic [1:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.CTRL.PRESCALER.value;
        load_next_c = '0;
        if(decoded_reg_strb.CTRL && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.CTRL.PRESCALER.value & ~decoded_wr_biten[1:0]) | (decoded_wr_data[1:0] & decoded_wr_biten[1:0]);
            load_next_c = '1;
        end
        field_combo.CTRL.PRESCALER.next = next_c;
        field_combo.CTRL.PRESCALER.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.CTRL.PRESCALER.value <= 2'h0;
        end else begin
            if(field_combo.CTRL.PRESCALER.load_next) begin
                field_storage.CTRL.PRESCALER.value <= field_combo.CTRL.PRESCALER.next;
            end
        end
    end
    assign hwif_out.CTRL.PRESCALER.value = field_storage.CTRL.PRESCALER.value;

    // Field: teste_spi.CTRL.MODE
    always_comb begin
        automatic logic [1:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.CTRL.MODE.value;
        load_next_c = '0;
        if(decoded_reg_strb.CTRL && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.CTRL.MODE.value & ~decoded_wr_biten[3:2]) | (decoded_wr_data[3:2] & decoded_wr_biten[3:2]);
            load_next_c = '1;
        end
        field_combo.CTRL.MODE.next = next_c;
        field_combo.CTRL.MODE.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.CTRL.MODE.value <= 2'h0;
        end else begin
            if(field_combo.CTRL.MODE.load_next) begin
                field_storage.CTRL.MODE.value <= field_combo.CTRL.MODE.next;
            end
        end
    end
    assign hwif_out.CTRL.MODE.value = field_storage.CTRL.MODE.value;

    // Field: teste_spi.CTRL.MASTER
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.CTRL.MASTER.value;
        load_next_c = '0;
        if(decoded_reg_strb.CTRL && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.CTRL.MASTER.value & ~decoded_wr_biten[4:4]) | (decoded_wr_data[4:4] & decoded_wr_biten[4:4]);
            load_next_c = '1;
        end else if(hwif_in.CTRL.MASTER.we) begin // HW Write - we
            next_c = hwif_in.CTRL.MASTER.next;
            load_next_c = '1;
        end
        field_combo.CTRL.MASTER.next = next_c;
        field_combo.CTRL.MASTER.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.CTRL.MASTER.value <= 1'h0;
        end else begin
            if(field_combo.CTRL.MASTER.load_next) begin
                field_storage.CTRL.MASTER.value <= field_combo.CTRL.MASTER.next;
            end
        end
    end
    assign hwif_out.CTRL.MASTER.value = field_storage.CTRL.MASTER.value;

    // Field: teste_spi.CTRL.DORD
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.CTRL.DORD.value;
        load_next_c = '0;
        if(decoded_reg_strb.CTRL && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.CTRL.DORD.value & ~decoded_wr_biten[5:5]) | (decoded_wr_data[5:5] & decoded_wr_biten[5:5]);
            load_next_c = '1;
        end
        field_combo.CTRL.DORD.next = next_c;
        field_combo.CTRL.DORD.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.CTRL.DORD.value <= 1'h0;
        end else begin
            if(field_combo.CTRL.DORD.load_next) begin
                field_storage.CTRL.DORD.value <= field_combo.CTRL.DORD.next;
            end
        end
    end
    assign hwif_out.CTRL.DORD.value = field_storage.CTRL.DORD.value;

    // Field: teste_spi.CTRL.ENABLE
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.CTRL.ENABLE.value;
        load_next_c = '0;
        if(decoded_reg_strb.CTRL && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.CTRL.ENABLE.value & ~decoded_wr_biten[6:6]) | (decoded_wr_data[6:6] & decoded_wr_biten[6:6]);
            load_next_c = '1;
        end
        field_combo.CTRL.ENABLE.next = next_c;
        field_combo.CTRL.ENABLE.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.CTRL.ENABLE.value <= 1'h0;
        end else begin
            if(field_combo.CTRL.ENABLE.load_next) begin
                field_storage.CTRL.ENABLE.value <= field_combo.CTRL.ENABLE.next;
            end
        end
    end
    assign hwif_out.CTRL.ENABLE.value = field_storage.CTRL.ENABLE.value;

    // Field: teste_spi.CTRL.CLK2X
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.CTRL.CLK2X.value;
        load_next_c = '0;
        if(decoded_reg_strb.CTRL && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.CTRL.CLK2X.value & ~decoded_wr_biten[7:7]) | (decoded_wr_data[7:7] & decoded_wr_biten[7:7]);
            load_next_c = '1;
        end
        field_combo.CTRL.CLK2X.next = next_c;
        field_combo.CTRL.CLK2X.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.CTRL.CLK2X.value <= 1'h0;
        end else begin
            if(field_combo.CTRL.CLK2X.load_next) begin
                field_storage.CTRL.CLK2X.value <= field_combo.CTRL.CLK2X.next;
            end
        end
    end
    assign hwif_out.CTRL.CLK2X.value = field_storage.CTRL.CLK2X.value;

    // Field: teste_spi.INTCTRL.INTLVL
    always_comb begin
        automatic logic [1:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.INTCTRL.INTLVL.value;
        load_next_c = '0;
        if(decoded_reg_strb.INTCTRL && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.INTCTRL.INTLVL.value & ~decoded_wr_biten[1:0]) | (decoded_wr_data[1:0] & decoded_wr_biten[1:0]);
            load_next_c = '1;
        end
        field_combo.INTCTRL.INTLVL.next = next_c;
        field_combo.INTCTRL.INTLVL.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.INTCTRL.INTLVL.value <= 2'h0;
        end else begin
            if(field_combo.INTCTRL.INTLVL.load_next) begin
                field_storage.INTCTRL.INTLVL.value <= field_combo.INTCTRL.INTLVL.next;
            end
        end
    end
    assign hwif_out.INTCTRL.INTLVL.value = field_storage.INTCTRL.INTLVL.value;

    // Field: teste_spi.STATUS.WRCOL
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.STATUS.WRCOL.value;
        load_next_c = '0;
        if(hwif_in.STATUS.WRCOL.we) begin // HW Write - we
            next_c = hwif_in.STATUS.WRCOL.next;
            load_next_c = '1;
        end
        field_combo.STATUS.WRCOL.next = next_c;
        field_combo.STATUS.WRCOL.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.STATUS.WRCOL.value <= 1'h0;
        end else begin
            if(field_combo.STATUS.WRCOL.load_next) begin
                field_storage.STATUS.WRCOL.value <= field_combo.STATUS.WRCOL.next;
            end
        end
    end
    assign hwif_out.STATUS.WRCOL.value = field_storage.STATUS.WRCOL.value;

    // Field: teste_spi.STATUS.IF
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.STATUS.IF.value;
        load_next_c = '0;
        if(hwif_in.STATUS.IF.we) begin // HW Write - we
            next_c = hwif_in.STATUS.IF.next;
            load_next_c = '1;
        end
        field_combo.STATUS.IF.next = next_c;
        field_combo.STATUS.IF.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.STATUS.IF.value <= 1'h0;
        end else begin
            if(field_combo.STATUS.IF.load_next) begin
                field_storage.STATUS.IF.value <= field_combo.STATUS.IF.next;
            end
        end
    end
    assign hwif_out.STATUS.IF.value = field_storage.STATUS.IF.value;

    // Field: teste_spi.DATA.WDATA
    always_comb begin
        automatic logic [7:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.DATA.WDATA.value;
        load_next_c = '0;
        if(decoded_reg_strb.DATA && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.DATA.WDATA.value & ~decoded_wr_biten[7:0]) | (decoded_wr_data[7:0] & decoded_wr_biten[7:0]);
            load_next_c = '1;
        end
        field_combo.DATA.WDATA.next = next_c;
        field_combo.DATA.WDATA.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(field_combo.DATA.WDATA.load_next) begin
            field_storage.DATA.WDATA.value <= field_combo.DATA.WDATA.next;
        end
    end

    // Field: teste_spi.DATA.RDATA
    always_comb begin
        automatic logic [7:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.DATA.RDATA.value;
        load_next_c = '0;
        if(hwif_in.DATA.RDATA.we) begin // HW Write - we
            next_c = hwif_in.DATA.RDATA.next;
            load_next_c = '1;
        end
        field_combo.DATA.RDATA.next = next_c;
        field_combo.DATA.RDATA.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.DATA.RDATA.value <= 8'h0;
        end else begin
            if(field_combo.DATA.RDATA.load_next) begin
                field_storage.DATA.RDATA.value <= field_combo.DATA.RDATA.next;
            end
        end
    end
    assign hwif_out.DATA.RDATA.value = field_storage.DATA.RDATA.value;

