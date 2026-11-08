#include <SPI.h>
#include <MFRC522.h>
#include <DHT.h>
#include <ESP32Servo.h>

const uint8_t PIN_LUZ_1 = 15;
const uint8_t PIN_LUZ_2 = 16;
const uint8_t PIN_LUZ_3 = 17;
const uint8_t PIN_PUERTA = 14;
const uint8_t PIN_RFID_SS = 5;
const uint8_t PIN_RFID_RST = 22;
const uint8_t PIN_LED_VERDE = 32;
const uint8_t PIN_LED_AMARILLO = 33;
const uint8_t PIN_LED_ROJO = 25;
const uint8_t PIN_SERVO = 2;
const uint8_t PIN_BOTON_INTERIOR = 12;
const uint8_t PIN_DHT = 4;
const uint8_t PIN_BUZZER = 13;

const uint32_t VELOCIDAD_SERIAL = 115200;
const uint32_t INTERVALO_DHT_MS = 2500;
const uint32_t DEBOUNCE_MS = 40;
const uint32_t DURACION_DESBLOQUEO_MS = 3500;
const uint32_t RFID_COOLDOWN_MS = 1200;
const int ANGULO_CIERRE_SERVO = 0;
const int ANGULO_ABIERTO_SERVO = 90;

MFRC522 rfid(PIN_RFID_SS, PIN_RFID_RST);
DHT dht(PIN_DHT, DHT22);
Servo cerradura;

bool luces[3] = {false, false, false};
bool cerraduraAbierta = false;
uint32_t desbloqueoEmpezo = 0;
uint32_t ultimoDht = 0;
uint32_t ultimoRfid = 0;
uint32_t ultimaPuerta = 0;
uint32_t ultimoBoton = 0;
bool ultimaLecturaBoton = HIGH;
bool estadoBoton = HIGH;
bool ultimoEstadoPuerta = HIGH;
bool estadoPuerta = HIGH;
String lineaComando;

