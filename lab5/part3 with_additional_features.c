/* This files provides address values that exist in the system */

#define SDRAM_BASE            0xC0000000
#define FPGA_ONCHIP_BASE      0xC8000000
#define FPGA_CHAR_BASE        0xC9000000

/* Cyclone V FPGA devices */
#define LEDR_BASE             0xFF200000
#define HEX3_HEX0_BASE        0xFF200020
#define HEX5_HEX4_BASE        0xFF200030
#define SW_BASE               0xFF200040
#define KEY_BASE              0xFF200050
#define TIMER_BASE            0xFF202000
#define PIXEL_BUF_CTRL_BASE   0xFF203020
#define CHAR_BUF_CTRL_BASE    0xFF203030

/* VGA colors */
#define WHITE 0xFFFF
#define YELLOW 0xFFE0
#define RED 0xF800
#define GREEN 0x07E0
#define BLUE 0x001F
#define CYAN 0x07FF
#define MAGENTA 0xF81F
#define GREY 0xC618
#define PINK 0xFC18
#define ORANGE 0xFC00

#define ABS(x) (((x) > 0) ? (x) : -(x))

/* Screen size. */
#define RESOLUTION_X 320
#define RESOLUTION_Y 240

/* Constants for animation */
#define BOX_SIZE 5
#define NUM_BOXES 8

#define FALSE 0
#define TRUE 1

#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <math.h>
#include <stdint.h>

// Begin part3.c code for Lab 7

//function declarations
void count_and_display(volatile int *A9_private_timer);
void erase_and_draw(volatile int * pixel_ctrl_ptr);
void draw_line(int x_0, int y_0, int x_1, int y_1, short int line_colour);
void clear_screen();
void wait_for_vsync();
void plot_pixel(int x, int y, short int line_colour);
void draw();
void draw_box(int x, int y, short int line_colour);
void incremnet_bound_check(int x, int* delta_x, int y, int* delta_y);
uint8_t bit_code(int index);


// global variable
volatile int pixel_buffer_start;
volatile int *A9_private_timer = (int *)0xFFFEC600; //base add. of A9 timer
volatile int *display = (int *)0xFF200020;
int * led_address = (int *)  0xFF200000;
int count = 0;
int led_count = 0;
int x_box[NUM_BOXES] ={15,200,150,30,80,180,220,290};
int y_box[NUM_BOXES] = {233,215,150,120,135,80,50,20};
int colour[NUM_BOXES];
int dx_box[NUM_BOXES];
int dy_box[NUM_BOXES];
int x_previous_box[NUM_BOXES];
int y_previous_box[NUM_BOXES];
uint8_t bit_array[10] = {0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111};

int main(void)
{
    volatile int *push_button = (int *)0xFF200050; // data register of push buttons
         // unit_8 is an 8-bit unsigned integer
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    
    
    
    // initialize location and direction of rectangles(not shown)

    /* set front pixel buffer to start of FPGA On-chip memory */
    *(pixel_ctrl_ptr + 1) = 0xC8000000; // first store the address in the 
                                        // back buffer
    /* now, swap the front/back buffers, to set the front buffer location */
    wait_for_vsync();
    /* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen(); // pixel_buffer_start points to the pixel buffer
    /* set back pixel buffer to start of SDRAM memory */
    *(pixel_ctrl_ptr + 1) = 0xC0000000;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // we draw on the back buffer
    clear_screen(); // pixel_buffer_start points to the pixel buffer
    
    *(A9_private_timer) = 2000000;
    *(A9_private_timer+2) = 0b111;
    
    //generate randnom initial directions of each box
    for(int i = 0; i < NUM_BOXES; ++i){
        dx_box[i] = (rand()%2)*2-1;//either 1 or -1
        dy_box[i] = (rand()%2)*2-1;//either 1 or -1
    }
    
    //generate random colours for each line
    for(int i = 0; i < NUM_BOXES; ++i){
        colour[i] = (rand()%65535)+1;//a number between 1 and 0xFFFF
    }
    
    while (1)
    {   if(*(push_button+3) != 0){
            *(push_button+3) = *(push_button+3);
            *(A9_private_timer+2) ^= 0b1;
        }
        else{
            count_and_display(A9_private_timer);
            erase_and_draw(pixel_ctrl_ptr);
        }
    }
}

void count_and_display(volatile int *A9_private_timer){
    volatile int* Interrupt = (A9_private_timer+3);
    count = count % 6000;
    int thousands_digit = count / 1000;
    int hundreds_digit = (count - thousands_digit * 1000) / 100;
    int tens_digit = (count - thousands_digit * 1000 - hundreds_digit * 100) / 10;
    int ones_digit = count % 10;

    int bit_pattern = (bit_code(thousands_digit) << 24) + (bit_code(hundreds_digit) << 16) + (bit_code(tens_digit) << 8) + bit_code(ones_digit);
    if (((*Interrupt) & 0x1) == 1){
               *Interrupt = 1;
               *display = bit_pattern;
               count++;
           }
}

