# nenetalk - a dumb I2C to serial arduino sketch

an example for how the serial communications works on nenemark2. more implementations will come in the future.  

## Protocol

The arduino serves as a I2C peripheral, nenemark2 is the host.  
All communications are on I2C address 0 (7-bit mask).  
nenemark2 sends a byte that the arduino passes on the serial line.  
it does also request periodically for incoming data, that the arduino responds with either:  
- a single 0x00, meaning no data is available
- the magic number 0x5A, followed by a single byte of data that has been sent from the serial line
