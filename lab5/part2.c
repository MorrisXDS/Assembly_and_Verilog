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
#define BOX_LEN 2
#define NUM_BOXES 8

#define FALSE 0
#define TRUE 1


#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>

// Begin part1.s for Lab 7
volatile int pixel_buffer_start;// global variable

//function declarations
void draw_line(int x_0, int y_0, int x_1, int y_1, short int line_colour);
void clear_screen();
void bound_check(int y, int* dy);
void sync();
void plot_pixel(int x, int y, short int line_colour);

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;
    //clear any previous drawing
    clear_screen();
    
    //initialize x, y positions, next move of y and last position of y
    int x_0  = 20;
    int x_1 = 300;
    int y  = 0;
    int dy = 1;
    int previous_y = 0;
    
    //draw the first line
    draw_line(x_0, y, x_1, y, 0xFFFF);
    
    while(1){
        sync();//sync and draw
        previous_y = y; //update the last position of y
        bound_check(y, &dy);//check if next move goes overbound
        y += dy;//update y position
        draw_line(x_0, previous_y, x_1, previous_y, 0x0000);//set black the last line
        draw_line(x_0, y, x_1, y, 0xFFFF);//draw the current line
    }
}



//plot pixels at the passed-in locatin with line_colour
void plot_pixel(int x, int y, short int line_colour)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_colour;
}


//check if next move is out of bound
void bound_check(int y, int* dy){
    if(y+(*dy) > RESOLUTION_Y){ //if go over bottom bound, move up
        (*dy) = -1;
    }
    else if(y+(*dy) < 0){   //if go overr up bound, move down
        (*dy) = 1;
    }
}

//sync and wait for drawing to finish
void sync(){
    volatile int * buffer = (int *)0xFF203020;
    int status;

    *buffer = 1;            //start synchronization
    status = *(buffer+3);   //get the content of status register

    while((status & 0x01) != 0){    //do polling until drawing is finished
        status = *(buffer+3);
    }
}

//put the whole screen back to black
void clear_screen(){
    for (int x = 0; x < RESOLUTION_X; ++x) {
        for (int y= 0; y < RESOLUTION_Y ; ++y) {
            plot_pixel(x,y,0);
        }
    }
}

//swap positions of two integers. Assume they do not point to the same memory location
void exchange_value(int *x, int* y){
    *x = *x^*y; //*x = *x^*y;
    *y = *x^*y; //*y = *x^*y^*y = *x;
    *x = *x^*y; //*x = *x^*y^*x^*y^*y = *x^*y^*x = *y;
}

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
