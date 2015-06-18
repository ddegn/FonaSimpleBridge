DAT programName         byte "FonaBridge", 0
CON
{{
  By Duane Degn
  June 18, 2015

  This program acts as bridge between Adafruit's FONA
  and Parallax Serial Terminal.exe (aka PST).
  
  This program using three of the Propeller's eight cogs.
  Two of the cogs are used to create software UARTs.
  One cog is used to manage these UARTs.

  Note: "Parallax Serial Terminal" can refer to both
  the terminal software which runs on the PC and the
  object used as a serial driver in a Spin program.
  The PC software is named "Parallax Serial Terminal.exe"
  and the Spin object is named "Parallax Serial Terminal.spin."
  
}}
{
  ******* Private Notes *******
  
}  
CON

  _clkmode = xtal1 + pll16x                           
  _xinfreq = 5_000_000

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MILLISECOND = CLK_FREQ / 1_000

  '' I/O pins
  TX_TO_FONA = 0                ' connects with RX on FONA
  RX_FROM_FONA = 1              ' connects with TX on FONA

  '' The FONA should be powered from a single cell LiPo battery. The ground
  '' of the FONA should be connected to the ground of the Propeller.
  '' 3.3V should be connected to the FONA's Vio pin.

  PST_BAUD = 115_200           
  FONA_BAUD = 9_600 

  END_OF_SMS_CHARACTER = "~"    ' This should a character not used by the FONA in normal communication.
  CONTROL_Z = 26                

  FONA_SERIAL_MODE = 0 '%1000
  
OBJ

  Pst : "Parallax Serial Terminal"
  Fona : "Parallax Serial Terminal"
  
PUB Start

  Pst.Start(PST_BAUD)
  Fona.StartRxTx(RX_FROM_FONA, TX_TO_FONA, FONA_SERIAL_MODE, FONA_BAUD)
    
  BridgeFona

PUB BridgeFona | inputCharacter, numberOfCharactersInBuffer

  repeat
    '' This first section of the loop checks for input from the terminal.
    '' If input is received it is passed on to the FONA.
    '' If the character defined by "END_OF_SMS_CHARACTER" is received
    '' a control-Z character will be substituted by the program.
    '' This is not a way to directly send a control-Z character
    '' from Parallax Serial Terminal.exe.
    
    numberOfCharactersInBuffer := Pst.RxCount
    if numberOfCharactersInBuffer
      repeat numberOfCharactersInBuffer
        inputCharacter := Pst.CharIn
        if inputCharacter == END_OF_SMS_CHARACTER
          inputCharacter := CONTROL_Z
        Fona.Char(inputCharacter)
        if inputCharacter == $0D ' Add a line feed character when a carriage return is received.
          Fona.Char($0A)         ' This step isn't really needed since the FONA will work fine
                                 ' with just a carriage return.
                                 
    '' This last section of the loop checks for input from the FONA.
    '' If input is received it is passed on to the terminal.
    '' Non-printable ASCII characters will be displayed as their
    '' hexadecimal value.
    
    numberOfCharactersInBuffer := Fona.RxCount
    if numberOfCharactersInBuffer
      repeat numberOfCharactersInBuffer
        inputCharacter := Fona.CharIn
        SafeTx(inputCharacter)

PRI SafeTx(localCharacter)

  if localCharacter => 32 and localCharacter =< "~"
    Pst.Char(localCharacter)
  elseif localCharacter == 0 ' this may need to be changed if monitoring raw data
                             ' "Parallax Serial Terminal" doesn't catch framing errors
                             ' so without this "elseif" line you can end up with a
                             ' bunch of zeros if a line is inactive. 
    return
  else
    Pst.Char("<") 
    Pst.Char("$")
    Pst.Hex(localCharacter, 2)
    Pst.Char(">")

  if localCharacter == $0D ' The hex value of carriage return characters will be displayed
    Pst.Char($0D)         ' and the carriage return will also be passed to the terminal.
                           ' This should improve the readablity of the output.
