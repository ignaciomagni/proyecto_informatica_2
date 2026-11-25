import processing.serial.*;

Serial puerto;

final int MAX_MUESTRAS_REG = 10;
float[] tiemposRegMin = new float[MAX_MUESTRAS_REG];
float[] tempsRegC = new float[MAX_MUESTRAS_REG];
int totalMuestrasReg = 0;
int tiempoBaseMsReg = 0;
boolean baseTiempoInicializada = false;

float pendienteTemp = Float.NaN;    
float ordenadaTemp = Float.NaN;     
float tempProyectada5Min = Float.NaN; 

String estadoActual = "Conectando ESP...";
HashMap<String, String> usuarios = new HashMap<String, String>();
ArrayList <String> eventos;
int scroll= 0;
String sensorEstado = "T-- C H: -- % Calculando tendencia...";
boolean actualizarEstado = false;
boolean[] lucesEstado ={false, false, false};
String puertaEstado = "DESCONOCIDA"; 
boolean botonRegistro = false;
boolean botonCancelar = false;
boolean registrando = false;
boolean pedirNombre = false;
String idPendiente = "";
String nombre = "";
String ultimaTarjeta = "--";
String ultimoAcceso = "Sin eventos";
boolean cerraduraEstado = false;
String puertoDeseado = "COM3";
int ultimoIntentoConexion;
int intervaloReconexion = 2000;

void setup(){
  
  size(600,600);
  eventos = new ArrayList<String>();
  for(int i = 0; i<10; i++){
    eventos.add("Evento de ejemplo"+ i);
  }
  
  conectarPuerto();
  cargarUsuarios();
  cargarEventos();
  
  textFont(createFont("SansSerif", 25));
}

void draw() {
  background(0,0,0);
  fill(255,255,255);
  textAlign(CENTER);
  rectMode(CENTER);
  textSize(15);
  text("Panel de control", width*0.5, height*0.05);
  textSize(16);
  text(estadoActual,  width*0.5, height*0.1);
  dibujarPanel(width*0.2, height*0.3, width * 0.3, height * 0.35, "Eventos recientes: " );
  if(eventos.size()!=0){
    for(int i=scroll ; i<min(eventos.size(), scroll + 7);i++){;
      text(eventos.get(i), width*0.2, height*0.3-40+20*(i-scroll)); 
    }
  }
  dibujarPanel(width*0.70, height*0.215, width*0.5, height*0.175, "Control de luces");
  
  if(puerto == null && millis() - ultimoIntentoConexion >= intervaloReconexion) {
  ultimoIntentoConexion = millis();
  conectarPuerto();
  }
  
  for(int i=0; i<3; i++){
    dibujarBoton(width*(0.70-(i-1)*0.16), height*0.215, width*0.1, "Led "+(-i-1+3), lucesEstado[i]);
  }
  
    dibujarPanel(width*0.70, height*0.7875, width*0.5, height*0.175, "Control de cerradura");
    dibujarBoton(width*0.8, height*0.7875, width*0.1, "Abrir",cerraduraEstado);
    dibujarBoton(width*0.6, height*0.7875, width*0.1, "Cerrar",!cerraduraEstado);
    
    text("Puerta: " + puertaEstado, width*0.7, height*0.870);
  
  dibujarPanel(width*0.7, height*0.5, width * 0.35, height*0.3, "SENSOR AMBIENTAL");
  text(sensorEstado, width * 0.7, height * 0.625);
  if(!mousePressed){actualizarEstado=false; botonRegistro =false; botonCancelar=false;}
  dibujarBoton(width*0.7, height*0.5, width * 0.17, "Actualizar estado", actualizarEstado);


  dibujarPanel(width*0.2, height*0.7, width * 0.3, height * 0.35, "USUARIOS RFID " );
  dibujarBoton(width*0.13, height * 0.81, width * 0.1,"Registrar\n tarjeta", botonRegistro);
  dibujarBoton(width*0.27, height * 0.81, width * 0.1,"Cancelar\n registro", botonCancelar);
  text("Tarjetas registradas: "+ usuarios.size(), width*0.2, height * 0.65);
  text("Ultima tarjeta: " + ultimaTarjeta, width*0.2,height*0.7);
  text("Ultimo acceso: " + ultimoAcceso, width*0.2, height*0.75);
  if(pedirNombre){
    text("Nombre "+ idPendiente + ": " + nombre, width*0.5, height * 0.9);  
 }    
}

