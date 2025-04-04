// Multiplication of sfp signals with full precision.
// Output must have the correct iw/qw for a full width operation:
// out.iw = in1.iw + in2.iw and out.qw = in1.qw + in2.qw
module sfp_mul_full (
    sfp_if.in  in1,
    sfp_if.in  in2,  // input sfp signal
    sfp_if.out out   // output sfp signal (= in1 * in2)
);

  if ((in1.IW + in2.IW != out.IW) || (in1.QW + in2.QW != out.QW))
    $error(
        {
          "%m: Incorrect output word length for a full-width mult!",
          "Make sure out.iw = in1.iw + in2.iw and out.qw = in1.qw + in2.qw"
        }
    );

  assign out.val = (in1.val) * (in2.val);

endmodule
