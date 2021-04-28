/**
 * ICAM Senior Project
 * Yanxin(Cleo) Xiao
 * 04/26/2021
 * 
 * PixelFlow | Copyright (C) 2016 Thomas Diewald - http://thomasdiewald.com
 * 
 * 
 */



import java.io.File;

import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLSLProgram;
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D;
import com.thomasdiewald.pixelflow.java.fluid.DwFluidParticleSystem2D;
import com.thomasdiewald.pixelflow.java.utils.DwFrameCapture;

import controlP5.Accordion;
import controlP5.ControlP5;
import controlP5.Group;
import controlP5.RadioButton;
import controlP5.Toggle;
import processing.core.*;
import processing.opengl.PGraphics2D;

import oscP5.*;
import netP5.*;

import processing.sound.*;
import de.voidplus.leapmotion.*;

LeapMotion leap;

ArrayList<PVector> old = new ArrayList<PVector>();
PVector old_position, old_velocity, center, target;  
  int viewport_w = 1920;
  int viewport_h = 1080;
  //int viewport_w = 300;
  //int viewport_h = 300;
  int viewport_x = 0;
  int viewport_y = 0;
  
  int gui_w = 200;
  int gui_x = 20;
  int gui_y = 20;
  
  int fluidgrid_scale = 1;
  
  DwPixelFlow context;
  DwFluid2D fluid;
  MyFluidData cb_fluid_data;
  DwFluidParticleSystem2D particle_system;
  

  PGraphics2D pg_fluid;       // render target
  PGraphics2D pg_obstacles;   // texture-buffer, for adding obstacles
  PGraphics2D pg_text;        // texture-buffer, for adding fluid data (density and temperature)
  PGraphics textLayer;
  
  
  //sound
  SoundFile sound;
  
  //image
  PImage bg;
  
  // processing font
  PFont font;
  PFont font2;
  
  // some state variables for the GUI/display
  int     BACKGROUND_COLOR           = 255;
  boolean UPDATE_FLUID               = true;
  boolean DISPLAY_FLUID_TEXTURES     = true;
  boolean DISPLAY_FLUID_VECTORS      = false;
  int     DISPLAY_fluid_texture_mode = 0;
  boolean DISPLAY_PARTICLES          = false;

  OscP5 oscP5;
  NetAddress myRemoteLocation;
  
  //LeapMotion leap;
  
  String s="";
  String args = "";
  float[] rand = new float[25];
  float[] rand2 = new float[25];
  
  PVector previousLeftHandPos = new PVector(0,0);
  PVector previousRightHandPos = new PVector(0,0);
  
  //float[] rand;
  //float[] rand2;
 
  public void settings() {
    size(viewport_w, viewport_h, P2D);
    smooth(4);
  }
  
  public void setup() {
    //sound = new SoundFile(this, "Senior Project.mp3");
    //sound.loop();
    leap = new LeapMotion(this).allowGestures();
    
    bg = loadImage("texture.jpg");
    oscP5 = new OscP5(this,12000);
    myRemoteLocation = new NetAddress("127.0.0.1",12000);
    
    surface.setLocation(viewport_x, viewport_y);
    
    // main library context
    context = new DwPixelFlow(this);
    context.print();
    context.printGL();

    // fluid simulation
    fluid = new DwFluid2D(context, viewport_w, viewport_h, fluidgrid_scale);
    
    // fuild simulation parameters
    fluid.param.dissipation_density     = 0.90f;
    fluid.param.dissipation_velocity    = 0.90f;
    fluid.param.dissipation_temperature = 0.90f;
    
    // interface for adding data to the fluid simulation
    cb_fluid_data = new MyFluidData();
    fluid.addCallback_FluiData(cb_fluid_data);

    // processing font
    font = createFont("FZLUXTJW--GB1-0", 64);
    font2 = createFont("FZZHAOJSJSJF--GBK1-0",64);

    // fluid render target
    pg_fluid = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
    pg_fluid.smooth(4);

    // particles
    particle_system = new DwFluidParticleSystem2D();
    particle_system.resize(context, viewport_w/20, viewport_h/20);
    
    // obstacles buffer
    pg_obstacles = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
    pg_obstacles.noSmooth();
    pg_obstacles.beginDraw();
    pg_obstacles.clear();
    // border
    pg_obstacles.strokeWeight(24);
    pg_obstacles.stroke(255,0,0);
    pg_obstacles.noFill();
    pg_obstacles.rect(0, 0, pg_obstacles.width, pg_obstacles.height, 24);
    pg_obstacles.endDraw();
    
    // add the obstacles to the simulation
    fluid.addObstacles(pg_obstacles);
 
    // buffer, for fluid data
    pg_text = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);

    //background(bg);
    background(255);
    frameRate(60);
    
    textLayer = createGraphics(width,600);
    
    frameRate(leap.getFrameRate());

    //float[] rand = new float[25];
    //float[] rand2 = new float[25];
    for(int i = 0; i < 14;i++){
      rand[i] = random(1.0, 6.0);
      while(rand2[i]==0){
        rand2[i] = random(-2.5,3.0);
      }
    }
  }
  
  //leap motion 
  public void drawFluid(DwFluid2D fluid){
   //Source Diewald, T. (2016) Fluid_GetStarted.
   
   //THIS VARIABLE IS KEY TO INCREASING FPS ON LOWER-END COMPUTERS
      int constraint = 10;
   
     float lpx, lpy, lvx, lvy, rpx, rpy, rvx, rvy, radius, vscale;
     
      PVector lprevpos = new PVector(0,0);
      PVector rprevpos = new PVector(0,0);
       
      if(leftHandExists() && !leftIsLimited(leap.getLeftHand().getPosition(), constraint)){
        
        Hand leftHand = leap.getLeftHand();

        vscale = 15;
        
        //left hand positional variables
        lpx     = leftHand.getPosition().x;
        lpy     = height-leftHand.getPosition().y+50;
        lprevpos = getpreviousLeftHandPos();
        lvx     = (lpx - lprevpos.x) * +vscale;
        lvy     = (leftHand.getPosition().y - lprevpos.y) * -vscale;
        
        //left hand velocity
        radius = random(15,30);
        fluid.addVelocity(lpx,lpy, radius, lvx, lvy);
        fluid.addVelocity(lpx,lpy, radius, lvx, lvy);
        fluid.addTemperature(lpx,lpy,10,1);
        fluid.addDensity(lpx, lpy, 10, 1.0, 1.0, 1.0, 1.0f);
        previousLeftHandPos = leftHand.getPosition();
      } 
      if (rightHandExists() && !rightIsLimited(leap.getRightHand().getPosition(), constraint)) {
        
        Hand rightHand = leap.getRightHand();
        
        vscale = 15;
        
        //right hand positional variables
        rpx     = rightHand.getPosition().x;
        rpy     = height-rightHand.getPosition().y+50;
        rprevpos = getpreviousRightHandPos();
        rvx     = (rpx - rprevpos.x) * +vscale;
        rvy     = (rightHand.getPosition().y - rprevpos.y) * -vscale;        
       
        radius = random(15,30);
        fluid.addVelocity(rpx, rpy, 14, rvx, rvy);
        fluid.addVelocity(rpx, rpy, 20, rvx, rvy);
        fluid.addTemperature(rpx,rpy,10,1);
        fluid.addDensity(rpx, rpy, 10, 1.0, 1.0, 1.0, 1.0f);
        previousRightHandPos = rightHand.getPosition();
      }
 }
 
    public PVector getpreviousLeftHandPos(){
    if (previousLeftHandPos == null)
      return new PVector(0,0);
    else
     return previousLeftHandPos;  
  }
    public PVector getpreviousRightHandPos(){
    if (previousRightHandPos == null)
      return new PVector(0,0);
    else
     return previousRightHandPos;  
  }
  public boolean leftHandExists(){
   if (leap.getLeftHand() == null){
     return false;
   }
  return true;
  }
  public boolean rightHandExists(){
   if (leap.getRightHand() == null){
     return false;
   }
  return true;
  }
  public boolean leftIsLimited(PVector handPos, int constraint){
    //artificial constaint so every fps =/= a fluid update which can RIP your GPU to shreds
    if (handPos == null)
      return true;
    if (handPos.x - previousLeftHandPos.x <= constraint && handPos.x - previousLeftHandPos.x >= -constraint)
      if (handPos.y - previousLeftHandPos.y <= constraint && handPos.y - previousLeftHandPos.y >= -constraint)
        return true;
   return false; 
  }
   public boolean rightIsLimited(PVector handPos, int constraint ){ 
     //artificial constaint so every fps =/= a fluid update which can RIP your GPU to shreds
     if (handPos == null)
      return true;
    if (handPos.x - previousRightHandPos.x <= constraint && handPos.x - previousRightHandPos.x >= -constraint)
     if (handPos.y - previousRightHandPos.y <= constraint && handPos.y - previousRightHandPos.y >= -constraint)
        return true;
   return false; 
  }
  
  private class MyFluidData implements DwFluid2D.FluidData{
    
    @Override
    // this is called during the fluid-simulation update step.
    public void update(DwFluid2D fluid) {
      
      drawFluid(fluid);
    
      float px, py, vx, vy, radius, vscale;       
      boolean mouse_input = mousePressed;
      if(mouse_input ){
        
        vscale = 15;
        px     = mouseX;
        py     = height-mouseY;
        vx     = (mouseX - pmouseX) * +vscale;
        vy     = (mouseY - pmouseY) * -vscale;
        
        print("px "+ px + "\n");
        print("py "+ py + "\n");
        print("vx "+ vx + "\n");
        print("vy "+ vy + "\n");
        
        if(mouseButton == LEFT){
          radius = 30;
          fluid.addVelocity(px, py, radius, vx, vy, 2, 0.5f);
        }
        if(mouseButton == CENTER){
          radius = 30;
          fluid.addDensity (px, py, radius, 1.0f, 0.0f, 0.40f, 1f, 1);
        }
        
      }
  
      // use the text as input for density and temperature
      addDensityTexture    (fluid, pg_text);
      addTemperatureTexture(fluid, pg_text);
    }
    
    // custom shader, to add density from a texture (PGraphics2D) to the fluid.
    public void addDensityTexture(DwFluid2D fluid, PGraphics2D pg){
      int[] pg_tex_handle = new int[1];
      context.begin();
      context.getGLTextureHandle(pg, pg_tex_handle);
      context.beginDraw(fluid.tex_density.dst);

      DwGLSLProgram shader = context.createShader("data/addDensity.frag");
      shader.begin();
      shader.uniform2f     ("wh"        , fluid.fluid_w, fluid.fluid_h);                                                                   
      shader.uniform1i     ("blend_mode", 6);   
      shader.uniform1f     ("mix_value" , 0.05f);     
      shader.uniform1f     ("multiplier", 2.0);     
      shader.uniformTexture("tex_ext"   , pg_tex_handle[0]);
      shader.uniformTexture("tex_src"   , fluid.tex_density.src);
      shader.drawFullScreenQuad();
      shader.end();
      context.endDraw();
      context.end("app.addDensityTexture");
      fluid.tex_density.swap();
    }
    
    // custom shader, to add temperature from a texture (PGraphics2D) to the fluid.
    public void addTemperatureTexture(DwFluid2D fluid, PGraphics2D pg){
      int[] pg_tex_handle = new int[1];
      context.begin();
      context.getGLTextureHandle(pg, pg_tex_handle);
      context.beginDraw(fluid.tex_temperature.dst);
      DwGLSLProgram shader = context.createShader("data/addTemperature.frag");
      shader.begin();
      shader.uniform2f     ("wh"        , fluid.fluid_w, fluid.fluid_h);                                                                   
      shader.uniform1i     ("blend_mode", 1);   
      shader.uniform1f     ("mix_value" , 0.002f);     
      shader.uniform1f     ("multiplier", -0.15f);     
      shader.uniformTexture("tex_ext"   , pg_tex_handle[0]);
      shader.uniformTexture("tex_src"   , fluid.tex_temperature.src);
      shader.drawFullScreenQuad();
      shader.end();
      context.endDraw();
      context.end("app.addTemperatureTexture");
      fluid.tex_temperature.swap();
    }
  }
  
  

  

  
  
  public void drawText(PGraphics pg,float px, float py, String str){
    pg.beginDraw();
    pg.clear();
 
    pg.textFont(font);
    pg.textAlign(CENTER, CENTER);
    
    //pg.fill(0,0,0);
////    pg.text(str.charAt(0), px, py);
    if(str.length() != 0){
      for(int i = 0;i<str.length();i++){
        float x = px + i*150;
        float y = py + 30*rand2[i];
        //pg.fill(255-51*(rand[1]-1),255-51*(rand[1]-1),255-51*(rand[1]-1));
        pg.fill(10,10,10);
        pg.textSize(64 * rand[i]);
        pg.text(str.charAt(i), x, y);
      }
    }
    pg.textSize(128);
    pg.fill(100,100,100);
    pg.textFont(font2);
    //pg.text(str, width/2, height-200);
    pg.endDraw();
  }
  

   public void oscEvent(OscMessage theOscMessage) {
    /* print the address pattern and the typetag of the received OscMessage */
    print("### received an osc message.");
    print(" addrpattern: "+theOscMessage.addrPattern());
    println(" typetag: "+theOscMessage.typetag());
    byte[] b=theOscMessage.get(0).bytesValue();
    try {
      s=new String(b,"UTF-8");
    }
    catch(Exception e){}
    println("String: "+s);
    //pg_text.clear();
  }

  public void draw() {
    //args = "风暖寒云岸，月中微色明";
    //int len = args.length();
    //float xPos = width/2 - 75*len;
    //drawText(pg_text, xPos, height/2-400, args);
    //if (rand == null ){
    //  print("start painting");
    //  rand = new float[s.length()];
    //  rand2 = new float[s.length()];
    //  for(int i = 0; i < s.length();i++){
    //    rand[i] = random(1.0, 6.0);
    //    while(rand2[i]==0){
    //      rand2[i] = random(-2.5,3.0);
    //    }
    //  }
    //}
    
    int len = s.length();
    float xPos = width/2 - 75*len;
    
    drawText(pg_text, xPos, height/2-100, s);
    textLayer.beginDraw();
    textLayer.background(255);
    textLayer.fill(0);
    textLayer.square(width/2,height-200, 500);
    textLayer.text(args,width/2,height-200);
    textLayer.endDraw();
    
    //delay(500);
    
    if(UPDATE_FLUID){
      fluid.addObstacles(pg_obstacles);
      fluid.update();
      particle_system.update(fluid);
    }

    pg_fluid.beginDraw();
    pg_fluid.background(255);
    pg_fluid.endDraw();
    
    if(DISPLAY_FLUID_TEXTURES){
      fluid.renderFluidTextures(pg_fluid, DISPLAY_fluid_texture_mode);
    }
    
    // display
    image(pg_fluid    , 0, 0);
    image(pg_obstacles, 0, 0);
    //image(textLayer,0,height-500);
    
    //image(pg_text     , 0, 0);
    
    //text(s,width/2, height-200);

    // info
    String txt_fps = String.format(getClass().getName()+ "   [size %d/%d]   [frame %d]   [fps %6.2f]", fluid.fluid_w, fluid.fluid_h, fluid.simulation_step, frameRate);
    surface.setTitle(txt_fps);
  }
