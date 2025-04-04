module sfp_mul #(
    parameter int CLIP = 0  // (if reducing iw) 0 = wrap, 1 = clip
) (
           sfp_if.in  x,
           sfp_if.in  y,
           sfp_if.out out,
    output            clipping  // clipping indicator (active-high)
);
  // Output must have the correct iw/qw for a full width operation
  sfp_if #(
      .IW(x.IW + y.IW),
      .QW(x.QW + y.QW)
  ) prod_fp ();
  assign prod_fp.val = x.val * y.val;
  sfp_resize #(
      .clip(CLIP)
  ) u_resize (
      .in(prod_fp),
      .out(out),
      .clipping(clipping)
  );
endmodule
