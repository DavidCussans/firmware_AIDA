# -*- coding: utf-8 -*-
import uhal
from I2CuHal2 import I2CCore
import StringIO
import time

class CFA632:
    #Class to configure the CFA632 display

    def __init__(self, i2c, slaveaddr=0x2A):
        self.i2c = i2c
        self.slaveaddr = slaveaddr

    def test(self):
        print "Testing the display"
        return
    
    def writeSomething(self, i2ccmd):
        mystop= True
        print "Write to CFA632"
        print "\t", i2ccmd
        #myaddr= [int(i2ccmd)]
        self.i2c.write( self.slaveaddr, i2ccmd, mystop)
	return
	
class LCD09052:
    #Class to configure the LCD09052 display

    def __init__(self, i2c, slaveaddr=0x3A):
        self.i2c = i2c
        self.slaveaddr = slaveaddr

    def test(self):
        print "\tTesting display (LCD09052)"
        self.clear()
        self.setBrightness(0)
        time.sleep(0.2)
        self.setBrightness(250)
        time.sleep(0.2)
        self.setBrightness(0)
        time.sleep(0.2)
        self.setBrightness(250)
        for ipos in range(1, 18):
            self.writeChar(33)
            self.posCursor(1, ipos-1)
            time.sleep(0.1)
            self.writeChar(254)
        self.posCursor(2, 1)
        for ipos in range(1, 18):
            self.writeChar(33)
            self.posCursor(2, ipos-1)
            time.sleep(0.1)
            self.writeChar(254)
        return
        
    def clear(self):
    ### Clears the display and locates the curson on position (1,1), i.e. top left
        i2ccmd= [4]
        mystop= True
        self.i2c.write( self.slaveaddr, i2ccmd, mystop)
        
    def posCursor(self, line, pos):
    ### Position the cursor on a specific location
    ##  line can be 1 (top) or 2 (bottom)
    ##  pos can be [1, 16}
        if ((line==1) or (line==2) and (1 <= pos <= 16)):
            i2ccmd= [2, line, pos]
            mystop= True
            self.i2c.write( self.slaveaddr, i2ccmd, mystop)
        else:
            print "Cursor line can only be 1 or 2, position must be in range [1, 16]"
    
    
    def setBrightness(self, value= 250):
    ### Sets the brightness level of the backlight.
    ##  Value is an integer in range [0, 250]. 0= no light, 250= maximum light.
        if value < 0:
            print "setBrightness: minimum value= 0. Coherced to 0"
            value = 0
        if value > 250:
            print "setBrightness: maximum value= 250. Coherced to 250"
            value = 250
        i2ccmd= [7, value]
        mystop= True
        self.i2c.write( self.slaveaddr, i2ccmd, mystop)
        
    
    def writeChar(self, value):
    ### Writes a char in the current cursor position
    ##  The curso is then shifted right one position
    ##  value must be an integer corresponding to the ascii code of the character
        i2ccmd= [1, value]
        mystop= True
        self.i2c.write( self.slaveaddr, i2ccmd, mystop)
    
    def writeSomething(self, i2ccmd):
        mystop= True
        print "Write to LCD09052"
        print "\t", i2ccmd
        #myaddr= [int(i2ccmd)]
        self.i2c.write( self.slaveaddr, i2ccmd, mystop)
	return

