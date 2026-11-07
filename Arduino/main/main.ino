#include <ESP32Servo.h>

const uint8_t PIN_LUZ_1 = 15;
const uint8_t PIN_LUZ_2 = 16;
const uint8_t PIN_LUZ_3 = 17;
const uint8_t PIN_PUERTA = 14;
const uint8_t PIN_SERVO = 2;

const uint32_t VELOCIDAD_SERIAL = 115200;
const uint32_t DEBOUNCE_MS = 40;
const uint32_t DURACION_DESBLOQUEO_MS = 3500;
const int ANGULO_CIERRE_SERVO = 0;
const int ANGULO_ABIERTO_SERVO = 90;

Servo cerradura;

bool luces[3] = {false, false, false};
bool cerraduraAbierta = false;
uint32_t desbloqueoEmpezo = 0;
uint32_t ultimaPuerta = 0;
bool ultimoEstadoPuerta = HIGH;
bool estadoPuerta = HIGH;
String lineaComando;

void enviarMensaje(const String &mensaje) {
  Serial.println(mensaje);
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
void logicaSensorPuerta() {
  bool lectura = digitalRead(PIN_PUERTA);
  uint32_t ahora = millis();
  if (lectura != ultimoEstadoPuerta) ultimaPuerta = ahora;
  if ((ahora - ultimaPuerta) > DEBOUNCE_MS && lectura != estadoPuerta) {
    estadoPuerta = lectura;
    bool estaAbierta = estadoPuerta == LOW;
    enviarMensaje(String("PUERTA=") + (estaAbierta ? "ABIERTA" : "CERRADA"));
  }
  ultimoEstadoPuerta = lectura;
}
void setup() {
  Serial.begin(VELOCIDAD_SERIAL);
  lineaComando.reserve(512);
  pinMode(PIN_LUZ_1, OUTPUT);
  pinMode(PIN_LUZ_2, OUTPUT);
  pinMode(PIN_LUZ_3, OUTPUT);
  pinMode(PIN_PUERTA, INPUT_PULLUP);
  digitalWrite(PIN_LUZ_1, LOW);
  digitalWrite(PIN_LUZ_2, LOW);
  digitalWrite(PIN_LUZ_3, LOW);
  cerradura.setPeriodHertz(50);
  cerradura.attach(PIN_SERVO, 500, 2400);
  cerradura.write(ANGULO_CIERRE_SERVO);
  enviarMensaje("LISTO=ESP32_DOMOTICA_V1");
}
void loop() {
  leerComandoSerial();
  logicaSensorPuerta();
  if (cerraduraAbierta && millis() - desbloqueoEmpezo >= DURACION_DESBLOQUEO_MS) {
    bloquearPuerta();
  }
}