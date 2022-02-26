{
  Proj          : Comm2Control.spin
  Platform      : Parallax Project USB Board
  Rev           : 0.50
  Author        : Mok ST Sonia
  Date          : 24/02/2022

  Log :
                24/02/2022      0.50                    pseudocode version
}

CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000
        _conclkfreq = ((_clkmode - xtal1) >> 6) + _xinfreq                     'comment out if incorporated into main prog
        _ms001 = _conclkfreq / 1_000

        commtx    = 10                                                           'random assign, change when ready!
        commrx    = 11                                                           'this too
        commbaud  = 9600                                                         'and this
        commkey   = $7F
        commhead  = $7A

        commACK = $AA                                   'ack
        commERR = $EE                                   'err

VAR
  long  cgComm, corestk[128]
  'long  _ms001

  byte dir, spd, cs

OBJ
  comm      : "FullDuplexSerial.spin"

PUB init(mainMS, header, direction, speed, checksum)

  '_ms001 := mainMS

  Stop                          'Stop running core first to refresh

  cgComm := cognew(instr(header, direction, speed, checksum), @corestk)

  return

PUB Stop

  if cgComm > 0
    cogstop(cgComm~)

  return

PUB instr(cthead, ctDir, ctSpd, ctcs)

  comm.start(commrx, commtx, 0, commbaud)
  pause(3000)

  repeat
    ctHead := comm.rxcheck
      if(ctHead == commHead)
        ctDir := comm.rxcheck
        ctSpd := comm.rxcheck
        cs := ((ctDir ^ ctSpd) ^ commKey)
        ctcs := comm.rxcheck
        if(cs == ctcs)
          comm.tx(commACK)
          dir := ctDir
          spd := ctSpd
        else
          comm.tx(commERR)
      else
        comm.tx(commERR)

PUB pause(ms) | t               'pause fn for util use
  t := cnt - 1088
  repeat (ms #> 0)
    waitcnt(t += _ms001)
  return
