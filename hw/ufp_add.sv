module ufp_add (
    ufp_if.in  x,
    ufp_if.in  y,
    ufp_if.out sum
);
  assign sum.val = x.val + y.val;
endmodule
