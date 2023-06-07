"""
# DAC53608 Buffered Voltage Output DAC


## Power Supply and Logic Levels

VDD must not exceed 6V.
VREF and DAC_SCL/DAC_SDA must not exceed VDD + 0.3V  [DAC53608, 7.1, p4].

This design uses 5V VDD and VREF.

Logic high (VIH) is 2.4V for 5V VDD [DAC53608, 7.3, p4].

VIO and DAC_VIO must not exceed 4V [SLAU790A, Table 4, p7], [TCA9800, 7.1, p4].

This design uses 3.3V VIO and DAC_VIO to interface to the R'Pi 3.3V GPIO.


## I2C Addressing

    Address   A0
    1001 000  GND
    1001 001  VDD
    1001 010  SDA
    1001 011  SCL

[DAC53608, Table 3, p26]


## LDACz and CLRz

This design uses asynchronous mode, LDACz = 0V [DAC53608, 8.3.1.2 p20].

DAC53608EVM has a 10k pull-down (R1) on LDACz [SLAU790A, p23],

This design does not use the CLR pin, CLR = 5V [DAC53608, 8.3.1.3 p20].



## Wiring to Raspberry Pi

                     ┌─────────────────────┐
                     │     DAC53608EVM     │
                     │                     │
                  5V │ ■ VDD         GND ■ │ GND
      GND, 5V or SCL │ ■ A0         CLRz ■ │ 5V
                     │ ■ LDACz      _NC_ ■ │
    R'Pi GPIO 3 (SC) │ ■ SCL         SDA ■ │ R'Pi GPIO 2 (SD)
                     │ ■ VREF       AIO0 ■ │
                     │ ■ REFGND     AIO2 ■ │
                     │ ■ AIO1    DAC_VIO ■ │ 3.3V
                     │ ■ AIO3        VIO ■ │ 3.3V
                     │ ■ _NC_       _NC_ ■ │
                     │ ■ _NC_       _NC_ ■ │
                     │ ■ AIO5       AIO4 ■ │
                     │ ■ AIO7       AIO6 ■ │
                     │ ■ AGND       AGND ■ │
                     │ ■ AGND       AGND ■ │
                     │ ■ ANGD       AGND ■ │
                     │ ■ AGND       AGND ■ │
                     └─────────────────────┘


## References

DAC53608: Octal Buffered Voltage Output DACs
https://www.ti.com/lit/ds/symlink/dac53608.pdf

SLAU790A: DAC53608 Evaluation Module
https://www.ti.com/lit/ug/slau790a/slau790a.pdf

TCA9800: TCA9800 Level-Translating I2C Bus Buffer
https://www.ti.com/lit/ds/symlink/tca9800.pdf
"""
module PiDAC53608

export DAC53608
export dac_open

using PiGPIOC
import PiGPIOC.gpioInitialise
import PiGPIOC.i2cOpen
import PiGPIOC.i2cReadWordData
import PiGPIOC.i2cWriteWordData
# See http://abyz.me.uk/rpi/pigpio/cif.html

const DAC_CONFIG_REGISTER = 0b0001                  # [DAC53608, Table 7, p28]
const DAC_STATUS_REGISTER = 0b0010                  # [DAC53608, Table 7, p28]
const DAC_DATA_REGISTER   = 0b1000                  # [DAC53608, Table 7, p28]
const DAC_DEVICE_ID = UInt16(0b001100) << 6         # [DAC53608, Table 11, p29]

struct DAC53608 <: AbstractChannel{UInt16}
    i2c::Cint
end

"""
    dac = dac_open(;bus=1, address=0b1001_0000)::DAC53608
    dac[c] = v

Connect to DAC53608 at `address` on i2c `bus`.
Set AIO`x` to `v`.
"""
function dac_open(;bus=1, address=0b1001_000)

    @assert bus >= 0

    res = gpioInitialise()
    @assert(res != PiGPIOC.PI_INIT_FAILED)

    i2c = i2cOpen(bus, address, 0)
    @assert i2c >= 0

    dac = DAC53608(i2c)
    x = dac_read(dac, DAC_STATUS_REGISTER)
    @assert x == DAC_DEVICE_ID
    dac_power_on(dac)
    dac
end


"""
    dac_power_on(::DAC53608)

Clear PDN [DAC53608, Table 10, p29].
"""
function dac_power_on(dac::DAC53608)
    dac_write(dac, DAC_CONFIG_REGISTER, 0)
    x = dac_read(dac, DAC_CONFIG_REGISTER)
    @assert x == 0
    nothing
end


"""
    dac_write(::DAC53608, register, value)

Write 16-bit `value` to `register`.
"""
function dac_write(dac, register, v)
    @assert register in 1:3 || register in 0b1000:0b1111
    err = i2cWriteWordData(dac.i2c, register, bswap(UInt16(v)))
    @assert err == 0
    nothing
end


"""
    dac_read(::DAC53608, register))

Read 16-bit value from `register`.
"""
function dac_read(dac, register)
    @assert register in 1:3 || register in 0b1000:0b1111
    n = i2cReadWordData(dac.i2c, register)
    if n < 0
        @error "dac_read register:$register = $n !"
    end
    @assert n >= 0
    bswap(UInt16(n))
end


"""
    setindex!(::DAC53608, x, v)

Set AIO`x` to `v`.
"""
function Base.setindex!(dac::DAC53608, v, x)
    @assert x in 0:7 "DAC53608 input AIO`x` must be in range 0:7"
    @assert 0 <= v <= 5 "DAC53608 input `v` must be in range 0:5V"
    vi = round(UInt16, (v * 0x3ff) / 5) << 2
    r = DAC_DATA_REGISTER | x
    dac_write(dac, r, vi)
    nothing
end


# Documentation.

readme() = join([
    Docs.doc(@__MODULE__),
    Docs.doc(dac_open),
    Docs.doc(dac_power_on),
   ], "\n\n")


end # module
