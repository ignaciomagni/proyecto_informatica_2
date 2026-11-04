import processing.serial.*;

Serial puerto;

String estadoActual = "Conectando ESP..";
ArrayList <String> eventos;
int scroll= 0;
int c =0;
void setup(){
  
  size(600,600);
  eventos = new ArrayList<String>();
  for(int i = 0; i<10; i++){
    eventos.add("Evento de ejemplo"+ i);
  }
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
  textAlign(CENTER);
  rectMode(CENTER);
  textSize(25);
  textFont(createFont("SansSerif", 15));
  text("Panel de control", width*0.5, height*0.05);
  textSize(16);
  text(estadoActual,  width*0.5, height*0.1);
  dibujarPanel(width*0.25, height*0.3, width * 0.3, height * 0.3, "Eventos recientes: " );
  for(int i=scroll ; i<7+min(scroll,eventos.size()-scroll);i++){;
    text(eventos.get(i), width*0.25, height*0.3-40+20*(i-scroll)); 
  }
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
    nuevoEvento(mensaje);
  }
}

void dibujarPanel(float x, float y, float ancho, float alto, String informacion){
  stroke(255,255,255);
  fill(0,0,0);
  rect(x, y, ancho, alto, 20);
  fill(255,255,255);
  textSize(13);
  textAlign(CENTER);
  text(informacion, x,  y - alto *0.4);
}

void mouseWheel(processing.event.MouseEvent event){
  
  scroll+= event.getCount(); 
  if(scroll < 0){
    scroll = 0; 
   }
  if(scroll>=(eventos.size()-7)){
   scroll = eventos.size()-7; 
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
 
 void nuevoEvento(String evento){
   String fecha = nf(day(), 2) + "/" + nf(month(), 2) + "-" + year();
   String registro = fecha +" "+ evento;
   eventos.add(registro);
   if(eventos.size() > 300){
    eventos.remove(0); 
   }
   String[] eventosTotal = loadStrings("eventos.csv");
   
   if(eventosTotal == null){
    eventosTotal = new String[0]; 
   }
   
   eventosTotal = append(eventosTotal, registro);
   if(eventosTotal.length > 100){
    eventosTotal = shorten(eventosTotal); 
   }
   saveStrings("eventos.csv", eventosTotal);
}
