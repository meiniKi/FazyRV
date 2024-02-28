//
// in parts adopted from SERV

module rvfi_wrapper (
    input         clock,
    input         reset,
    `RVFI_OUTPUTS
);

  localparam PAR_BWIDTH = `CHUNKSIZE;
  localparam CONF       = "MIN";
  localparam MTVAL      = 'b0;
  localparam BOOTADR    = 'h0;
  localparam RFTYPE     = "LOGIC";

  localparam MEMDLY1  = 0;

  // imem
  (* keep *)      wire [31:0] ibus_adr;
  (* keep *)      wire        ibus_cyc;
  (* keep *) rand reg  [31:0] ibus_rdt;
  (* keep *) rand reg         ibus_ack;

  // dmem
  (* keep *)      wire [31:0] dbus_adr;
  (* keep *)      wire [31:0] dbus_dat;
  (* keep *)      wire [3:0]  dbus_sel;
  (* keep *)      wire        dbus_we;
  (* keep *)      wire        dbus_cyc;
  (* keep *) rand reg  [31:0] dbus_rdt;
  (* keep *) rand reg         dbus_ack;

  fazyrv_top #( 
    .CHUNKSIZE  ( PAR_BWIDTH  ),
    .CONF       ( CONF        ),
    .MTVAL      ( MTVAL       ),
    .BOOTADR    ( BOOTADR     ),
    .RFTYPE     ( RFTYPE      ),
    .MEMDLY1    ( MEMDLY1     )
  ) i_fazyr_top (
    .clk_i            ( clock     ),
    .rst_in           ( ~reset    ),
    .tirq_i           ( 1'b0      ),
    `RVFI_CONN,
    // imem
    .wb_imem_stb_o    ( ibus_cyc  ),
    .wb_imem_cyc_o    (  ),
    .wb_imem_adr_o    ( ibus_adr  ),
    .wb_imem_dat_i    ( ibus_rdt  ),
    .wb_imem_ack_i    ( ibus_ack  ),
    // dmem
    .wb_dmem_cyc_o    (  ),
    .wb_dmem_stb_o    ( dbus_cyc  ),
    .wb_dmem_we_o     ( dbus_we   ),
    .wb_dmem_ack_i    ( dbus_ack  ),
    .wb_dmem_be_o     ( dbus_sel  ),
    .wb_dmem_dat_i    ( dbus_rdt  ),
    .wb_dmem_adr_o    ( dbus_adr  ),
    .wb_dmem_dat_o    ( dbus_dat  )
  );

  // imem
	always @(posedge clock) begin
		if (reset) begin
			assume (!ibus_ack);
		end
		if (!ibus_cyc) begin
			assume (!ibus_ack);
		end

    //if (ibus_cyc) begin
		//	assume (ibus_ack);
		//end
	end

	// dmem
	always @(posedge clock) begin
		if (reset) begin
			assume (!dbus_ack);
		end
		if (!dbus_cyc) begin
			assume (!dbus_ack);
		end

    //if (dbus_cyc) begin
		//	assume (dbus_ack);
		//end
	end

  always assume (~rvfi_trap);

endmodule