void erase_and_draw(volatile int * pixel_ctrl_ptr ){
    /* Erase any boxes and lines that were drawn in the last iteration */
        draw();
    
    //update previous boxes position, do boundary check, and move x and y with dx and dy,.
    for(int i = 0; i < NUM_BOXES; ++i){
        x_previous_box[i] = x_box[i];   //record last drawn pixels' postions
        y_previous_box[i] = y_box[i];
        
        incremnet_bound_check(x_box[i], &dx_box[i], y_box[i], &dy_box[i]);//make sure moves are not going overbound
        x_box[i] += dx_box[i];          //move boxes with directions
        y_box[i] += dy_box[i];
        
    }// code for drawing the boxes and lines (not shown)
    // code for updating the locations of boxes (not shown)
    
    //draw boxes and lines
    for(int i = 0; i < NUM_BOXES; ++i){
        draw_box(x_box[i],y_box[i],0XFFFF);         //draw boxes in white
        draw_line(x_box[i],y_box[i],x_box[(i+1)%8],y_box[(i+1)%8],colour[i]);   //draw lines in randomrized colours
    }
    
    led_count++;//increment count
    led_count = led_count%1024; //a cycle has 1024 turns
    *led_address = led_count;
    
    wait_for_vsync(); // swap front and back buffers on VGA vertical sync
    
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer
}


// code for subroutines (not shown)
void plot_pixel(int x, int y, short int line_colour)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_colour;//fill  the specific pixel with line_colour
}

//synchronize, and swap the contents of front and back buffers.
void wait_for_vsync(){
    volatile int * buffer = (int *)0xFF203020;
    int status;

    *buffer = 1;            //start synchronization
    status = *(buffer+3);   //get the content of status register

    while((status & 0x01) != 0){    //do polling until drawing is finished
        status = *(buffer+3);
    }
}

//clear the entire screen (i.e set all pixels to black)
void clear_screen(){
    for (int x = 0; x < RESOLUTION_X; ++x) {
        for (int y= 0; y < RESOLUTION_Y ; ++y) {
            plot_pixel(x,y,0);
        }
    }
}

//swap x and y, providede they are not at the same position in memory
void exchange_value(int *x, int* y){
    *x = *x^*y; //*x = *x^*y;
    *y = *x^*y; //*y = *x^*y^*y = *x;
    *x = *x^*y; //*x = *x^*y^*x^*y^*y = *x^*y^*x = *y;
}

//clear previous boxes and lines
void draw(){
    for(int i =0;i<NUM_BOXES;++i){
        //erase boxes and lines if we have drawn at least once
            draw_box(x_previous_box[i],y_previous_box[i],0x0000);
            draw_line(x_previous_box[i],y_previous_box[i],x_previous_box[(i+1)%8],y_previous_box[(i+1)%8],0X0000);
    }
}

//plot a two by two box. x,y coordinates act as the top left corner of the box
void draw_box(int x, int y, short int line_colour){
    for(int i = 0; i <= BOX_SIZE; i++){
        for(int j = 0; j <= BOX_SIZE; j++){
            plot_pixel(x+i,y+j,line_colour);
        }
    }
}

//bresenham algorithm to draw lines
void draw_line(int x_0, int y_0, int x_1, int y_1, short int line_colour){
    bool is_steep = abs(y_1 - y_0) > abs(x_1 - x_0);
    //if the graph is steep, swap x and y.
    if(is_steep){
        exchange_value(&x_0, &y_0);
        exchange_value(&x_1,&y_1);
    }
    //if the starting x is > ending x, swap their positions and corresponding y positions
    if(x_0>x_1){
        exchange_value(&x_0, &x_1);
        exchange_value(&y_0, &y_1);
    }
    
    //declare variables
    int y = y_0;    //initial y position
    int delta_x = x_1-x_0; //dx change in x this is always positive bcz of the alteration above
    int delta_y = abs(y_1-y_0); //dy change in y note this is absolute value
    int error = -(delta_x/2);   //error
    int y_step = (y_0<y_1) ? 1: -1;//deceding whehter y is descending or ascending

    for (int x = x_0; x <= x_1; ++x) {
        if(is_steep)
            plot_pixel(y,x,line_colour); //plot y versus x (sicne positions have been switched)
        else
            plot_pixel(x,y,line_colour); //plot x versus y

        error = error + delta_y;        //goes to next y error increases by delta_y
        if(error>0){
            y += y_step;    //y increment by 1
            error -= delta_x;   //error decreases by delta_x
        }
    }
}

//check bounds for boxes and reverse moving directions if necessary
void incremnet_bound_check(int x, int* delta_x, int y, int* delta_y){
    int delta_x_copy = *delta_x;
    int delta_y_copy = *delta_y;
    
    if(x + (delta_x_copy) > (RESOLUTION_X-BOX_SIZE)){
        (delta_x_copy) = -1;    //if next move hits right bound, move left.
    }
    if(y + (delta_y_copy) > (RESOLUTION_Y-BOX_SIZE)){
        (delta_y_copy) = -1;    //if next move hits bottom bound, move up.

    }
    if (x + (delta_x_copy) < 0){
        (delta_x_copy) = 1;     //if next move hits left bound, move right.

    }
    if (y + (delta_y_copy) < 0){
        (delta_y_copy) = 1;     //if next move hits up bound, move down.
    }
    
    //update delta_x and delta_y.
    *delta_x = delta_x_copy;
    *delta_y = delta_y_copy;
}


uint8_t bit_code(int index)
{
    return bit_array[index % 10];
}
