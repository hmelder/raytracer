// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Skyworks Inc.
// Copyright (c) 2025 Hugo Melder


// Change the # of int/frac bits of a ufp signal (with a clipping indicator)
// - Decreasing # frac bits: truncates LSBs (floor toward -inf)
// - Increasing # frac bits: pads zero LSBs
// - Decreasing # int  bits: clips or drops MSBs depending on 'clip' parameter
// - Increasing # int  bits: pads zero MSBs (ufp) or sign-extends (sfp)
module ufp_resize #(
    parameter clip = 1  // (if reducing iw) 0 = wrap, 1 = clip
) (
           ufp_if.in  in,       // input ufp signal
           ufp_if.out out,      // output ufp signal
    output            clipping  // clipping indicator (active-high)
);

  localparam iniw = in.IW;
  localparam inqw = in.QW;
  localparam inw = in.WL;
  localparam outiw = out.IW;
  localparam outqw = out.QW;
  localparam outw = out.WL;

  localparam tmp1w = iniw + outqw;
  localparam tmp2w = outiw + inqw;

  if (tmp1w > 1) begin : gen_case1
    logic [tmp1w-1:0] tmp1;
    // first handle the franctional bits by truncating LSBs or padding zeros
    if (inqw >= outqw) assign tmp1 = $unsigned(in.val[inw-1-:tmp1w]);
    else assign tmp1 = $unsigned({in.val, (outqw - inqw)'('b0)});
    // then handle the integer bits by clipping / discarding MSBs (may causing wrapping!), or sign extending MSBs
    if (iniw > outiw) begin
      if (clip) begin
        clip_unsigned #(
            .INW (tmp1w),
            .OUTW(outw)
        ) u_clip (
            .in(tmp1),
            .out(out.val),
            .clipping(clipping)
        );
      end else begin
        assign out.val  = $unsigned(tmp1[outw-1:0]);
        assign clipping = 1'b0;
      end
    end else begin
      assign out.val  = outw'(tmp1);
      assign clipping = 1'b0;
    end
  end else begin : gen_case2
    logic [tmp2w-1:0] tmp2;
    // first handle the integer bits by clipping / discarding MSBs (may causing wrapping!), or sign extending MSBs
    if (iniw > outiw) begin
      if (clip) begin
        clip_unsigned #(
            .INW (inw),
            .OUTW(tmp2w)
        ) u_clip (
            .in(in.val),
            .out(tmp2),
            .clipping(clipping)
        );
      end else begin
        assign tmp2 = $unsigned(in.val[tmp2w-1:0]);
        assign clipping = 1'b0;
      end
    end else begin
      assign tmp2 = tmp2w'(in.val);
      assign clipping = 1'b0;
    end
    // then handle the fractional bits by truncating LSBs or padding zeros
    if (inqw >= outqw) assign out.val = $unsigned(tmp2[tmp2w-1-:outw]);
    else assign out.val = $unsigned({tmp2, (outqw - inqw)'('b0)});
  end

endmodule
