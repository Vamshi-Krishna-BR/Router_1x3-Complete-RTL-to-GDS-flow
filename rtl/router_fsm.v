module router_fsm (
    input            clock,
    input            resetn,
    input            parity_done,
    input      [1:0] data_in,
    input      [2:0] soft_reset,
    input            fifo_full,
    input            packet_valid,
    input            low_packet_valid,
    input            fifo_empty_0,
    input            fifo_empty_1,
    input            fifo_empty_2,
    output reg       busy,
    output reg       detect_add,
    output reg       lfd_state,         //load_first_data
    output reg       ld_state,          //load_data
    output reg       laf_state,         //load_after_full
    output reg       full_state,
    output reg       write_enb_reg,
    output reg       rst_int_reg
);
  //8 states 3bs
  parameter Decode_address = 3'd0;
  parameter Load_first_data = 3'd1;
  parameter Wait_till_empty = 3'd2;
  parameter Load_data = 3'd3;
  parameter Fifo_full_state = 3'd4;
  parameter Load_parity = 3'd5;
  parameter Load_after_full = 3'd6;
  parameter Check_parity_error = 3'd7;
  reg [2:0] present_state, next_state;
  reg [1:0] dest_addr;
  reg [1:0] next_dest_addr;
  reg soft_reset_active;

  always @(posedge clock) begin
    if (!resetn) begin
      dest_addr <= 2'b11;
      present_state <= Decode_address;
    end else begin
      dest_addr <= next_dest_addr;
      present_state <= next_state;
    end
  end
  always @(*) begin
    case (dest_addr)
      2'b00:   soft_reset_active = soft_reset[0];
      2'b01:   soft_reset_active = soft_reset[1];
      2'b10:   soft_reset_active = soft_reset[2];
      default: soft_reset_active = 1'b0;
    endcase
  end
  always @(*) begin
    next_state = Decode_address;
    next_dest_addr = dest_addr;
    rst_int_reg = 1'b0;
    full_state = 1'b0;
    ld_state = 1'b0;
    detect_add = 1'b0;
    lfd_state = 1'b0;
    laf_state = 1'b0;
    busy = 1'b0;
    write_enb_reg = 1'b0;
    case (present_state)
      Decode_address: begin
        if (((packet_valid) && data_in[1:0] == 2'b00 && (fifo_empty_0))
        || ((packet_valid) && data_in[1:0] == 2'b01 && (fifo_empty_1))
        || ((packet_valid) && data_in[1:0] == 2'b10 && (fifo_empty_2)))begin
          next_dest_addr = (data_in[1:0] == 0) ? 2'b00 : (data_in[1:0] == 1) ? 2'b01 : 2'b10;
          detect_add = 1'b1;
          next_state = Load_first_data;
        end else if ((packet_valid) && (data_in[1:0] == 2'b11)) begin
          next_state = Wait_till_empty;
          next_dest_addr = dest_addr;
        end else begin
          next_dest_addr = dest_addr;
          next_state = Wait_till_empty;
        end
      end
      Wait_till_empty: begin
        if (soft_reset_active) next_state = Decode_address;
        else begin
          busy = 1'b1;
          write_enb_reg = 1'b0;
          if (dest_addr == 2'b11) next_state = Decode_address;
          else if ((fifo_empty_0 && dest_addr == 2'b00) || 
           (fifo_empty_1 &&  dest_addr == 2'b01) || 
           (fifo_empty_2 && dest_addr == 2'b10))
            next_state = Load_first_data;
          else begin
            next_state = Wait_till_empty;
          end
        end
      end
      Load_first_data: begin
        if (soft_reset_active) next_state = Decode_address;
        else begin
          lfd_state = 1'b1;
          busy = 1'b1;
          write_enb_reg = 1'b0;
          next_state = Load_data;
        end
      end
      Load_data: begin
        if (soft_reset_active) next_state = Decode_address;
        else begin
          ld_state = 1'b1;
          busy = 1'b0;
          write_enb_reg = 1'b1;
          if (!fifo_full && !packet_valid) begin
            next_state = Load_parity;
          end else if (fifo_full) next_state = Fifo_full_state;
          else begin
            next_state = Load_data;
          end
        end
      end
      Fifo_full_state: begin
        if (soft_reset_active) next_state = Decode_address;
        else begin
          full_state = 1'b1;
          write_enb_reg = 1'b0;
          busy = 1'b1;
          if (!fifo_full) begin
            next_state = Load_after_full;
          end else begin
            next_state = Fifo_full_state;
          end
        end
      end
      Load_parity: begin
        if (soft_reset_active) next_state = Decode_address;
        else begin
          busy = 1'b1;
          write_enb_reg = 1'b1;
          next_state = Check_parity_error;
        end
      end
      Load_after_full: begin
        if (soft_reset_active) next_state = Decode_address;
        else begin
          laf_state = 1'b1;
          busy = 1'b1;
          write_enb_reg = 1'b1;
          if (!parity_done && low_packet_valid) next_state = Load_parity;
          else if (!parity_done && !low_packet_valid) next_state = Load_data;
          else next_state = Decode_address;
        end
      end
      Check_parity_error: begin
        if (soft_reset_active) next_state = Decode_address;
        else begin
          busy = 1'b1;
          rst_int_reg = 1'b1;
          if (!fifo_full) next_state = Decode_address;
          else next_state = Fifo_full_state;
        end
      end
    endcase
  end
endmodule

