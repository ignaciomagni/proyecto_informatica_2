import processing.serial.*;

Serial puerto;

String estadoActual = "Conectando ESP...";
ArrayList <String> eventos;
int scroll= 0;
int c =0;
boolean[] lucesEstado ={false, false, false};
boolean cerraduraEstado = false;

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
  textSize(15);
  textFont(createFont("SansSerif", 25));
  text("Panel de control", width*0.5, height*0.05);
  textSize(16);
  text(estadoActual,  width*0.5, height*0.1);
  dibujarPanel(width*0.2, height*0.3, width * 0.3, height * 0.3, "Eventos recientes: " );
  for(int i=scroll ; i<7+min(scroll,eventos.size()-scroll);i++){;
    text(eventos.get(i), width*0.2, height*0.3-40+20*(i-scroll)); 
  }
  
  dibujarPanel(width*0.70, height*0.3, width*0.5, height*0.3, "Control de luces");
  
  for(int i=0; i<3; i++){
    dibujarBoton(width*(0.70-(i-1)*0.16), height*0.3, width*0.1, "Led "+(-i-1+3), lucesEstado[i]);
  }
  
    dibujarPanel(width*0.70, height*0.65, width*0.5, height*0.3, "Control de cerradura");
    dibujarBoton(width*0.8, height*0.65, width*0.1, "Abrir",cerraduraEstado);
    dibujarBoton(width*0.6, height*0.65, width*0.1, "Cerrar",!cerraduraEstado);
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
void dibujarBoton(float x, float y, float diametro, String informacion, boolean estado){
 stroke(255,255,255);
 if(!estado){
 fill(0,0,0);
 circle(x+4, y+4, diametro);
 circle(x, y, diametro);
 textAlign(CENTER);
 fill(255,255,255);
 textSize(13);
 text(informacion, x, y);
 }else{
 fill(255,255,255);
 circle(x+4, y+4, diametro);
 textAlign(CENTER);
 fill(0,0,0);
 textSize(13);
 text(informacion, x+4, y+4);
 }
 
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

void mousePressed(){
  for(int i = 0; i<3;i++){
   if(dist(width*(0.70-(i-1)*0.16), height*0.3, mouseX, mouseY)<width*0.05) {
     lucesEstado[i]=!lucesEstado[i]; 
     if(lucesEstado[i]){
       enviarComando("LUZ"+(i+1)+"="+"ENCENDIDA");
     }else{
       enviarComando("LUZ"+(i+1)+"="+"APAGADA");
     }
     break;
   }
  }
  
  if(dist(width*0.6, height*0.65, mouseX, mouseY)<width*0.05){
    enviarComando("ABRIR");
    cerraduraEstado = false;
  }
  if(dist(width*0.8, height*0.65, mouseX, mouseY)<width*0.05){
    enviarComando("CERRAR");
    cerraduraEstado = true;
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
    enviarComando("ESTADO");
  }else if(mensaje.startsWith("CERRADURA=ABIERTA,RAZON=")){
    nuevoEvento("Cerradura desbloqueada: " + mensaje.substring(mensaje.indexOf("RAZON=")+7));
  }else if (mensaje.startsWith("CERRADURA=")){
    cerraduraEstado = mensaje.contains("ABIERTA");
  }else if(mensaje.startsWith("ERROR=")){
    estadoActual = mensaje;
    nuevoEvento(mensaje);
  }else if(mensaje.startsWith("LUZ")){
     int igual = mensaje.indexOf("=");
     if(igual>3){
         int boton = parseInt(mensaje.substring(3, igual))-1;
         String orden = mensaje.substring(igual+1);
         if(boton>=0 && boton<3){
            if(orden.equals("ENCENDIDA")){
             lucesEstado[boton] = true; 
            }else if(orden.equals("APAGADA")){
               lucesEstado[boton] = false; 
            }
         }
     }
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
