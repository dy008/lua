require("LeweiTcpClient")

LeweiTcpClient.init("03","dab6a862154c4ebfab05b845eb4b5652")

function test(p1)
   print("switch01--"..p1)
   if (p1 == '0') then gpio.write(0, gpio.HIGH)
     else gpio.write(0, gpio.LOW) end
end

function test2(p1)
   print("switch02--"..p1)
   if (p1 == '0') then gpio.write(4, gpio.HIGH)
     else gpio.write(4, gpio.LOW) end
end

LeweiTcpClient.addUserSwitch(test,"switch01",1)
LeweiTcpClient.addUserSwitch(test2,"switch02",1)

local disp
function init_OLED(sda,scl) --Set up the u8glib lib
     sla = 0x3c
     i2c.setup(0, sda, scl, i2c.SLOW)
     disp = u8g.ssd1306_128x64_i2c(sla)
     disp:setFont(u8g.font_6x10)
     disp:setFontRefHeightExtendedText()
     disp:setDefaultForegroundColor()
     disp:setFontPosTop()
end
init_OLED(5,6) --Run setting up

local sensorId
if(_G["sensorId"] ~= nil) then sensorId = _G["sensorId"]
else sensorId = "dust"
end

local pm25 = 15
local Hum = nil
local Temp = nil

function setTimer()
     tmr.alarm(0, 60000, 0, function()
          local si7021 = require("si7021")
          
          SDA_PIN = 5 -- sda pin, GPIO12
          SCL_PIN = 6 -- scl pin, GPIO14
          
          si7021.init(SDA_PIN, SCL_PIN)
          si7021.read(OSS)
          Hum = si7021.getHumidity()
          Temp = si7021.getTemperature()
          print(Hum)
          print(Temp)
          -- release module
          pm25 = 15
          si7021 = nil
          _G["si7021"]=nil
               if(pm25 ~=nil) then 
               if(Temp~=nil) then LeweiTcpClient.appendSensorValue("T1",Temp)  end
               if(Hum~=nil) then LeweiTcpClient.appendSensorValue("H1",Hum) end
               LeweiTcpClient.sendSensorValue(sensorId,pm25) 
               setTimer()
               end
     end)
end

setTimer()

disp:firstPage()
repeat
disp:drawFrame(15,15,100,25) 
disp:drawStr(25,25,"PM2.5 Detector") 
disp:drawStr(20,50,"www.lewei50.com") 
until disp:nextPage() == false 

--[[
tmr.alarm(1,5000,tmr.ALARM_AUTO, function()  --每5秒采集一次环境数据
     uart.alt(1)     --将uart通信切换到外部引脚 GPIO13 and GPIO15（D8-TX，D7-RX）
     uart.setup(0, 9600, 8, 0, 1, 0)  
     uart.on("data", 30,function(data)
          uart.alt(0)     --切回原来的引脚
          uart.setup(0, 115200, 8, 0, 1, 0)
          print("recived--"..#data)

          if((string.byte(data,1)==0x42) and (string.byte(data,2)==0x4d))  then
          pm25 = (string.byte(data,13)*256+string.byte(data,14))

          uart.on("data") -- unregister callback function

          local si7021 = require("si7021")
          
          SDA_PIN = 5 -- sda pin, GPIO12
          SCL_PIN = 6 -- scl pin, GPIO14
          
          si7021.init(SDA_PIN, SCL_PIN)
          si7021.read(OSS)
          Hum = si7021.getHumidity()
          Temp = si7021.getTemperature()
          print(Hum)
          print(Temp)
          -- release module
          si7021 = nil
          _G["si7021"]=nil
           disp:firstPage()
           repeat
               disp:drawStr(10,20,"PM2.5:"..pm25.." ug/m3") 
               disp:drawStr(10,40,"Temp:"..Temp.."'C") 
               disp:drawStr(10,50,"Humi:"..Hum.."%")         
           until disp:nextPage() == false  
          end
          uart.on("data") -- unregister callback function

     end, 0)

end)


uart.setup( 0, 9600, 8, 0, 1, 0 )
uart.on("data", 0, 
 function(data)
     if((string.len(data)==32) and (string.byte(data,1)==0x42) and (string.byte(data,2)==0x4d))  then
          pm25 = (string.byte(data,13)*256+string.byte(data,14))
          --socket:send(pm25..'\n\r')    
          local si7021 = require("si7021")
          
          SDA_PIN = 5 -- sda pin, GPIO12
          SCL_PIN = 6 -- scl pin, GPIO14
          
          si7021.init(SDA_PIN, SCL_PIN)
          si7021.read(OSS)
          Hum = si7021.getHumidity()
          Temp = si7021.getTemperature()
          --print(Hum)
          --print(Temp)
          -- release module
          si7021 = nil
          _G["si7021"]=nil
           disp:firstPage()
           repeat
               disp:drawStr(10,20,"PM2.5:"..pm25.." ug/m3") 
               disp:drawStr(10,40,"Temp:"..Temp.."'C") 
               disp:drawStr(10,50,"Humi:"..Hum.."%")         
           until disp:nextPage() == false  
     end
end, 0)
]]
