import processing.serial.*;

Serial puerto;

String estadoActual = "Conectando ESP..";

void setup(){
  size(600,600);
  String puertos[] = Serial.list();
  print("Puertos disponibles: ");
  println();
  printArray(puertos);
  if(puertos.length > 0){
    puerto = new Serial(this, puertos[0], 115200);
  }else{
   println("No hay puertos disponibles") ;
  }
}

void draw() {
  background(0,0,0);
  fill(255,255,255);
  textSize(25);
  text("Panel de control", 25, 38);
  textSize(13);
  text(estadoActual, 26, 62);
}

void serialEvent(Serial puerto){
  String mensaje = puerto.readStringUntil('\n');
  mensaje = trim(mensaje);
  if(mensaje != null){
    println("Mensaje recibido: ", mensaje);
  }else{
   return; 
  }
  if(mensaje.startsWith("LISTO=")){
    estadoActual = "ESSP32 conectado";
  } else if(mensaje.startsWith("ERROR=")){
    estadoActual = mensaje;
  }
}

void enviarComando(String comando){
 if(puerto == null){
  estadoActual = "No se pudo enviar comando: Sin conexión serie";
  return;
 }
 puerto.write(comando + "\n");
 println("Comando enviado: " + comando);
 }