void conectarPuerto(){

  String[] puertos = Serial.list();

  println("Puertos disponibles:");
  printArray(puertos);

  for(int i = 0; i < puertos.length; i++){

    if(puertos[i].equals(puertoDeseado)){

      try{
        puerto = new Serial(this, puertos[i], 115200);
        puerto.bufferUntil('\n');

        estadoActual = "Conectando ESP32...";
        println("Intentando conectar con " + puertos[i]);

        return;

      }catch(RuntimeException e){

        puerto = null;
        estadoActual = "Puerto ocupado o inaccesible";
        println("Error al abrir puerto: " + e.getMessage());

        return;
      }
    }
  }

  puerto = null;
  estadoActual = "Esperando ESP32...";
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
 fill(255,255,255);
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
   if(dist(width*(0.70-(i-1)*0.16), height*0.215, mouseX, mouseY)<width*0.05) {
     boolean nuevoEstado=!lucesEstado[i]; 
     if(nuevoEstado){
       enviarComando("LUZ"+(i+1)+"="+"ENCENDIDA");
     }else{
       enviarComando("LUZ"+(i+1)+"="+"APAGADA");
     }
     break;
   }
  }
  
  if(dist(width*0.6, height*0.7875, mouseX, mouseY)<width*0.05){
    enviarComando("CERRAR");
 
  }
  if(dist(width*0.8, height*0.7875, mouseX, mouseY)<width*0.05){
    enviarComando("ABRIR");
  }
  if(dist(width*0.7, height*0.5,mouseX,mouseY)<width*0.085){
    enviarComando("ESTADO");
    actualizarEstado=true;
  }
  if(dist(width*0.13, height * 0.81,mouseX,mouseY)<width*0.05){
    if(pedirNombre){
      estadoActual = "Termina o cancela el registro actual primero";
      return;
    }
    botonRegistro = true;
    registrando = true;
    enviarComando("REGISTRAR");
    estadoActual = "Modo de registro activado: Acerca una tarjeta al lector";
    nuevoEvento("Solicitud de registro RFID");
  }
  if(dist(width*0.27, height * 0.81,mouseX,mouseY)<width*0.05){
    botonCancelar = true;
    registrando = false;
    pedirNombre = false;
    idPendiente = "";
    nombre = "";
    enviarComando("CANCELAR_REGISTRO");
    estadoActual = "Registro cancelado";
    return;
  }
}

void keyPressed(){
 if(!pedirNombre){
  return; 
 }
 if (key == ENTER || key == RETURN){
  String usuario = nombre.trim();
   if(usuario.length() == 0){
    estadoActual = "Escribe un nombre antes de confirmar";
    return;
   }
   usuarios.put(idPendiente, usuario);
    guardarUsuarios();
    sincronizarUsuarios();
    nuevoEvento("Tarjeta registrada: "+ usuario+" [" +idPendiente + "]");
    estadoActual="Tarjeta registrada correctamente";
    pedirNombre = false;
    registrando = false;
    idPendiente = "";
    nombre = "";
 }else if(key == ESC){
    key = 0;
    pedirNombre = false;
    registrando = false;
    idPendiente = "";
    nombre = "";
    enviarComando("CANCELAR_REGISTRO");
 }else if(key == BACKSPACE){
   if(nombre.length()>0){
     nombre = nombre.substring(0, nombre.length()-1);
   }
  }else if(key >=32 && key !=127 && nombre.length()<40){
     nombre +=key;
   }
}

