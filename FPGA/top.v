(* top *)
module top (
    (* iopad_external_pin, clkbuf_inhibit *) input  clk,
    (* iopad_external_pin *)                 output clk_en,
    (* iopad_external_pin *)                 input  rst_n,
    (* iopad_external_pin *)                 input  uart_rx,
    (* iopad_external_pin *)                 input  spi_ss_n,
    (* iopad_external_pin *)                 input  spi_sck,
    (* iopad_external_pin *)                 input  spi_mosi,
    (* iopad_external_pin *)                 output spi_miso,
    (* iopad_external_pin *)                 output spi_miso_en,
    (* iopad_external_pin *)                 input  i2c_sda,
    (* iopad_external_pin *)                 input  i2c_scl,
    (* iopad_external_pin *)                 output reg led,
    (* iopad_external_pin *)                 output led_en
);

    assign clk_en = 1'b1;
    assign led_en = 1'b1;

    reg [23:0] ts;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ts <= 24'd0;
        else        ts <= ts + 1'b1;
    end

    // ── UART receiver ────────────────────────────────────────────────────────
    wire [7:0] rx_byte;
    wire       rx_data_ready;
    wire       framing_err;

    uart_rx_core #(.CLKS_PER_BIT(5208)) u_uart (
        .clk(clk), .rst_n(rst_n), .uart_rx(uart_rx),
        .rx_byte(rx_byte), .rx_data_ready(rx_data_ready),
        .framing_err(framing_err)
    );

    // ── I2C decoder ──────────────────────────────────────────────────────────
    wire        pkt_valid, pkt_rw, pkt_ack, pkt_is_addr, pkt_start, pkt_stop;
    wire [7:0]  pkt_addr, pkt_data;
    wire [47:0] pkt_timestamp;

    i2c_decoder u_i2c (
        .clk(clk), .rst_n(rst_n),
        .sda(i2c_sda), .scl(i2c_scl),
        .pkt_valid(pkt_valid), .pkt_addr(pkt_addr), .pkt_data(pkt_data),
        .pkt_rw(pkt_rw), .pkt_ack(pkt_ack), .pkt_is_addr(pkt_is_addr),
        .pkt_start(pkt_start), .pkt_stop(pkt_stop),
        .pkt_timestamp(pkt_timestamp)
    );

    reg       fifo_wr_en;
    reg [7:0] fifo_wr_data;

    reg [3:0]  tx_state;
    reg [7:0]  saved_data;
    reg        saved_ack;
    reg [23:0] saved_ts;
    reg        start_pending, stop_pending;

    localparam [3:0]
        S_IDLE    = 4'd0,
        S_UART_D  = 4'd1,   
        S_TS2     = 4'd2,
        S_TS1     = 4'd3,
        S_TS0     = 4'd4,
        S_I2C_V   = 4'd5,
        S_I2C_A   = 4'd6,
        S_I2C_T2  = 4'd7,
        S_I2C_T1  = 4'd8,
        S_I2C_T0  = 4'd9,
        S_1B_TS2  = 4'd10,
        S_1B_TS1  = 4'd11,
        S_1B_TS0  = 4'd12;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_wr_en    <= 1'b0;
            fifo_wr_data  <= 8'h00;
            tx_state      <= S_IDLE;
            saved_data    <= 8'h00;
            saved_ack     <= 1'b0;
            saved_ts      <= 24'd0;
            start_pending <= 1'b0;
            stop_pending  <= 1'b0;
        end else begin

            fifo_wr_en <= 1'b0;

      
            if (pkt_start) start_pending <= 1'b1;
            if (pkt_stop)  stop_pending  <= 1'b1;

       
            if(tx_state == S_IDLE)
            begin

              
                if(start_pending)
                begin
                    start_pending <= 1'b0;

                    if(!fifo_full)
                    begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= 8'h01;
				tx_state <= S_IDLE;
                    end
                end

             
                else if(pkt_valid)
                begin
                    saved_ack <= pkt_ack;
                    //saved_ts  <= pkt_timestamp[23:0];

                    if(pkt_is_addr)
                    begin
                        saved_data <= pkt_addr;

                        if(!fifo_full)
                        begin
                            fifo_wr_en   <= 1'b1;
                            fifo_wr_data <= 8'h03;
                            tx_state     <= S_I2C_V;
                        end
                    end
                    else
                    begin
                        saved_data <= pkt_data;

                        if(!fifo_full)
                        begin
                            fifo_wr_en   <= 1'b1;
                            fifo_wr_data <= 8'h04;
                            tx_state     <= S_I2C_V;
                        end
                    end
                end

              
                else if(stop_pending)
                begin
                    stop_pending <= 1'b0;

                    if(!fifo_full)
                    begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= 8'h02;
				tx_state <= S_IDLE;
                    end
                end

               
                else if(rx_data_ready)
                begin
                    saved_data <= rx_byte;

                    if(!fifo_full)
                    begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= 8'hF1;
                        tx_state     <= S_UART_D;
                    end
                end

            end

 
            case (tx_state)

                S_IDLE: begin
                   
                end

              
                S_UART_D: begin
                    if(!fifo_full) begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= saved_data;
                        tx_state     <= S_IDLE;
                    end
                end

                S_TS2: begin
                    if(!fifo_full) begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= saved_ts[23:16];
                        tx_state     <= S_TS1;
                    end
                end

                S_TS1: begin
                    if(!fifo_full) begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= saved_ts[15:8];
                        tx_state     <= S_TS0;
                    end
                end

                S_TS0: begin
                    if(!fifo_full) begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= saved_ts[7:0];
                        tx_state     <= S_IDLE;
                    end
                end

                S_1B_TS2: begin
                    if(!fifo_full) begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= saved_ts[23:16];
                        tx_state     <= S_1B_TS1;
                    end
                end

                S_1B_TS1: begin
                    if(!fifo_full) begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= saved_ts[15:8];
                        tx_state     <= S_1B_TS0;
                    end
                end

                S_1B_TS0: begin
                    if(!fifo_full) begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= saved_ts[7:0];
                        tx_state     <= S_IDLE;
                    end
                end

                S_I2C_V: begin
                    if(!fifo_full) begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= saved_data;
                        tx_state     <= S_I2C_A;
                    end
                end

                S_I2C_A: begin
                    if(!fifo_full) begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= saved_ack ? 8'h05 : 8'h06;
                        tx_state     <= S_IDLE;
                    end
                end

                /*S_I2C_T2: begin
                    if(!fifo_full) begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= saved_ts[23:16];
                        tx_state     <= S_I2C_T1;
                    end
                end

                S_I2C_T1: begin
                    if(!fifo_full) begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= saved_ts[15:8];
                        tx_state     <= S_I2C_T0;
                    end
                end

                S_I2C_T0: begin
                    if(!fifo_full) begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= saved_ts[7:0];
                        tx_state     <= S_IDLE;
                    end
                end

                default: begin
                    tx_state <= S_IDLE;
                end */

            endcase
        end
    end

    // ── FIFO ─────────────────────────────────────────────────────────────────
    wire [7:0] fifo_data;
    wire fifo_empty, fifo_full;
    wire fifo_almost_empty, fifo_almost_full;
    wire fifo_overflow, fifo_underflow;

    reg        overflow_seen;
    reg        fifo_rd_en;

    uart_fifo #(.DATA_WIDTH(8), .DEPTH(16)) u_fifo (
        .clk(clk), .rst_n(rst_n),
        .wr_en(fifo_wr_en), .wr_data(fifo_wr_data),
        .rd_en(fifo_rd_en), .rd_data(fifo_data),
        .empty(fifo_empty), .full(fifo_full),
        .almost_empty(fifo_almost_empty), .almost_full(fifo_almost_full),
        .overflow(fifo_overflow), .underflow(fifo_underflow)
    );

    // Sticky overflow detector
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            overflow_seen <= 1'b0;
        else if(fifo_overflow)
            overflow_seen <= 1'b1;
    end

    // ── FIFO → SPI bridge
    reg [7:0] tx_data;
    wire      tx_data_hold;
    reg       tx_hold_d;
    reg       pending_read;

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            tx_hold_d <= 1'b0;
        else
            tx_hold_d <= tx_data_hold;
    end

    wire tx_hold_rise;
    assign tx_hold_rise = tx_data_hold & ~tx_hold_d;

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            tx_data      <= 8'h00;
            fifo_rd_en   <= 1'b0;
            pending_read <= 1'b0;
        end
        else
        begin
            fifo_rd_en <= 1'b0;

            // Advance FIFO one clock AFTER loading tx_data
            if(pending_read)
            begin
                fifo_rd_en   <= 1'b1;
                pending_read <= 1'b0;
            end

            // SPI requests next byte
            if(tx_hold_rise)
            begin
                if(!fifo_empty)
                begin
                    tx_data      <= fifo_data;
                    pending_read <= 1'b1;
                end
                else
                begin
                    tx_data <= 8'h00;
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            led <= 1'b0;
        else if(rx_data_ready || pkt_valid)
            led <= ~led;
    end

    // ── SPI target
    spi_target #(.CPOL(1'b0), .CPHA(1'b0), .WIDTH(8), .LSB(1'b0)) u_spi (
        .i_clk(clk), .i_rst_n(rst_n), .i_enable(1'b1),
        .i_ss_n(spi_ss_n), .i_sck(spi_sck), .i_mosi(spi_mosi),
        .o_miso(spi_miso), .o_miso_oe(spi_miso_en),
        .o_rx_data(), .o_rx_data_valid(),
        .i_tx_data(tx_data), .o_tx_data_hold(tx_data_hold)
    );

endmodule