/**
    Noah Park | Text Rain Implementation
**/


import processing.video.*;
import java.util.Random;

// Global variables for handling video data and the input selection screen
String[] cameras;
Capture cam;
Movie mov;
PImage inputImage;
boolean inputMethodSelected = false;

int threshold = 128;   // Threshold on whether the letters keep falling or not
String poem = "LoveislikeariverAneverendingstreamLoveissharedbyeachotherToanswersomeonesdream"; // From the poem: "God's Gift by John P. Read"
Random random = new Random ();  // To use the random module
PFont font;  // To set up the font
ArrayList<Letter> rain = new ArrayList<Letter>(); // Initialize our rain ArrayList
int maxLetters = 150;  // Only allow 150 letters on the screen at a time to prevent overlap
int currentLetters = 0; // Our current number of letters on the screen to be checked against maxLetters
int maxCollisions = 300; // The letter is stuck at this point and this also helps with overlap
boolean spacePressed = false; // To keep track of whether we are in threshold mode (for debugging)
int poemIndex = 0;  // Initial poem index is the beginning of the string for the poem
boolean mirrored = false; // Used to flip the video

void setup() {
  size(1280, 720);
  smooth();
  inputImage = createImage(width, height, RGB);
  font = createFont("Consolas", 18);
  textFont(font);
  stroke(230, 69, 90);
  fill(230, 69, 90);
}


