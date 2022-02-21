{
  Proj:         commControl.spin
  Platform:     Parallax Project USB Board
  Rev:          1
  Author:       -
  Date:         19/11/2021
  Log:
        29/11/2021              Tribute to Kenichi Kato Edition (most prev code are commented out)
        19/11/2021              First version
}


CON
        {_clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000
        _ms001                  = _ConClkFreq / 1_000}

        commTxPin = 18
        commRxPin = 19
        commBaud  = 9600

        commSt  = $7A
        commFwd = $01
        commRvs = $02
        commL   = $03
        commR   = $04
        commStopAll = $AA


OBJ
  comm      : "FullDuplexSerial.spin"

VAR
  long cgComm, corestk[128]
  long _ms001

PUB init(mainMS, commCmd)

  _ms001 := mainMS

  Stop

  cgComm := cognew(instr(commCmd), @corestk)

  return

PUB Stop

  if cgComm > 0
    cogstop(cgComm~)

  return

PUB instr(commCmd) | rxVal

  comm.Start(commRxPin, commTxPin, 0, commBaud)
  Pause(3000)

  repeat
    rxVal := comm.Rx
    if(rxVal == commSt)
    repeat
      rxVal := comm.Rx    'debug mode: only fwd

      case rxVal
        commFwd:
          long[commCmd] := 1
        commRvs:
          long[commCmd] := 2
        commL:
          long[commCmd] := 3
        commR:
          long[commCmd] := 4
        commStopAll:
          long[commCmd] := 5
      pause(3000)

{PUB instrDebug(commCmd) | rxVal

  'comm.Start(commTxPin, commRxPin, 0, commBaud)
  'Pause(3000)

  repeat
    rxVal := $7A 'comm.RxCheck
    if(rxVal == commSt)
    repeat
      rxVal := $01 'comm.RxCheck    'debug mode: only fwd

      case rxVal
        commFwd:
          long[commCmd] := 1
        commRvs:
          long[commCmd] := 2
        commL:
          long[commCmd] := 3
        commR:
          long[commCmd] := 4
        commStopAll:
          long[commCmd] := 0
      pause(3000)}

PUB pause(ms) | t               'pause fn for util use
  t := cnt - 1088
  repeat (ms #> 0)
    waitcnt(t += _ms001)
  return