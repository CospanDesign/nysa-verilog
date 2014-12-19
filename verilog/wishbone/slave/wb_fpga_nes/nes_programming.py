#Written by: Holguer A Becerra.
#Based on Brian Bennett Visual C++ Code

import serial



SupportedProgRomBanks=2;
SupportedChrRomBanks=1;#

DbgPacketOpCodeEcho              = 0x00 # echo packet body back to debugger
DbgPacketOpCodeCpuMemRd          = 0x01 # read CPU memory
DbgPacketOpCodeCpuMemWr          = 0x02 # write CPU memory
DbgPacketOpCodeDbgHlt            = 0x03 # debugger break (stop execution)
DbgPacketOpCodeDbgRun            = 0x04 # debugger run (resume execution)
DbgPacketOpCodeCpuRegRd          = 0x05 # read CPU register
DbgPacketOpCodeCpuRegWr          = 0x06 # read CPU register
DbgPacketOpCodeQueryHlt          = 0x07 # query if the cpu is currently halted
DbgPacketOpCodeQueryErrCode      = 0x08 # query NES error code
DbgPacketOpCodePpuMemRd          = 0x09 # read PPU memory
DbgPacketOpCodePpuMemWr          = 0x0A # write PPU memory
DbgPacketOpCodePpuDisable        = 0x0B # disable PPU
DbgPacketOpCodeCartSetCfg        = 0x0C # set cartridge config from iNES header

CpuRegPcl = 0x00# PCL: Program Counter Low
CpuRegPch = 0x01# PCH: Program Counter High
CpuRegAc  = 0x02# AC:  Accumulator reg
CpuRegX   = 0x03# X:   X index reg
CpuRegY   = 0x04# Y:   Y index reg
CpuRegP   = 0x05# P:   Processor Status reg
CpuRegS   = 0x06# S:   Stack Pointer reg

#addr,      // memory address to write
#numBytes,  // number of bytes to write
#pData     // data to write

send_data='';



ser = serial.Serial();

ser.port = "com5"
ser.baudrate = 38400;
ser.bytesize = serial.EIGHTBITS #number of bits per bytes
ser.parity = serial.PARITY_ODD #set parity check: no parity
ser.stopbits = serial.STOPBITS_ONE #number of stop bits



ser.open();


def send_byte(data):
    ser.write(chr(data));
    return 0;

    

rom=open('roms/wild_gun_man.nes','rb');
header=rom.read(4);
print header
if(header=='NES\x1a'):
    print 'Reading valid rom';
else:
    print 'Not valid NES ROM.. Sorry';
    exit(1)

    
progRomBanks= rom.read(1);
chrRomBanks= rom.read(1);
progRomBanks=ord(progRomBanks)
chrRomBanks=ord(chrRomBanks)

print 'progRomBanks=' + str(progRomBanks)
print 'chrRomBanks=' + str(progRomBanks)


if(progRomBanks>SupportedProgRomBanks or chrRomBanks>SupportedChrRomBanks):
    print 'Too many ROM Banks\nYou should try yo expand the memory to UxROM on the FPGA'
    exit(1)

Flag6=ord(rom.read(1));
Flag7=ord(rom.read(1));
Flag7_1=ord(rom.read(1));

if (Flag6 & 0x08):
    print "Only horizontal and vertical mirroring are supported."
    exit(1)

if(Flag6 & 0x04):
    print 'SRAM at 6000-7FFFh battery backed.  Yes'
else:
    print 'SRAM at 6000-7FFFh battery backed.  No'

if(Flag6 & 0x02):    
    print '512 byte trainer at 7000-71FFh'
else:
    print 'no trainer present'

if(Flag6 & 0x01):    
    print 'Four screen mode Yes'
else:
    print 'Four screen mode No'

if ((((Flag6 & 0xF0) >> 4)| (Flag7 & 0xF0)) != 0):
    print "Only mapper 0 is supported.";
    exit(1)
            
#debugger break (stop execution)
send_byte(DbgPacketOpCodeDbgHlt);


#disable PPU
send_byte(DbgPacketOpCodePpuDisable);

#Set iNES header info to configure mappers.
#send    DbgPacketOpCodePpuDisable
#send    progRomBanks
#send    chrRomBanks
#send    Flag6
#send    Flag7
#send    Flag7_1

print 'Set iNES header info to configure mappers.'
send_byte(DbgPacketOpCodeCartSetCfg);
send_byte(progRomBanks);
send_byte(chrRomBanks);
send_byte(Flag6);
send_byte(Flag7);
send_byte(Flag7_1);


#math size of banks    
prgRomDataSize    = progRomBanks * 0x4000;
chrRomDataSize    = chrRomBanks * 0x2000;
totalBytes        = prgRomDataSize + chrRomDataSize;
transferBlockSize = 0x400;


#copy PRG ROM data
_i=0
prgRomOffset=0;
while(_i<(prgRomDataSize / transferBlockSize)):
    prgRomOffset = transferBlockSize * _i;
    rom.seek(16+prgRomOffset)
    m_pData=''
    m_pData = m_pData +chr(DbgPacketOpCodeCpuMemWr);
    m_pData = m_pData + chr((0x8000 + prgRomOffset) & 0xff);
    m_pData = m_pData +chr(((0x8000 + prgRomOffset) & 0xff00)>>8);
    m_pData = m_pData +chr(transferBlockSize & 0xff);
    m_pData = m_pData +chr((transferBlockSize & 0xff00)>>8);
    send_data=rom.read(transferBlockSize);
    m_pData=m_pData+send_data
    ser.flushOutput()
    ser.write(m_pData)
    print '->Programming PRG ROM ADDR ' + hex(0x8000 + prgRomOffset)
    _i=_i+1;

    
#copy CHR ROM data
_i=0;
while(_i<(chrRomDataSize / transferBlockSize)):
    chrRomOffset = transferBlockSize * _i;
    rom.seek(16+prgRomDataSize+chrRomOffset)
    m_pData=''
    m_pData = m_pData +chr(DbgPacketOpCodePpuMemWr);
    m_pData = m_pData + chr((chrRomOffset) & 0xff);
    m_pData = m_pData +chr(((chrRomOffset) & 0xff00)>>8);
    m_pData = m_pData +chr(transferBlockSize & 0xff);
    m_pData = m_pData +chr((transferBlockSize & 0xff00)>>8);
    send_data=rom.read(transferBlockSize);
    m_pData=m_pData+send_data
    ser.flushOutput();
    ser.write(m_pData)
    print '->Programming CHR ROM ADDR ' + hex(chrRomOffset)
    _i=_i+1;

# Update PC to point at the reset interrupt vector location.
rom.seek(16+prgRomDataSize - 4)
pclVal = rom.read(1);
rom.seek(16 + prgRomDataSize - 3)
pchVal = rom.read(1);

print 'Update PC to point at the reset interrupt vector location'
m_pData ='';
m_pData = m_pData+ chr(DbgPacketOpCodeCpuRegWr);
m_pData = m_pData+ chr(CpuRegPcl);
m_pData = m_pData+ pclVal;    
ser.write(m_pData)


m_pData ='';
m_pData = m_pData+ chr(DbgPacketOpCodeCpuRegWr);
m_pData = m_pData+ chr(CpuRegPch);
m_pData = m_pData+ pchVal;    
ser.write(m_pData)

# Issue a debug run command.
print 'sending run command'
send_byte(DbgPacketOpCodeDbgRun);

rom.close()
ser.close()
