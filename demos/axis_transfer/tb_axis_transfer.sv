`timescale 1ns / 1ps

module tb_axis_transfer ();


  // verilog_format: off
  reg                          ACLK = 0;    // Synchronous clock
  reg                          ARESETN; // System reset, active low
  // slave in interface
  wire                         S_AXIS_TREADY;  // Ready to accept data in
  reg      [31 : 0]            S_AXIS_TDATA;   // Data in
  reg                          S_AXIS_TLAST;   // Optional data in qualifier
  reg                          S_AXIS_TVALID;  // Data in is valid
  // master out interface
  wire                         M_AXIS_TVALID;  // Data out is valid
  wire     [31 : 0]            M_AXIS_TDATA;   // Data out
  wire                         M_AXIS_TLAST;   // Optional data out qualifier
  reg                          M_AXIS_TREADY;  // Connected slave device is ready to accept data out
  // verilog_format: on

  axis_transfer U1 (
      .aclk(ACLK),
      .aresetn(ARESETN),
      .m_axis_tvalid(M_AXIS_TVALID),
      .m_axis_tdata(M_AXIS_TDATA),
      .m_axis_tlast(M_AXIS_TLAST),
      .m_axis_tready(M_AXIS_TREADY)
  );

  reg M_AXIS_TLAST_prev = 1'b0;

  always @(posedge ACLK) M_AXIS_TLAST_prev <= M_AXIS_TLAST;

  always #50 ACLK = ~ACLK;

  initial begin
    $dumpfile("tb_axis_transfer.vcd");
    $dumpvars(0, tb_axis_transfer);

    #25  // to make inputs and capture from testbench not aligned with clock edges
    ARESETN = 1'b0;
    S_AXIS_TVALID = 1'b0;
    S_AXIS_TLAST  = 1'b0;
    M_AXIS_TREADY = 1'b0;

    #100  // hold reset for 100 ns.
    ARESETN = 1'b1;

    M_AXIS_TREADY = 1'b1;
    while(M_AXIS_TLAST | ~M_AXIS_TLAST_prev) // receive data until the falling edge of M_AXIS_TLAST
      begin
      if (M_AXIS_TVALID) begin
        $display("0x%x", M_AXIS_TDATA);
        $finish;
      end
      #100;
    end  // receive loop
    M_AXIS_TREADY = 1'b0;
    $finish;
  end
endmodule