void serialEvent(Serial puerto){
  String mensaje = puerto.readStringUntil('\n');
  
  if(mensaje == null){
    return;
  }
  mensaje = trim(mensaje);
  
  if(mensaje.length() == 0){
    return;
  }

  println("Mensaje recibido: " + mensaje);
  
  if(mensaje.startsWith("LISTO=")){
    estadoActual = "ESP32 conectado";
    sincronizarUsuarios();
    enviarComando("ESTADO");
  }else if(mensaje.startsWith("UID_REGISTRO=")){
    idPendiente = procesarTexto(mensaje.substring("UID_REGISTRO=".length()));
    if(usuarios.containsKey(idPendiente)){
        estadoActual = "Esta tarjeta ya esta registrada como " + usuarios.get(idPendiente);
        nuevoEvento("Intento de registrar UID ya existente: " + idPendiente);
        pedirNombre = false;
        registrando = false;
        sincronizarUsuarios();
    }else{
       pedirNombre = true;
       registrando = false;
       nombre = "";
       estadoActual="UID leido. Escribe el nombre y pulsa ENTER para guardar";
    }
  }else if(mensaje.startsWith("AMB=")){
    String info = mensaje.substring(4);
    float t = Float.NaN;
    float h= Float.NaN;
    String[] lecturas = split(info, ',');
    for(String lectura : lecturas){
     if(lectura.startsWith("T:")){
      t=parseFloat(lectura.substring(2));
     }
     if(lectura.startsWith("H:")){
      h=parseFloat(lectura.substring(2)); 
     }
    }
    if(!Float.isNaN(t) && !Float.isNaN(h)){
      registrarMuestraRegresion(t);
      if (!Float.isNaN(tempProyectada5Min)) {
        sensorEstado="T: "+ nf(t, 0, 1) + "C  H: " + nf(h,0,1) + " %\n" + "Pend: " + nf(pendienteTemp, 0, 2) + "C/m  +5m: " + nf(tempProyectada5Min, 0, 1) + "C"; 
      }else{
        sensorEstado = "T: " + nf(t, 0, 1) + "C  H: " + nf(h, 0, 1) + "%\nCalculando tendencia...";
      }
    }
  }else if(mensaje.startsWith("PUERTA=")){
      if(mensaje.substring(7).equals("ABIERTA")){
       puertaEstado = "ABIERTA";
      }else{
        puertaEstado = "CERRADA";
      }
      nuevoEvento("Puerta " + puertaEstado.toLowerCase());
  } else if(mensaje.startsWith("CERRADURA=ABIERTA,RAZON=")){
    cerraduraEstado = true;
    nuevoEvento("Cerradura desbloqueada: " + mensaje.substring(mensaje.indexOf("RAZON=")+6));
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
  }else if(mensaje.startsWith("ACCESO=CONSEDIDO")){
    ultimoAcceso = "AUTORIZADO";
    nuevoEvento("Acceso autorizado: " + mensaje);
    estadoActual = "Acceso autorizado";
  }else if(mensaje.startsWith("ACCESO=DENEGADO")){
    ultimoAcceso = "DENEGADO";
    nuevoEvento("Acceso denegado: "+ mensaje);
    estadoActual = "Acceso denegado";
  }else if(mensaje.startsWith("TARJETA=")){
    ultimaTarjeta = procesarTexto(mensaje.substring("TARJETA=".length()));
  } else if(mensaje.startsWith("REGISTRO=TIEMPO_TERMINADO")){
    registrando=false;
    estadoActual="Tiempo de registro agotado";
  }else if(mensaje.startsWith("ERROR_DE_SENSOR")){
    estadoActual = "Error leyendo DHT";
    nuevoEvento(estadoActual);
  }else if(mensaje.startsWith("USUARIOS_SINCRONIZADOS=")){
    estadoActual = "Usuarios sincronizados con ESP32: " + mensaje.substring("USUARIOS_SINCRONIZADOS=".length());
  }else if (mensaje.startsWith("BOTON=")){
    nuevoEvento("Boton interior pulsado");
  }else if(mensaje.startsWith("REGISTRO=LISTO")){
   estadoActual="Modo de registro: acerca una tarjeta al lector RFID"; 
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
 
void guardarUsuarios(){
 ArrayList<String> mensajes = new ArrayList<String>();
 for(String id: usuarios.keySet()){
   mensajes.add(id + "," + usuarios.get(id).replace(","," "));
   }
   saveStrings("usuarios.csv", mensajes.toArray(new String[0]));
 }
 
 
String procesarTexto(String texto){
   if(texto == null){
    return ""; 
   }
   texto = trim(texto).toUpperCase().replace(" ","").replace(":", "").replace("-","");
   return texto;
 }
 
 void sincronizarUsuarios(){
   String csv = "";
   for(String id:usuarios.keySet()){
    if(csv.length()>0){
      csv += ",";
    }
     csv += id;
   }
   if(csv.length()>0){
     enviarComando("USUARIOS="+ csv);
   }
 }
 
 void cargarUsuarios(){
   File archivo = new File(dataPath("usuarios.csv"));
   if(!archivo.exists()){
    return; 
   }
   String[] usuarioss = loadStrings("usuarios.csv");
   if (usuarioss == null){
    return; 
   }
   for(String usuario: usuarioss){
     int coma = usuario.indexOf(',');
     if(coma>0){
      String id=procesarTexto(usuario.substring(0, coma));
      String nombre = usuario.substring(coma+1);
      if(id.length()>0 && nombre.length()>0){
       usuarios.put(id, nombre); 
      }
     }
   }
 }
 
void cargarEventos(){
 File archivo = new File(dataPath("eventos.csv"));
 if(!archivo.exists()){
   return;
  }
 String[] eventosCarga = loadStrings("eventos.csv");
 if(eventosCarga == null){
    return; 
  } 
  for(String eventoActual : eventosCarga){
    if(eventoActual != null && trim(eventoActual).length()>0) {
      eventos.add(eventoActual);
    }   
  }
  while(eventos.size()>100){
    eventos.remove(0);
   }
 }
 void nuevoEvento(String evento){
   String fecha = nf(day(), 2) + "/" + nf(month(), 2) + "-" + year();
   String registro = fecha +" "+ evento;
   eventos.add(registro);
   if(eventos.size() > 100){
    eventos.remove(0); 
   }
   saveStrings("eventos.csv", eventos.toArray(new String[0]));
}

void registrarMuestraRegresion(float tempC) {
  if (Float.isNaN(tempC)) {
    return;
  }

  int ahoraMs = millis();
  if (!baseTiempoInicializada) {
    tiempoBaseMsReg = ahoraMs;
    baseTiempoInicializada = true;
  }

  float tMin = (ahoraMs - tiempoBaseMsReg) / 60000.0;

  if (totalMuestrasReg < MAX_MUESTRAS_REG) {
    tiemposRegMin[totalMuestrasReg] = tMin;
    tempsRegC[totalMuestrasReg] = tempC;
    totalMuestrasReg++;
  } else {
    
    for (int i = 0; i < MAX_MUESTRAS_REG - 1; i++) {
      tiemposRegMin[i] = tiemposRegMin[i + 1];
      tempsRegC[i] = tempsRegC[i + 1];
    }
    tiemposRegMin[MAX_MUESTRAS_REG - 1] = tMin;
    tempsRegC[MAX_MUESTRAS_REG - 1] = tempC;
  }

  calcularRegresionLineal();
}

void calcularRegresionLineal() {
  if (totalMuestrasReg < 2) {
    pendienteTemp = Float.NaN;
    ordenadaTemp = Float.NaN;
    tempProyectada5Min = Float.NaN;
    return;
  }

  float sumX = 0;
  float sumY = 0;
  float sumXY = 0;
  float sumX2 = 0;

  for (int i = 0; i < totalMuestrasReg; i++) {
    float x = tiemposRegMin[i];
    float y = tempsRegC[i];
    sumX += x;
    sumY += y;
    sumXY += x * y;
    sumX2 += x * x;
  }

  float n = totalMuestrasReg;
  float denominador = n * sumX2 - sumX * sumX;


  if (abs(denominador) < 1e-6) {
    pendienteTemp = 0.0;
    ordenadaTemp = sumY / n;
  } else {
    pendienteTemp = (n * sumXY - sumX * sumY) / denominador;
    ordenadaTemp = (sumY - pendienteTemp * sumX) / n;
  }

  float tiempoActualMin = tiemposRegMin[totalMuestrasReg - 1];
  tempProyectada5Min = predecirTemperatura(tiempoActualMin + 5.0);
}

float predecirTemperatura(float futuroMin) {
  if (Float.isNaN(pendienteTemp) || Float.isNaN(ordenadaTemp)) {
    return Float.NaN;
  }
  return pendienteTemp * futuroMin + ordenadaTemp;
}
