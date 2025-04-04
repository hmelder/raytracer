// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Skyworks Inc.
// Copyright (c) 2025 Hugo Melder

// Change the # of int/frac bits of a sfp signal (with a clipping indicator)
// - Decreasing # frac bits: truncates LSBs (floor toward -inf)
// - Increasing # frac bits: pads zero LSBs
// - Decreasing # int  bits: clips or drops MSBs depending on 'clip' parameter
// - Increasing # int  bits: pads zero MSBs (ufp) or sign-extends (sfp)
module sfp_resize #(
    clip = 1  // (if reducing iw) 0 = wrap, 1 = clip
) (
           sfp_if.in  in,       // input sfp signal
           sfp_if.out out,      // output sfp signal
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
    logic signed [tmp1w-1:0] tmp1;
    // first handle the franctional bits by truncating LSBs or padding zeros
    if (inqw >= outqw) assign tmp1 = $signed(in.val[inw-1-:tmp1w]);
    else assign tmp1 = $signed({in.val, (outqw - inqw)'('b0)});
    // then handle the integer bits by clipping / discarding MSBs (may causing wrapping!), or sign extending MSBs
    if (iniw > outiw) begin
      if (clip) begin
        clip_signed #(
            .inw (tmp1w),
            .outw(outw)
        ) u_clip (
            .in(tmp1),
            .out(out.val),
            .clipping(clipping)
        );
      end else begin
        assign out.val  = $signed(tmp1[outw-1:0]);
        assign clipping = 1'b0;
      end
    end else begin
      assign out.val  = outw'(tmp1);
      assign clipping = 1'b0;
    end
  end else begin : gen_case2
    logic signed [tmp2w-1:0] tmp2;
    // first handle the integer bits by clipping / discarding MSBs (may causing wrapping!), or sign extending MSBs
    if (iniw > outiw) begin
      if (clip) begin
        clip_signed #(
            .inw (inw),
            .outw(tmp2w)
        ) u_clip (
            .in(in.val),
            .out(tmp2),
            .clipping(clipping)
        );
      end else begin
        assign tmp2 = $signed(in.val[tmp2w-1:0]);
        assign clipping = 1'b0;
      end
    end else begin
      assign tmp2 = tmp2w'(in.val);
      assign clipping = 1'b0;
    end
    // then handle the franctional bits by truncating LSBs or padding zeros
    if (inqw >= outqw) assign out.val = $signed(tmp2[tmp2w-1-:outw]);
    else assign out.val = $signed({tmp2, (outqw - inqw)'('b0)});
  end

endmodule
