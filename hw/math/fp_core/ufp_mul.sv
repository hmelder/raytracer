module ufp_mul #(
    parameter int CLIP = 0  // (if reducing iw) 0 = wrap, 1 = clip
) (
           ufp_if.in  x,
           ufp_if.in  y,
           ufp_if.out out,
    output            clipping  // clipping indicator (active-high)
);
  // Output must have the correct iw/qw for a full width operation
  ufp_if #(
      .IW(x.IW + y.IW),
      .QW(x.QW + y.QW)
  ) prod_fp ();
  assign prod_fp.val = x.val * y.val;
  ufp_resize #(
      .clip(CLIP)
  ) u_resize (
      .in(prod_fp),
      .out(out),
      .clipping(clipping)
  );
endmodule
