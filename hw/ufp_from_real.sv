
// Convert a real input to a ufp signal by rounding.
// Reals that are outside the range of the ufp would throw an $error().
// This module is NOT synthesizable!
module ufp_from_real (
    input real       float,  // input real
          ufp_if.out fp      // output ufp signal
);
  localparam longint TOP = 2 ** fp.WL - 1;
  localparam longint BOT = 'd0;

  longint ival;

  always_comb begin
    ival = longint'(float * (2.0 ** fp.QW));  // rounds to nearest integer
    if ((ival <= TOP) && (ival >= BOT)) fp.val = unsigned'(fp.WL'(ival));
    else
      $error(
          "%m: real number %f does not fit in the %d.%d format of the output!", float, fp.IW, fp.QW
      );
  end

endmodule