void draw() {
  // When the program first starts, draw a menu of different options for which camera to use for input
  // The input method is selected by pressing a key 0-9 on the keyboard
  if (!inputMethodSelected) {
    cameras = Capture.list();
    int y=40;
    text("O: Offline mode, test with TextRainInput.mov movie file instead of live camera feed.", 20, y);
    y += 40; 
    for (int i = 0; i < min(9,cameras.length); i++) {
      text(i+1 + ": " + cameras[i], 20, y);
      y += 40;
    }
    return;
  }


  // This part of the draw loop gets called after the input selection screen, during normal execution of the program.

  
  // STEP 1.  Load an image, either from a movie file or from a live camera feed. Store the result in the inputImage variable
  
  if ((cam != null) && (cam.available())) {
    cam.read();
    inputImage.copy(cam, 0,0,cam.width,cam.height, 0,0,inputImage.width,inputImage.height);
    mirrored = false; // Change back mirrored to false so that it flips properly at the beginning on the next draw call
  }
  else if ((mov != null) && (mov.available())) {
    mov.read();
    inputImage.copy(mov, 0,0,mov.width,mov.height, 0,0,inputImage.width,inputImage.height);
    mirrored = false; // Change back mirrored to false so that it flips properly at the beginning on the next draw call
  }
  
  // Flip video so it acts like a mirror
  // Iteratively...Sighs in O(n^2)
  if(!mirrored){
    for(int i = 0; i < inputImage.width / 2; i++){
      for(int j = 0; j < inputImage.height; j++){
          // Go through the first half of the x values and flip them with their counterparts
          // On the opposite side of the screen (inputImage.width - i)
          color flipleft = inputImage.get(i, j);
          color flipright = inputImage.get(inputImage.width - i, j);
          inputImage.set(i, j, flipright);
          inputImage.set(inputImage.width - i, j, flipleft);        
      }
    }
    mirrored = true; // Make sure we only flip once per call to draw
  }
  
  
  // Set Grayscale by taking the average of the green, red, and blue in each pixel
  // then setting the pixel as this average for the grayscale
  for(int i = 0; i < inputImage.width; i++){
    for(int j = 0; j < inputImage.height; j++){
        float g = green(inputImage.get(i, j));
        float r = red(inputImage.get(i, j));
        float b = blue(inputImage.get(i, j));
        float avg = (g + r + b) / 3;
        color gray = color(avg);
        inputImage.set(i, j, gray);
    }
  }
  
  // Set Threshold (Spacebar debugging)
  if(spacePressed){    // Initially will be false until the press of the spacebar
    // Iterate through each pixel and check the green channel using get from the image against the threshold
    // If the green value is less than or equal to threshold set the pixel to black else white
    color black = color(0);
    color white = color(255);
    for(int i = 0; i < inputImage.width; i++){
      for(int j = 0; j < inputImage.height; j++){
        if(green(inputImage.get(i, j)) <= threshold){
           inputImage.set(i, j, black); 
        } else{
           inputImage.set(i, j, white); 
        }
      }
    }
  }
   
  // This code draws the current input image to the screen
  set(0, 0, inputImage);
  
  if(currentLetters < maxLetters){      // Ensure that the total letters on the screen does not exceed our capacity otherwise the letters become too chaotic
                                        // Create new letter object to then add to our rain ArrayList
    int randomIndex = poemIndex++;      // Our x position for each letter is what makes this random. However, incrementing the poemIndex by 1 each new letter gives us reasonable chance for words to be spelled.
    if(poemIndex >= poem.length()){     // Ensure the poemIndex does not go out of bounds
       poemIndex = 0;                   // Reset the poemIndex if it does go out of bounds to be at most 1 less than the length of poem
    }
    Letter newLetter = new Letter(randomIndex);  // Create a new letter using the random poem index
    rain.add(newLetter);                         // Add the newly created letter to our rain ArrayList
    currentLetters++;                            // Increment our current number of Letters
  }
  
  // On each call to the draw function, we need to loop through out rain ArrayList and make changes to each letter
  for(int i = 0; i < rain.size(); i++){
      color pixelColor = get(rain.get(i).getxpos(), rain.get(i).getypos());  // Obtain the pixel color
      color leftSlope = get(rain.get(i).getxpos() - 1, rain.get(i).getypos() - 1); // Obtain the color of the lower left diagonal of the current pixel
      color rightSlope = get(rain.get(i).getxpos() + 1, rain.get(i).getypos() - 1); // Obtain the color of the lower right diagonal of the current pixel
      color belowPixel = get(rain.get(i).getxpos(), rain.get(i).getypos() - 1); // Obtain the color of the pixel below the current pixel
      color abovePixel = get(rain.get(i).getxpos(), rain.get(i).getypos() + 1); // Obtain the color of the pixel above the current pixel
      rain.get(i).drawLetter();   // Call each Letter's draw method to draw itself at its x index
      
      // Increment y-position to emulate the letters falling down the screen if the given pixel's green
      // channel is greater than the threshold
      // Use the float values of the green channel of each pixel to determine whether the letters fall or not
      float greenChannel = green(pixelColor);
      float gls = green(leftSlope);
      float grs = green(rightSlope);
      float bp = green(belowPixel);
      float ap = green(abovePixel);
      if(ap <= threshold && bp > threshold){  // If the pixel above is black and the pixel below is not, ideally the pixel will be pushed down
        rain.get(i).pushDown();  
      }
      if(greenChannel <= threshold || bp <= threshold){  // Ensure that the letter does not pass through a very thin black pixel, rather it should collide
        rain.get(i).collision();                         // Call the letter's collision method
        if(bp <= threshold && gls > threshold && grs <= threshold){  // If we are on a left falling slope, ideally the letter will slowly "fall left"
          rain.get(i).fallLeft();  // Call the letter's left fall method
        }
        if(bp <= threshold && gls <= threshold && grs > threshold){  // If we are on a right falling slope, ideally the letter will slowly "fall right"
          rain.get(i).fallRight(); // Call the letter's right fall method
        } 
      } else{
        // Since we are potentially moving at more than one pixel downwards at a time, we need
        // to ensure that we do not jump through a thin black pixel. Here, we check each pixel
        // within the range that we are jumping to ensure this does not occur.
        boolean blackPixel = false;
        for(int j = 0; j < rain.get(i).getVelocity(); j++){ // Make sure that if we are jumping a certain amount, that we do not jump through thin black pixels
          if(green(get(rain.get(i).getxpos(), rain.get(i).getypos() + j)) <= threshold){ // If we find a thin black pixel in that range that the velocity is moving at then we mark blackPixel as true
            blackPixel = true;
          }
        }
        if(blackPixel){ // We found a thin black pixel and force collide with it
          rain.get(i).collision(); 
        } else{         // We did not find a thin black pixel and continue falling as normal
          rain.get(i).fall();
        }
      }
      
      // If the letters reach the bottom of the screen or hit a certain large number of collisions (potentially stuck) the corresponding letters should be removed from the ArrayList
      // This will help emulate the more random rain look
      if(rain.get(i).getypos() >= inputImage.height - 1 || rain.get(i).getCollisions() >= maxCollisions){
         rain.remove(rain.get(i)); 
         currentLetters--;
      }
  }
}


