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

volatile int pixel_buffer_start; // global variable

//function declarations
void draw_line(int x_0, int y_0, int x_1, int y_1, short int line_color);
void clear_screen();
void plot_pixel(int x, int y, short int line_color);

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;

    clear_screen();
    draw_line(0, 0, 150, 150, 0x001F);   // this line is blue
    draw_line(150, 150, 319, 0, 0x07E0); // this line is green
    draw_line(0, 239, 319, 239, 0xF800); // this line is red
    draw_line(319, 0, 0, 239, 0xF81F);   // this line is a pink color
}

//write colour into the passed_in pixel position
void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

//set the entire screen to black
void clear_screen(){
    for (int x = 0; x < RESOLUTION_X; ++x) {
        for (int y= 0; y < RESOLUTION_Y ; ++y) {
            plot_pixel(x,y,0);
        }
    }
}

//swap the valueso f x and y
void exchange_value(int *x, int* y){
    *x = *x^*y; //*x = *x^*y;
    *y = *x^*y; //*y = *x^*y^*y = *x;
    *x = *x^*y; //*x = *x^*y^*x^*y^*y = *x^*y^*x = *y;
}

//bresenham algorithm to draw a line
void draw_line(int x_0, int y_0, int x_1, int y_1, short int line_color){
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
    int delta_y = abs(y_1-y_0); //dy change in y note this is an absolute value
    int error = -(delta_x/2);   //error
    int y_step = (y_0<y_1) ? 1: -1;//deceding whehter y is descending or ascending

    for (int x = x_0; x <= x_1; ++x) {
        if(is_steep)
            plot_pixel(y,x,line_color); //plot y versus x (sicne positions have been switched)
        else
            plot_pixel(x,y,line_color); //plot x versus y

        error = error + delta_y;        //goes to next y error increases by delta_y
        
        
        if(error>0){
            y += y_step;    //y increment by 1
            error -= delta_x;   //error decreases by delta_x
        }
    }
}
