int incomingByte = 0;   // for incoming serial data

int cams[] = {6,9,10,11};

void setup() {
        Serial.begin(9600);     // opens serial port, sets data rate to 9600 bps
}

void loop() {

        // send data only when you receive data:
        if (Serial.available() > 0) {
                // read the incoming byte:
                incomingByte = Serial.read();

                for (int i = 0;i<sizeof(cams);i++) {
                  analogWrite(cams[i],0);
                }
                analogWrite(cams[incomingByte-49],128);

        }
}
 