void enviarMensaje(const String &mensaje) {
  Serial.println(mensaje);
}
void cambiarEstadoLeds(bool verde, bool amarillo, bool rojo) {
  digitalWrite(PIN_LED_VERDE, verde ? HIGH : LOW);
  digitalWrite(PIN_LED_AMARILLO, amarillo ? HIGH : LOW);
  digitalWrite(PIN_LED_ROJO, rojo ? HIGH : LOW);
}
void beep(uint16_t frecuencia, uint16_t duracion) {
  tone(PIN_BUZZER, frecuencia, duracion);
}
void bloquearPuerta() {
  cerradura.write(ANGULO_CIERRE_SERVO);
  cerraduraAbierta = false;
  enviarMensaje("CERRADURA=CERRADA");
}
void desbloquearPuerta(const String &razon) {
  cerradura.write(ANGULO_ABIERTO_SERVO);
  cerraduraAbierta = true;
  desbloqueoEmpezo = millis();
  cambiarEstadoLeds(true, false, false);
  beep(1800, 100);
  enviarMensaje("CERRADURA=ABIERTA,RAZON=" + razon);
}
void cambiarLuz(uint8_t index, bool estado) {
  if (index > 2) return;
  luces[index] = estado;
  const uint8_t pines[] = {PIN_LUZ_1, PIN_LUZ_2, PIN_LUZ_3};
  digitalWrite(pines[index], estado ? HIGH : LOW);
  enviarMensaje("LUZ" + String(index + 1) + "=" + (estado ? "ENCENDIDA" : "APAGADA"));
}
void recibirComando(String linea) {
  linea.trim();
  if (!linea.length()) return;
  int igual = linea.indexOf('=');
  String comando = igual >= 0 ? linea.substring(0, igual) : linea;
  String valor = igual >= 0 ? linea.substring(igual + 1) : "";
  comando.trim();
  valor.trim();
  comando.toUpperCase();
  if (comando == "PING") enviarMensaje("PONG");
  else if (comando == "LUZ1") cambiarLuz(0, valor == "ENCENDIDA" || valor == "1");
  else if (comando == "LUZ2") cambiarLuz(1, valor == "ENCENDIDA" || valor == "1");
  else if (comando == "LUZ3") cambiarLuz(2, valor == "ENCENDIDA" || valor == "1");
  else if (comando == "ABRIR") desbloquearPuerta("APP");
  else if (comando == "CERRAR") bloquearPuerta();
  else if (comando == "ESTADO") {
    enviarMensaje("PUERTA=" + String(estadoPuerta == LOW ? "ABIERTA" : "CERRADA"));
    enviarMensaje("CERRADURA=" + String(cerraduraAbierta ? "ABIERTA" : "CERRADA"));
    for (int i = 0; i < 3; i++) {
      enviarMensaje("LUZ" + String(i+1) + "=" + (luces[i] ? "ENCENDIDA" : "APAGADA"));
    }
  } else enviarMensaje("ERROR=COMANDO_DESCONOCIDO," + comando);
}
void leerComandoSerial() {
  while (Serial.available()) {
    char c = (char)Serial.read();
    if (c == '\n') {
      recibirComando(lineaComando);
      lineaComando = "";
    } else if (c != '\r' && lineaComando.length() < 512) {
      lineaComando += c;
    } else if (lineaComando.length() >= 512) {
      lineaComando = "";
    }
  }
}
String leerUID() {
  String uid;
  for (byte i = 0; i < rfid.uid.size; i++) {
    if (rfid.uid.uidByte[i] < 0x10) uid += '0';
    uid += String(rfid.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();
  return uid;
}
void scanRFID() {
  if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial()) return;
  const uint32_t ahora = millis();
  String uid = leerUID();
  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();
  if (ahora - ultimoRfid < RFID_COOLDOWN_MS) return;
  ultimoRfid = ahora;
  enviarMensaje("TARJETA=" + uid);
}
void logicaBoton() {
  bool lectura = digitalRead(PIN_BOTON_INTERIOR);
  uint32_t ahora = millis();
  if (lectura != ultimaLecturaBoton) ultimoBoton = ahora;
  if ((ahora - ultimoBoton) > DEBOUNCE_MS && lectura != estadoBoton) {
    estadoBoton = lectura;
    if (estadoBoton == LOW) {
      enviarMensaje("BOTON=INTERIOR");
      desbloquearPuerta("BOTON_INTERIOR");
    }
  }
  ultimaLecturaBoton = lectura;
}
void logicaSensorPuerta() {
  bool lectura = digitalRead(PIN_PUERTA);
  uint32_t ahora = millis();
  if (lectura != ultimoEstadoPuerta) ultimaPuerta = ahora;
  if ((ahora - ultimaPuerta) > DEBOUNCE_MS && lectura != estadoPuerta) {
    estadoPuerta = lectura;
    bool estaAbierta = estadoPuerta == LOW;
    enviarMensaje(String("PUERTA=") + (estaAbierta ? "ABIERTA" : "CERRADA"));
    if (estaAbierta) beep(1200, 50);
  }
  ultimoEstadoPuerta = lectura;
}
void logicaDHT() {
  uint32_t ahora = millis();
  if (ahora - ultimoDht < INTERVALO_DHT_MS) return;
  ultimoDht = ahora;
  float humedad = dht.readHumidity();
  float temperatura = dht.readTemperature();
  if (isnan(humedad) || isnan(temperatura)) {
    enviarMensaje("ERROR_DE_SENSOR=DHT22");
    return;
  }
  enviarMensaje("AMB=T:" + String(temperatura, 1) + ",H:" + String(humedad, 1));
}
void setup() {
  Serial.begin(VELOCIDAD_SERIAL);
  lineaComando.reserve(512);
  pinMode(PIN_LUZ_1, OUTPUT);
  pinMode(PIN_LUZ_2, OUTPUT);
  pinMode(PIN_LUZ_3, OUTPUT);
  pinMode(PIN_LED_VERDE, OUTPUT);
  pinMode(PIN_LED_AMARILLO, OUTPUT);
  pinMode(PIN_LED_ROJO, OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);
  pinMode(PIN_PUERTA, INPUT_PULLUP);
  pinMode(PIN_BOTON_INTERIOR, INPUT_PULLUP);
  digitalWrite(PIN_LUZ_1, LOW);
  digitalWrite(PIN_LUZ_2, LOW);
  digitalWrite(PIN_LUZ_3, LOW);
  cambiarEstadoLeds(false, false, false);
  cerradura.setPeriodHertz(50);
  cerradura.attach(PIN_SERVO, 500, 2400);
  cerradura.write(ANGULO_CIERRE_SERVO);
  dht.begin();
  SPI.begin();
  rfid.PCD_Init();
  delay(100);
  enviarMensaje("LISTO=ESP32_DOMOTICA_V1");
}
void loop() {
  leerComandoSerial();
  logicaBoton();
  logicaSensorPuerta();
  scanRFID();
  logicaDHT();
  if (cerraduraAbierta && millis() - desbloqueoEmpezo >= DURACION_DESBLOQUEO_MS) {
    bloquearPuerta();
  }
}