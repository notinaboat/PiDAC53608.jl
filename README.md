# DAC53608 Buffered Voltage Output DAC

## Power Supply and Logic Levels

VDD must not exceed 6V. VREF and DAC*SCL/DAC*SDA must not exceed VDD + 0.3V  [DAC53608, 7.1, p4].

This design uses 5V VDD and VREF.

Logic high (VIH) is 2.4V for 5V VDD [DAC53608, 7.3, p4].

VIO and DAC_VIO must not exceed 4V [SLAU790A, Table 4, p7], [TCA9800, 7.1, p4].

This design uses 3.3V VIO and DAC_VIO to interface to the R'Pi 3.3V GPIO.

## I2C Addressing

```
Address   A0
1001 000  GND
1001 001  VDD
1001 010  SDA
1001 011  SCL
```

[DAC53608, Table 3, p26]

## LDACz and CLRz

This design uses asynchronous mode, LDACz = 0V [DAC53608, 8.3.1.2 p20].

DAC53608EVM has a 10k pull-down (R1) on LDACz [SLAU790A, p23],

This design does not use the CLR pin, CLR = 5V [DAC53608, 8.3.1.3 p20].

## Wiring to Raspberry Pi

```
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
```

## References

DAC53608: Octal Buffered Voltage Output DACs https://www.ti.com/lit/ds/symlink/dac53608.pdf

SLAU790A: DAC53608 Evaluation Module https://www.ti.com/lit/ug/slau790a/slau790a.pdf

TCA9800: TCA9800 Level-Translating I2C Bus Buffer https://www.ti.com/lit/ds/symlink/tca9800.pdf


```
dac = dac_open(;bus=1, address=0b1001_0000)::DAC53608
dac[c] = v
```

Connect to DAC53608 at `address` on i2c `bus`. Set AIO`x` to `v`.


```
dac_power_on(::DAC53608)
```

Clear PDN [DAC53608, Table 10, p29].

