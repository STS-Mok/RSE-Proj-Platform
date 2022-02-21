{
  Proj          : MecanumControl.spin
  Platform      : Parallax Project USB Board
  Rev           : 0.5
  Author        : Mok ST Sonia
  Date          : 18/02/2022

  Log :
                18/02/2022      testing version
  }


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

        _conclkfreq = ((_clkmode - xtal1) >> 6) + _xinfreq
        _ms001 = _conclkfreq / 1_000

        'Pin and Baudrate asgnmnt

        'Roboclaw 1
        r1s1 = 3
        r1s2 = 2

        'Roboclaw 2
        r2s1 = 5
        r2s2 = 4

        'Simple serial
        SSBaud = 57_600

        'zero vals
        zr = 64
        zl = 192

        'spd for debug
        'spd = 10


VAR
  long  symbol

OBJ
  'UART init
  MD1   : "FullDuplexSerial.spin"
  MD2   : "FullDuplexSerial.spin"

PUB main | i

  init

  'test stp, fwd and rvs vals
  repeat
    cfl(25)
    pause(50000)
    stp
    pause(10000)
    cbl(25)
    pause(50000)
    stp
    pause(10000)
    cfr(25)
    pause(50000)
    stp
    pause(10000)
    cbrs(25)
    pause(50000)
    stp
    pause(10000)

  'TODO - check why the pause ms val +1 x 10

PUB init

  'initialisation
  MD1.start(r1s2, r1s1, 0, SSBaud)
  MD2.start(r2s2, r2s1, 0, SSBaud)

PUB stp

  MD1.tx(zr)
  MD1.tx(zl)
  MD2.tx(zr)
  MD2.tx(zl)

PUB fwd(spd)

  MD1.tx(zr+spd)
  MD1.tx(zl+spd)
  MD2.tx(zr+spd)
  MD2.tx(zl+spd)

PUB bkd(spd)

  MD1.tx(zr-spd)
  MD1.tx(zl-spd)
  MD2.tx(zr-spd)
  MD2.tx(zl-spd)

PUB lsf(spd)

  MD1.tx(zr-spd)
  MD1.tx(zl+spd)
  MD2.tx(zr+spd)
  MD2.tx(zl-spd)

PUB rsf(spd)

  MD1.tx(zr+spd)
  MD1.tx(zl-spd)
  MD2.tx(zr-spd)
  MD2.tx(zl+spd)

PUB dfl(spd)

  MD1.tx(zr)
  MD1.tx(zl+spd)
  MD2.tx(zr+spd)
  MD2.tx(zl)

PUB dfr(spd)

  MD1.tx(zr+spd)
  MD1.tx(zl)
  MD2.tx(zr)
  MD2.tx(zl+spd)

PUB dbl(spd)

  MD1.tx(zr)
  MD1.tx(zl-spd)
  MD2.tx(zr-spd)
  MD2.tx(zl)

PUB dbr(spd)

  MD1.tx(zr-spd)
  MD1.tx(zl)
  MD2.tx(zr)
  MD2.tx(zl-spd)

PUB ccw(spd)

  MD1.tx(zr+spd)
  MD1.tx(zl-spd)
  MD2.tx(zr+spd)
  MD2.tx(zl-spd)

PUB ckw(spd)

  MD1.tx(zr-spd)
  MD1.tx(zl+spd)
  MD2.tx(zr-spd)
  MD2.tx(zl+spd)

PUB cfl(spd)

  MD1.tx(zr+spd)
  MD1.tx(zl)
  MD2.tx(zr+spd)
  MD2.tx(zl)

PUB cfr(spd)

  MD1.tx(zr)
  MD1.tx(zl+spd)
  MD2.tx(zr)
  MD2.tx(zl+spd)

PUB cbl(spd)

  MD1.tx(zr-spd)
  MD1.tx(zl)
  MD2.tx(zr-spd)
  MD2.tx(zl)

PUB cbr(spd)

  MD1.tx(zr)
  MD1.tx(zl-spd)
  MD2.tx(zr)
  MD2.tx(zl-spd)

PRI pause(ms) | t
  t := cnt - 1088
  repeat (ms #> 0)
    waitcnt(t += _ms001)
  return