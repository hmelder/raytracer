import numpy as np

IW = 16
QW = 16
WL = IW + QW

B = 2**16

# Get the most significant bit of the fixed-point value
def msb(fp: np.int32):
    return np.floor(np.log2(fp)).astype(np.int32) - QW

def initial_est(m: np.int32):
    return 1 / (np.sqrt(math.pow(2,m)) * 2**QW);

def initial_est2(m: np.int32):
    return (2**16) / (np.sqrt(math.pow(2,m)));

def goldschmidt(sfp: np.int32):
    m = msb(sfp)
    b_0 = sfp
    Y_0 = initial_est2(m)
    x_0 = (sfp * Y_0) / B
    y_0 = Y_0

    Y_i = Y_0
    x_i = x_0
    y_i = y_0
    b_i = b_0

    for _ in range(2):
        b_i = (b_i * (Y_i * Y_i)) / (B*B)
        Y_i = (3 * B - b_i) / 2
        x_i = (x_i * Y_i) / B
        y_i = (y_i * Y_i) / B

    return np.int32(y_i)
