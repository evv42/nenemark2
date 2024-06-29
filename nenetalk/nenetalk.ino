#include <Wire.h>
#include <avr/power.h>

void handle_rx_data(){
  while(Wire.available()){
    uint8_t d = Wire.read();//read a byte from i2c
    Serial.write(d);//send it over serial
    Serial.flush();
  }  
}

void handle_tx_request(){
    int sr = Serial.read();
    if(sr == -1){
      Wire.write(0x00);//if we have nothing to send we send a zero
    }else{
      Wire.write(0x5A);//if we have a thing to send, we send a magic number
      Wire.write(sr);//followed by the byte
    }
}

void setup() {
  // disable some useless stuff
  ADCSRA = 0;  
  power_spi_disable();

  // all the magic happens here
  Serial.begin(19200);
  Wire.begin(0x00);
  Wire.onReceive(handle_rx_data);
  Wire.onRequest(handle_tx_request);
}

void loop() {
  // nothing here
}
