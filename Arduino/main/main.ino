constexpr uint32_t VELOCIDAD_SERIAL = 115200;

String lineaComando;

void enviarMensaje(const String &mensaje) {
  Serial.println(mensaje);
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
  else enviarMensaje("ERROR=UKNOWN_COMMAND," + comando);
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
  enviarMensaje("READY=ESP32_DOMOTICA_V1");
}
void loop() {
  leerComandoSerial();
}