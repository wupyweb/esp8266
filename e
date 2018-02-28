#include <aJSON.h>
#include <dht11.h>
dht11 DHT;
#define DHT11_PIN 4
String DEVICEID="1203"; // 你的设备ID=======
String APIKEY="1ff00d6fb"; // 设备密码==
String INPUTID1="1165";
String INPUTID2="1166";
unsigned long lastCheckInTime = 0; //记录上次报到时间
unsigned long lastUpdateTime = 0;//记录上次上传数据时间
const unsigned long postingInterval = 40000; // 每隔40秒向服务器报到一次
const unsigned long updateInterval = 5000; // 数据上传间隔时间5秒
String inputString = "";//串口读取到的内容
boolean stringComplete = false;//串口是否读取完毕
boolean CONNECT = true; //连接状态
boolean isCheckIn = false; //是否已经登录服务器
char* parseJson(char *jsonString);//定义aJson字符串
void setup() {
  Serial.begin(115200);
  delay(10000);
}
void loop() {
  if(millis() - lastCheckInTime > postingInterval || lastCheckInTime==0) {
    checkIn();
  }
  if((millis() - lastUpdateTime > updateInterval) && isCheckIn) {
    float temp,humi;//定义变量
    int dat;//定义变量
    dat = DHT.read(DHT11_PIN);
    temp=DHT.temperature;
    humi=DHT.humidity;
    update2(DEVICEID,INPUTID1,temp,INPUTID2,humi);
  }
  serialEvent();
    if (stringComplete) {
      inputString.trim();
      //Serial.println(inputString);
      if(inputString=="CLOSED"){
        Serial.println("connect closed!");
        CONNECT=false;   
        isCheckIn=false;     
      }else{
        int len = inputString.length()+1;    
        if(inputString.startsWith("{") && inputString.endsWith("}")){
          char jsonString[len];
          inputString.toCharArray(jsonString,len);
          aJsonObject *msg = aJson.parse(jsonString);
          processMessage(msg);//处理接收到的Json数据
          aJson.deleteItem(msg);          
        }
      }      
      inputString = "";
      stringComplete = false;
  }
}
void checkIn() {
  if (!CONNECT) {
    Serial.print("+++");
    delay(500);  
    Serial.print("\r\n"); 
    delay(1000);
    Serial.print("AT+RST\r\n"); 
    delay(6000);
    CONNECT=true;
    lastCheckInTime==0;
  }
  else{
    Serial.print("{\"M\":\"checkin\",\"ID\":\"");
    Serial.print(DEVICEID);
    Serial.print("\",\"K\":\"");
    Serial.print(APIKEY);
    Serial.print("\"}\r\n");
    lastCheckInTime = millis();
  }
}
void processMessage(aJsonObject *msg){
  aJsonObject* method = aJson.getObjectItem(msg, "M");
  aJsonObject* content = aJson.getObjectItem(msg, "C");     
  aJsonObject* client_id = aJson.getObjectItem(msg, "ID");  
  //char* st = aJson.print(msg);
  if (!method) {
    return;
  }
    //Serial.println(st); 
    //free(st);
    String M=method->valuestring;
    if(M=="checkinok"){
      isCheckIn = true;
    }
}
void serialEvent() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    inputString += inChar;
    if (inChar == '\n') {
      stringComplete = true;
    }
  }
}

void update2(String did, String inputid1, float value1, String inputid2, float value2){
  Serial.print("{\"M\":\"update\",\"ID\":\"");
  Serial.print(did);
  Serial.print("\",\"V\":{\"");
  Serial.print(inputid1);
  Serial.print("\":\"");
  Serial.print(value1);
  Serial.print("\",\"");
  Serial.print(inputid2);
  Serial.print("\":\"");
  Serial.print(value2);
  Serial.println("\"}}");
  lastCheckInTime = millis();
  lastUpdateTime= millis(); 
}
