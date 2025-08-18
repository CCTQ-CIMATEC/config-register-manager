// Lógica CSR_IP_Map - Gerado automaticamente em 2025-08-18 09:56:22
// Lógica dos registradores CSR

    //--------------------------------------------------------------------------
    // Field logic
    //--------------------------------------------------------------------------
    typedef struct {
        struct {
            struct {
                logic [1:0] next;
                logic load_next;
            } mode2;
            struct {
                logic [1:0] next;
                logic load_next;
            } priority;
            struct {
                logic next;
                logic load_next;
            } enable2;
            struct {
                logic next;
                logic load_next;
            } resetn;
        } ctrl2;
        struct {
            struct {
                logic [7:0] next;
                logic load_next;
            } clockdiv;
        } cfg;
        struct {
            struct {
                logic next;
                logic load_next;
            } err;
            struct {
                logic next;
                logic load_next;
            } ready;
        } stat2;
        struct {
            struct {
                logic [15:0] next;
                logic load_next;
            } in;
            struct {
                logic [15:0] next;
                logic load_next;
            } out;
        } data2;
        struct {
            struct {
                logic [1:0] next;
                logic load_next;
            } prescaler;
            struct {
                logic [1:0] next;
                logic load_next;
            } mode;
            struct {
                logic next;
                logic load_next;
            } master;
            struct {
                logic next;
                logic load_next;
            } dord;
            struct {
                logic next;
                logic load_next;
            } enable;
            struct {
                logic next;
                logic load_next;
            } clk2x;
        } ctrl;
        struct {
            struct {
                logic [1:0] next;
                logic load_next;
            } intlvl;
        } intctrl;
        struct {
            struct {
                logic next;
                logic load_next;
            } wrcol;
            struct {
                logic next;
                logic load_next;
            } if;
        } status;
        struct {
            struct {
                logic [8:0] next;
                logic load_next;
            } wdata;
            struct {
                logic [8:0] next;
                logic load_next;
            } rdata;
        } data;
    } field_combo_t;
    field_combo_t field_combo;

    typedef struct {
        struct {
            struct {
                logic [1:0] value;
            } mode2;
            struct {
                logic [1:0] value;
            } priority;
            struct {
                logic value;
            } enable2;
            struct {
                logic value;
            } resetn;
        } ctrl2;
        struct {
            struct {
                logic [7:0] value;
            } clockdiv;
        } cfg;
        struct {
            struct {
                logic value;
            } err;
            struct {
                logic value;
            } ready;
        } stat2;
        struct {
            struct {
                logic [15:0] value;
            } in;
            struct {
                logic [15:0] value;
            } out;
        } data2;
        struct {
            struct {
                logic [1:0] value;
            } prescaler;
            struct {
                logic [1:0] value;
            } mode;
            struct {
                logic value;
            } master;
            struct {
                logic value;
            } dord;
            struct {
                logic value;
            } enable;
            struct {
                logic value;
            } clk2x;
        } ctrl;
        struct {
            struct {
                logic [1:0] value;
            } intlvl;
        } intctrl;
        struct {
            struct {
                logic value;
            } wrcol;
            struct {
                logic value;
            } if;
        } status;
        struct {
            struct {
                logic [8:0] value;
            } wdata;
            struct {
                logic [8:0] value;
            } rdata;
        } data;
    } field_storage_t;
    field_storage_t field_storage;

    // Field: CSR_IP_Map.ctrl2.mode2
    always_comb begin
        automatic logic [1:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.ctrl2.mode2.value;
        load_next_c = '0;
        if(decoded_reg_strb.ctrl2 && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.ctrl2.mode2.value & ~decoded_wr_biten[1:0]) | (decoded_wr_data[1:0] & decoded_wr_biten[1:0]);
            load_next_c = '1;
        end
        field_combo.ctrl2.mode2.next = next_c;
        field_combo.ctrl2.mode2.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.ctrl2.mode2.value <= 0x1;
        end else begin
            if(field_combo.ctrl2.mode2.load_next) begin
                field_storage.ctrl2.mode2.value <= field_combo.ctrl2.mode2.next;
            end
        end
    end
    assign hwif_out.ctrl2.mode2.value = field_storage.ctrl2.mode2.value;

    // Field: CSR_IP_Map.ctrl2.priority
    always_comb begin
        automatic logic [1:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.ctrl2.priority.value;
        load_next_c = '0;
        if(decoded_reg_strb.ctrl2 && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.ctrl2.priority.value & ~decoded_wr_biten[3:2]) | (decoded_wr_data[3:2] & decoded_wr_biten[3:2]);
            load_next_c = '1;
        end
        field_combo.ctrl2.priority.next = next_c;
        field_combo.ctrl2.priority.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.ctrl2.priority.value <= 0;
        end else begin
            if(field_combo.ctrl2.priority.load_next) begin
                field_storage.ctrl2.priority.value <= field_combo.ctrl2.priority.next;
            end
        end
    end
    assign hwif_out.ctrl2.priority.value = field_storage.ctrl2.priority.value;

    // Field: CSR_IP_Map.ctrl2.enable2
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.ctrl2.enable2.value;
        load_next_c = '0;
        if(decoded_reg_strb.ctrl2 && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.ctrl2.enable2.value & ~decoded_wr_biten[4:4]) | (decoded_wr_data[4:4] & decoded_wr_biten[4:4]);
            load_next_c = '1;
        end
        field_combo.ctrl2.enable2.next = next_c;
        field_combo.ctrl2.enable2.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.ctrl2.enable2.value <= 1'h0;
        end else begin
            if(field_combo.ctrl2.enable2.load_next) begin
                field_storage.ctrl2.enable2.value <= field_combo.ctrl2.enable2.next;
            end
        end
    end
    assign hwif_out.ctrl2.enable2.value = field_storage.ctrl2.enable2.value;

    // Field: CSR_IP_Map.ctrl2.resetn
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.ctrl2.resetn.value;
        load_next_c = '0;
        if(decoded_reg_strb.ctrl2 && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.ctrl2.resetn.value & ~decoded_wr_biten[5:5]) | (decoded_wr_data[5:5] & decoded_wr_biten[5:5]);
            load_next_c = '1;
        end else if(hwif_in.ctrl2.resetn.we) begin // HW Write - we
            next_c = hwif_in.ctrl2.resetn.next;
            load_next_c = '1;
        end
        field_combo.ctrl2.resetn.next = next_c;
        field_combo.ctrl2.resetn.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.ctrl2.resetn.value <= 0x1;
        end else begin
            if(field_combo.ctrl2.resetn.load_next) begin
                field_storage.ctrl2.resetn.value <= field_combo.ctrl2.resetn.next;
            end
        end
    end
    assign hwif_out.ctrl2.resetn.value = field_storage.ctrl2.resetn.value;

    // Field: CSR_IP_Map.cfg.clockdiv
    always_comb begin
        automatic logic [7:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.cfg.clockdiv.value;
        load_next_c = '0;
        if(decoded_reg_strb.cfg && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.cfg.clockdiv.value & ~decoded_wr_biten[7:0]) | (decoded_wr_data[7:0] & decoded_wr_biten[7:0]);
            load_next_c = '1;
        end
        field_combo.cfg.clockdiv.next = next_c;
        field_combo.cfg.clockdiv.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.cfg.clockdiv.value <= 0x2;
        end else begin
            if(field_combo.cfg.clockdiv.load_next) begin
                field_storage.cfg.clockdiv.value <= field_combo.cfg.clockdiv.next;
            end
        end
    end
    assign hwif_out.cfg.clockdiv.value = field_storage.cfg.clockdiv.value;

    // Field: CSR_IP_Map.stat2.err
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.stat2.err.value;
        load_next_c = '0;
        if(hwif_in.stat2.err.we) begin // HW Write - we
            next_c = hwif_in.stat2.err.next;
            load_next_c = '1;
        end
        field_combo.stat2.err.next = next_c;
        field_combo.stat2.err.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.stat2.err.value <= 1'h0;
        end else begin
            if(field_combo.stat2.err.load_next) begin
                field_storage.stat2.err.value <= field_combo.stat2.err.next;
            end
        end
    end
    assign hwif_out.stat2.err.value = field_storage.stat2.err.value;

    // Field: CSR_IP_Map.stat2.ready
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.stat2.ready.value;
        load_next_c = '0;
        if(hwif_in.stat2.ready.we) begin // HW Write - we
            next_c = hwif_in.stat2.ready.next;
            load_next_c = '1;
        end
        field_combo.stat2.ready.next = next_c;
        field_combo.stat2.ready.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.stat2.ready.value <= 0x1;
        end else begin
            if(field_combo.stat2.ready.load_next) begin
                field_storage.stat2.ready.value <= field_combo.stat2.ready.next;
            end
        end
    end
    assign hwif_out.stat2.ready.value = field_storage.stat2.ready.value;

    // Field: CSR_IP_Map.data2.in
    always_comb begin
        automatic logic [15:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.data2.in.value;
        load_next_c = '0;
        if(decoded_reg_strb.data2 && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.data2.in.value & ~decoded_wr_biten[15:0]) | (decoded_wr_data[15:0] & decoded_wr_biten[15:0]);
            load_next_c = '1;
        end
        field_combo.data2.in.next = next_c;
        field_combo.data2.in.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(field_combo.data2.in.load_next) begin
            field_storage.data2.in.value <= field_combo.data2.in.next;
        end
    end

    // Field: CSR_IP_Map.data2.out
    always_comb begin
        automatic logic [15:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.data2.out.value;
        load_next_c = '0;
        if(decoded_reg_strb.data2 && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.data2.out.value & ~decoded_wr_biten[31:16]) | (decoded_wr_data[31:16] & decoded_wr_biten[31:16]);
            load_next_c = '1;
        end else if(hwif_in.data2.out.we) begin // HW Write - we
            next_c = hwif_in.data2.out.next;
            load_next_c = '1;
        end
        field_combo.data2.out.next = next_c;
        field_combo.data2.out.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.data2.out.value <= 16'h0;
        end else begin
            if(field_combo.data2.out.load_next) begin
                field_storage.data2.out.value <= field_combo.data2.out.next;
            end
        end
    end
    assign hwif_out.data2.out.value = field_storage.data2.out.value;

    // Field: CSR_IP_Map.ctrl.prescaler
    always_comb begin
        automatic logic [1:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.ctrl.prescaler.value;
        load_next_c = '0;
        if(decoded_reg_strb.ctrl && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.ctrl.prescaler.value & ~decoded_wr_biten[1:0]) | (decoded_wr_data[1:0] & decoded_wr_biten[1:0]);
            load_next_c = '1;
        end
        field_combo.ctrl.prescaler.next = next_c;
        field_combo.ctrl.prescaler.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.ctrl.prescaler.value <= 0;
        end else begin
            if(field_combo.ctrl.prescaler.load_next) begin
                field_storage.ctrl.prescaler.value <= field_combo.ctrl.prescaler.next;
            end
        end
    end
    assign hwif_out.ctrl.prescaler.value = field_storage.ctrl.prescaler.value;

    // Field: CSR_IP_Map.ctrl.mode
    always_comb begin
        automatic logic [1:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.ctrl.mode.value;
        load_next_c = '0;
        if(decoded_reg_strb.ctrl && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.ctrl.mode.value & ~decoded_wr_biten[3:2]) | (decoded_wr_data[3:2] & decoded_wr_biten[3:2]);
            load_next_c = '1;
        end
        field_combo.ctrl.mode.next = next_c;
        field_combo.ctrl.mode.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.ctrl.mode.value <= 0;
        end else begin
            if(field_combo.ctrl.mode.load_next) begin
                field_storage.ctrl.mode.value <= field_combo.ctrl.mode.next;
            end
        end
    end
    assign hwif_out.ctrl.mode.value = field_storage.ctrl.mode.value;

    // Field: CSR_IP_Map.ctrl.master
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.ctrl.master.value;
        load_next_c = '0;
        if(decoded_reg_strb.ctrl && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.ctrl.master.value & ~decoded_wr_biten[4:4]) | (decoded_wr_data[4:4] & decoded_wr_biten[4:4]);
            load_next_c = '1;
        end else if(hwif_in.ctrl.master.we) begin // HW Write - we
            next_c = hwif_in.ctrl.master.next;
            load_next_c = '1;
        end
        field_combo.ctrl.master.next = next_c;
        field_combo.ctrl.master.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.ctrl.master.value <= 1'h0;
        end else begin
            if(field_combo.ctrl.master.load_next) begin
                field_storage.ctrl.master.value <= field_combo.ctrl.master.next;
            end
        end
    end
    assign hwif_out.ctrl.master.value = field_storage.ctrl.master.value;

    // Field: CSR_IP_Map.ctrl.dord
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.ctrl.dord.value;
        load_next_c = '0;
        if(decoded_reg_strb.ctrl && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.ctrl.dord.value & ~decoded_wr_biten[5:5]) | (decoded_wr_data[5:5] & decoded_wr_biten[5:5]);
            load_next_c = '1;
        end
        field_combo.ctrl.dord.next = next_c;
        field_combo.ctrl.dord.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.ctrl.dord.value <= 1'h0;
        end else begin
            if(field_combo.ctrl.dord.load_next) begin
                field_storage.ctrl.dord.value <= field_combo.ctrl.dord.next;
            end
        end
    end
    assign hwif_out.ctrl.dord.value = field_storage.ctrl.dord.value;

    // Field: CSR_IP_Map.ctrl.enable
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.ctrl.enable.value;
        load_next_c = '0;
        if(decoded_reg_strb.ctrl && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.ctrl.enable.value & ~decoded_wr_biten[6:6]) | (decoded_wr_data[6:6] & decoded_wr_biten[6:6]);
            load_next_c = '1;
        end
        field_combo.ctrl.enable.next = next_c;
        field_combo.ctrl.enable.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.ctrl.enable.value <= 1'h0;
        end else begin
            if(field_combo.ctrl.enable.load_next) begin
                field_storage.ctrl.enable.value <= field_combo.ctrl.enable.next;
            end
        end
    end
    assign hwif_out.ctrl.enable.value = field_storage.ctrl.enable.value;

    // Field: CSR_IP_Map.ctrl.clk2x
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.ctrl.clk2x.value;
        load_next_c = '0;
        if(decoded_reg_strb.ctrl && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.ctrl.clk2x.value & ~decoded_wr_biten[7:7]) | (decoded_wr_data[7:7] & decoded_wr_biten[7:7]);
            load_next_c = '1;
        end
        field_combo.ctrl.clk2x.next = next_c;
        field_combo.ctrl.clk2x.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.ctrl.clk2x.value <= 1'h0;
        end else begin
            if(field_combo.ctrl.clk2x.load_next) begin
                field_storage.ctrl.clk2x.value <= field_combo.ctrl.clk2x.next;
            end
        end
    end
    assign hwif_out.ctrl.clk2x.value = field_storage.ctrl.clk2x.value;

    // Field: CSR_IP_Map.intctrl.intlvl
    always_comb begin
        automatic logic [1:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.intctrl.intlvl.value;
        load_next_c = '0;
        if(decoded_reg_strb.intctrl && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.intctrl.intlvl.value & ~decoded_wr_biten[1:0]) | (decoded_wr_data[1:0] & decoded_wr_biten[1:0]);
            load_next_c = '1;
        end
        field_combo.intctrl.intlvl.next = next_c;
        field_combo.intctrl.intlvl.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.intctrl.intlvl.value <= 0;
        end else begin
            if(field_combo.intctrl.intlvl.load_next) begin
                field_storage.intctrl.intlvl.value <= field_combo.intctrl.intlvl.next;
            end
        end
    end
    assign hwif_out.intctrl.intlvl.value = field_storage.intctrl.intlvl.value;

    // Field: CSR_IP_Map.status.wrcol
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.status.wrcol.value;
        load_next_c = '0;
        if(hwif_in.status.wrcol.we) begin // HW Write - we
            next_c = hwif_in.status.wrcol.next;
            load_next_c = '1;
        end
        field_combo.status.wrcol.next = next_c;
        field_combo.status.wrcol.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.status.wrcol.value <= 1'h0;
        end else begin
            if(field_combo.status.wrcol.load_next) begin
                field_storage.status.wrcol.value <= field_combo.status.wrcol.next;
            end
        end
    end
    assign hwif_out.status.wrcol.value = field_storage.status.wrcol.value;

    // Field: CSR_IP_Map.status.if
    always_comb begin
        automatic logic [0:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.status.if.value;
        load_next_c = '0;
        if(hwif_in.status.if.we) begin // HW Write - we
            next_c = hwif_in.status.if.next;
            load_next_c = '1;
        end
        field_combo.status.if.next = next_c;
        field_combo.status.if.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.status.if.value <= 1'h0;
        end else begin
            if(field_combo.status.if.load_next) begin
                field_storage.status.if.value <= field_combo.status.if.next;
            end
        end
    end
    assign hwif_out.status.if.value = field_storage.status.if.value;

    // Field: CSR_IP_Map.data.wdata
    always_comb begin
        automatic logic [8:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.data.wdata.value;
        load_next_c = '0;
        if(decoded_reg_strb.data && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.data.wdata.value & ~decoded_wr_biten[8:0]) | (decoded_wr_data[8:0] & decoded_wr_biten[8:0]);
            load_next_c = '1;
        end
        field_combo.data.wdata.next = next_c;
        field_combo.data.wdata.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(field_combo.data.wdata.load_next) begin
            field_storage.data.wdata.value <= field_combo.data.wdata.next;
        end
    end

    // Field: CSR_IP_Map.data.rdata
    always_comb begin
        automatic logic [8:0] next_c;
        automatic logic load_next_c;
        next_c = field_storage.data.rdata.value;
        load_next_c = '0;
        if(decoded_reg_strb.data && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.data.rdata.value & ~decoded_wr_biten[16:8]) | (decoded_wr_data[16:8] & decoded_wr_biten[16:8]);
            load_next_c = '1;
        end else if(hwif_in.data.rdata.we) begin // HW Write - we
            next_c = hwif_in.data.rdata.next;
            load_next_c = '1;
        end
        field_combo.data.rdata.next = next_c;
        field_combo.data.rdata.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.data.rdata.value <= 9'h0;
        end else begin
            if(field_combo.data.rdata.load_next) begin
                field_storage.data.rdata.value <= field_combo.data.rdata.next;
            end
        end
    end
    assign hwif_out.data.rdata.value = field_storage.data.rdata.value;

