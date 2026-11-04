constexpr uint8_t PIN_LUZ_1 = 15;
constexpr uint8_t PIN_LUZ_2 = 16;
constexpr uint8_t PIN_LUZ_3 = 17;

constexpr uint32_t VELOCIDAD_SERIAL = 115200;

bool luces[3] = {false, false, false};
String lineaComando;

void enviarMensaje(const String &mensaje) {
  Serial.println(mensaje);
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
  else enviarMensaje("ERROR=COMANDO_DESCONOCIDO," + comando);
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
void setup() {
  Serial.begin(VELOCIDAD_SERIAL);
  lineaComando.reserve(512);
  pinMode(PIN_LUZ_1, OUTPUT);
  pinMode(PIN_LUZ_2, OUTPUT);
  pinMode(PIN_LUZ_3, OUTPUT);
  digitalWrite(PIN_LUZ_1, LOW);
  digitalWrite(PIN_LUZ_2, LOW);
  digitalWrite(PIN_LUZ_3, LOW);
  enviarMensaje("LISTO=ESP32_DOMOTICA_V1");
}
void loop() {
  leerComandoSerial();
}