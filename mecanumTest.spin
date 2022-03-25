{
  Proj          : MecanumControl.spin
  Platform      : Parallax Project USB Board
  Rev           : 0.75
  Author        : Mok ST Sonia
  Date          : 18/02/2022

  Log :
                06/03/2022      1.00                    operation in conjunction with other sub-sys
                23/02/2022      0.75                    pseudo-incorporation into main program
                18/02/2022      0.50                    testing version
  }


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

        _conclkfreq = ((_clkmode - xtal1) >> 6) + _xinfreq                     'comment out if incorporated into main prog
        _ms001 = _conclkfreq / 1_000                                           'comment out this also

        'Pin and Baudrate asgnmnt

        'Roboclaw 1 - frt
        r1s1 = 3
        r1s2 = 2

        'Roboclaw 2 - bk=ck
        r2s1 = 5
        r2s2 = 4

        'Simple serial comm btw mtr driver and wheels
        SSBaud = 57_600

        'zero vals - accord. to fwd dir, r = right side, l = left side
        zr = 64
        zl = 192

        'spd for debug
        'spd = 10


VAR
  long  cgMtr, corestk[128]
  'long  _ms001

OBJ
  'UART init
  MD1   : "FullDuplexSerial.spin"
  MD2   : "FullDuplexSerial.spin"

PUB start(mainMS, mtrCmd, mtrSpd)                       'start new cog

  '_ms001 := mainMS                                      'main MS val from main prog

  cogstp                                                   'stop current cog if vals remain in running cog

  cgMtr := cognew(mtrInstruct(mtrCmd, mtrSpd), @corestk)'run new cog with this function @corestk

  return

PUB mtrInstruct(mtrCmd, mtrSpd)

  init                                                  'prep serial comm for driver ctrl

  repeat
    mtrSpd := 63 * (mtrspd/100)

    case LONG[mtrCmd]
      1:
        stp
      11:
        fwd(long[mtrSpd])
      12:
        bkd(long[mtrSpd])
      18:
        ccw(long[mtrSpd])
      19:
        ckw(long[mtrSpd])

      20:
        lsf(long[mtrSpd])
      21:
        dfl(long[mtrSpd])
      22:
        dbl(long[mtrSpd])
      28:
        cfl(long[mtrSpd])
      29:
        cbl(long[mtrSpd])

      30:
        rsf(long[mtrSpd])
      31:
        dfr(long[mtrSpd])
      32:
        dbr(long[mtrSpd])
      38:
        cfr(long[mtrSpd])
      39:
        cbr(long[mtrSpd])


{PUB main | i                                            'debug

  init

  'test stp, fwd and rvs vals
  repeat
    ckw(25)
    pause(50000)
    stp
    pause(10000)
    ccw(25)
    pause(50000)
    stp
    pause(10000)
    fwd(25)
    pause(50000)
    stp
    pause(10000)
    bkd(25)
    pause(50000)
    stp
    pause(10000)
    dfl(25)
    pause(50000)
    stp
    pause(10000)
    dbl(25)
    pause(50000)
    stp
    pause(10000)
    dfr(25)
    pause(50000)
    stp
    pause(10000)
    dbr(25)
    pause(50000)
    stp
    pause(10000)
    lsf(25)
    pause(50000)
    stp
    pause(10000)
    rsf(25)
    pause(50000)
    stp
    pause(10000)

 }
  'TODO - check why the pause ms val +1 x 10


PUB cogstp                                              'cogstop

  if cgMtr > 0
    cogstop(cgMtr~)

PUB init

  'initialisation
  MD1.start(r1s2, r1s1, 0, SSBaud)
  MD2.start(r2s2, r2s1, 0, SSBaud)

PUB stp 'stop

  MD1.tx(zr)
  MD1.tx(zl)
  MD2.tx(zr)
  MD2.tx(zl)

PUB fwd(spd)                    'forward

  MD1.tx(zr+spd)
  MD1.tx(zl+spd)
  MD2.tx(zr+spd)
  MD2.tx(zl+spd)

PUB bkd(spd)                    'backward

  MD1.tx(zr-spd)
  MD1.tx(zl-spd)
  MD2.tx(zr-spd)
  MD2.tx(zl-spd)

PUB lsf(spd)                    'left strafe

  MD1.tx(zr-spd)
  MD1.tx(zl+spd)
  MD2.tx(zr+spd)
  MD2.tx(zl-spd)

PUB rsf(spd)                    'right strafe

  MD1.tx(zr+spd)
  MD1.tx(zl-spd)
  MD2.tx(zr-spd)
  MD2.tx(zl+spd)

PUB dfl(spd)                    'diagonal front left

  MD1.tx(zr)
  MD1.tx(zl+spd)
  MD2.tx(zr+spd)
  MD2.tx(zl)

PUB dfr(spd)                    'diagonal front right

  MD1.tx(zr+spd)
  MD1.tx(zl)
  MD2.tx(zr)
  MD2.tx(zl+spd)

PUB dbl(spd)                    'diagonal back left

  MD1.tx(zr)
  MD1.tx(zl-spd)
  MD2.tx(zr-spd)
  MD2.tx(zl)

PUB dbr(spd)                    'diagonal back right

  MD1.tx(zr-spd)
  MD1.tx(zl)
  MD2.tx(zr)
  MD2.tx(zl-spd)

PUB ccw(spd)                    ' counter-clockwise

  MD1.tx(zr+spd)
  MD1.tx(zl-spd)
  MD2.tx(zr+spd)
  MD2.tx(zl-spd)

PUB ckw(spd)                    'clockwise

  MD1.tx(zr-spd)
  MD1.tx(zl+spd)
  MD2.tx(zr-spd)
  MD2.tx(zl+spd)

PUB cfl(spd)                    'corner front left

  MD1.tx(zr+spd)
  MD1.tx(zl)
  MD2.tx(zr+spd)
  MD2.tx(zl)

PUB cfr(spd)                    'corner front right

  MD1.tx(zr)
  MD1.tx(zl+spd)
  MD2.tx(zr)
  MD2.tx(zl+spd)

PUB cbl(spd)                    'corner back left

  MD1.tx(zr-spd)
  MD1.tx(zl)
  MD2.tx(zr-spd)
  MD2.tx(zl)

PUB cbr(spd)                    'corner back right

  MD1.tx(zr)
  MD1.tx(zl-spd)
  MD2.tx(zr)
  MD2.tx(zl-spd)

PRI pause(ms) | t
  t := cnt - 1088
  repeat (ms #> 0)
    waitcnt(t += _ms001)