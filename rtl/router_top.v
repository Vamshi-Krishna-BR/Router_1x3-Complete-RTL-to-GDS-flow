module router_top_module (
    input clock,
    input resetn,
    input packet_valid,
    input [7:0] data_in,
    input [2:0] read_en,
    output [7:0] data_out_0,
    output [7:0] data_out_1,
    output [7:0] data_out_2,
    output [2:0] valid_out,
    output error,
    output busy
);
  wire lfd_state, ld_state, laf_state, full_state, write_enb_reg, rst_int_reg, detect_add;
  wire parity_done, low_packet_valid;
  wire fifo_full;
  wire [2:0] soft_reset;
  wire [2:0] write_enb;
  wire empty_0, empty_1, empty_2, full_0, full_1, full_2, dout;
  router_fifo FIFO_0 (
      .clock(clock),
      .resetn(resetn),
      .write_en(write_enb[0]),
      .read_en(read_en[0]),
      .soft_reset(soft_reset[0]),
      .data_in(dout),
      .lfd_state(lfd_state),
      .empty(empty_0),
      .full(full_0),
      .data_out(data_out_0)
  );
  router_fifo FIFO_1 (
      .clock(clock),
      .resetn(resetn),
      .write_en(write_enb[1]),
      .read_en(read_en[1]),
      .soft_reset(soft_reset[1]),
      .data_in(dout),
      .lfd_state(lfd_state),
      .empty(empty_1),
      .full(full_1),
      .data_out(data_out_1)
  );
  router_fifo FIFO_2 (
      .clock(clock),
      .resetn(resetn),
      .write_en(write_enb[2]),
      .read_en(read_en[2]),
      .soft_reset(soft_reset[2]),
      .data_in(dout),
      .lfd_state(lfd_state),
      .empty(empty_2),
      .full(full_2),
      .data_out(data_out_2)
  );
  router_synchronizer Synchroniser (
      .clock(clock),
      .resetn(resetn),
      .detect_add(detect_add),
      .data_in(data_in[1:0]),
      .write_enb_reg(write_enb_reg),
      .read_en(read_en),
      .empty_0(empty_0),
      .empty_1(empty_1),
      .empty_2(empty_2),
      .full_0(full_0),
      .full_1(full_1),
      .full_2(full_2),
      .write_enb(write_enb),
      .soft_reset(soft_reset),
      .fifo_full(fifo_full),
      .vld_out(valid_out)
  );
  router_register Register (
      .clock(clock),
      .resetn(resetn),
      .packet_valid(packet_valid),
      .fifo_full(fifo_full),
      .rst_int_reg(rst_int_reg),
      .detect_add(detect_add),
      .ld_state(ld_state),
      .laf_state(laf_state),
      .lfd_state(lfd_state),
      .full_state(full_state),
      .data_in(data_in),
      .parity_done(parity_done),
      .low_packet_valid(low_packet_valid),
      .error(error),
      .dout(dout)
  );
  router_fsm FSM (
      .clock(clock),
      .resetn(resetn),
      .parity_done(parity_done),
      .data_in(data_in[1:0]),
      .soft_reset(soft_reset),
      .fifo_full(fifo_full),
      .packet_valid(packet_valid),
      .low_packet_valid(low_packet_valid),
      .fifo_empty_0(empty_0),
      .fifo_empty_1(empty_1),
      .fifo_empty_2(empty_2),
      .busy(busy),
      .detect_add(detect_add),
      .lfd_state(lfd_state),
      .ld_state(ld_state),
      .laf_state(laf_state),
      .full_state(full_state),
      .write_enb_reg(write_enb_reg),
      .rst_int_reg(rst_int_reg)
  );

endmodule