void keyPressed() {
  if (!inputMethodSelected) {
    // If we haven't yet selected the input method, then check for 0 to 9 keypresses to select from the input menu
    if ((key >= '0') && (key <= '9')) { 
      int input = key - '0';
      if (input == 0) {
        println("Offline mode selected.");
        mov = new Movie(this, "TextRainInput.mov");
        mov.loop();
        inputMethodSelected = true;
      }
      else if ((input >= 1) && (input <= 9)) {
        println("Camera " + input + " selected.");           
        // The camera can be initialized directly using an element from the array returned by list():
        cam = new Capture(this, cameras[input-1]);
        cam.start();
        inputMethodSelected = true;
      }
    }
    return;
  }

  // This part of the keyPressed routine gets called after the input selection screen during normal execution of the program
  if (key == CODED) {
    if (keyCode == UP) {
      // up arrow key pressed
      threshold++; // Increase threshold
    }
    else if (keyCode == DOWN) {
      // down arrow key pressed
      threshold--; // Decrease threshold
    }
  }
  else if (key == ' ') {
    // space bar pressed
    if(!spacePressed){ // Enable debugging mode
       spacePressed = true;  
    } else{            // Disable debugging mode
       spacePressed = false; 
    }
  }
}


class Letter {
   int xpos; // initial x position of the letter
   int ypos; // initial y position of the letter
   char ch;  // character the letter will represent
   int collisions; // total number of collisions the letter has experienced
   int vel = 1; // initial velocity of the letter
   int r; // red value for the letter
   int g; // green value for the letter
   int b; // blue value for the letter
   
   Letter(int index){
     this.xpos = int(random(5, inputImage.width - 5));  // Allow the letters to be visible on the screen
     this.ypos = int(random(0, 30));                    // Start y-position at the top of the screen or a bit below the top which helps the letters not overlap as much
     this.ch = poem.charAt(index);                      // Sets each letter's individual character from the poem
     this.collisions = 0;                               // Number of collisions each letter has experienced initialized to 0
     this.vel += (millis() % 4);                        // Uses the number of milliseconds as a unique velocity to each letter. Modulus ensures this will be a value from 0 to 3 (inclusive) which we add to the initial velocity of 1
     this.r = random.nextInt(256);                      // Choose a random red value for the letter
     this.g = 0;                                        // Keeping the green and blue values as zero will make the letters be different shades of red
     this.b = 0;
   }
   
   // return x position of the letter
   public int getxpos(){
     return this.xpos;
   }
   
   // return y position of the letter   
   public int getypos(){
     return this.ypos;
   }
   
   // return total collisions the letter has experienced
   public int getCollisions(){
     return this.collisions;  
   }
   
   // return velocity of the letter
   public int getVelocity(){
     return this.vel; 
   }
   
   // set a new x position for the letter
   public void setxpos(int newpos){
     this.xpos = newpos;  
   }
   
   // set a new y position for the letter
   public void setypos(int newpos){
     this.ypos = newpos;  
   }
   
   // emulates the falling rain for the letter
   public void fall(){
      this.ypos += vel; 
   }
   
   // emulates the collision with black/thresholded pixels
   public void collision(){
      this.ypos -= (vel*3) + 1;  // This is arbitrary, but emulates a good collision animation
      this.collisions++;
   }
   
   // emulates the falling rain off of a left slope
   public void fallLeft(){
      this.xpos -= (vel*3) + 1;  // This is also arbitrary, but helps the rain fall left somewhat
      this.ypos += (vel*3) + 1;
   }
   
   // emulates the falling rain off of a right slope
   public void fallRight(){
      this.xpos += (vel*3) + 1;  // This is also arbitrary, but helps the rain fall right somewhat
      this.ypos += (vel*3) + 1;
   }
   
   // emulates a black/thresholded object pushing a letter further downwards
   public void pushDown(){
      this.ypos += (vel*3) + 1;  
   }
   
   // Draws the letter on the screen
   public void drawLetter(){
      fill(this.r, this.g, this.b); // Some variation of red based on the randomly selected value initialized to this.r
      text(this.ch, this.xpos, this.ypos);
   }
}
