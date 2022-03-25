{
  Proj          : Comm2Control.spin
  Platform      : Parallax Project USB Board
  Rev           : 0.50
  Author        : Mok ST Sonia
  Date          : 24/02/2022

  Log :
                25/03/2022      1.00                    operation w/ chksum
                06/03/2022      0.75                    edit
                24/02/2022      0.50                    pseudocode version
}

CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000
        _conclkfreq = ((_clkmode - xtal1) >> 6) + _xinfreq                     'comment out if incorporated into main prog
        _ms001 = _conclkfreq / 1_000

        commtx    = 19
        commrx    = 18
        commbaud  = 115200

        commhead  = $7A
        commkey   = $7F

        commACK   = $AA                                   'ack
        commERR   = $EE                                   'err

        'dir
        stp       = $01

        fwd       = $11
        bkd       = $12
        ccw       = $18
        ckw       = $19

        lsf       = $20
        dfl       = $21
        dbl       = $22
        cfl       = $28
        cbl       = $29

        rsf       = $30
        dfr       = $31
        dbr       = $32
        cfr       = $38
        cbr       = $39

VAR
  'core var
  long  cgComm, corestk[128]
  'long  _ms001

  'global var


  'private var
  long cs

OBJ
  comm      : "FullDuplexSerial.spin"
  term      : "FullDuplexSerial.spin"

PUB init(mainMS, pDir, pSpd)

  '_ms001 := mainMS

  Stop                          'Stop running core first to refresh

  cgComm := cognew(instr(pDir, pSpd), @corestk) + 1

  return

PUB Stop

  if cgComm > 0
    cogstop(cgComm~)

  return

PUB instr(pDir, pSpd) | ctHead, ctDir, ctSpd, ctCS

  term.Start(31, 30, 0, 115200)
  comm.start(commrx, commtx, 0, commbaud)
  pause(3000)

  repeat
    ctHead := comm.rxcheck
    'term.Str(String(13, "reading val"))
      if(ctHead == commHead)

        ctDir := comm.rxcheck
        term.Str(String(13, "dir recieved : "))
        term.dec(ctDir)
        ctSpd := comm.rxcheck
        term.Str(String(13, "spd recieved : "))'
        term.dec(ctSpd)
        ctcs := comm.rxcheck
        term.Str(String(13, "ct cs : "))
        term.dec(ctcs)

        cs := ((ctDir ^ ctSpd) ^ commKey)
        term.Str(String(13, "calc-ed cs : "))
        term.dec(cs)

        if(cs == ctcs)
          comm.tx(0)
          term.Str(String(13, "cfmed, ack"))
          long[pDir] := ctDir
          long[pSpd] := ctSpd

        else
          comm.tx(commERR)
      else
        comm.tx(commERR)

    pause(50)

PUB pause(ms) | t               'pause fn for util use
  t := cnt - 1088
  repeat (ms #> 0)
    waitcnt(t += _ms001)
  return