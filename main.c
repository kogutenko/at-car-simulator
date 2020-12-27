#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>


/* TEXT STRINGS */

const char *STR_INTRO       = "Welcome to car driving simulator!\n\n";

const char *STR_CURR_STATE  = "Current state:\n";
const char *STR_READ_ACTION = "Action (digit): ";
const char *STR_AVAIL_ACTS  = "Available actions:\n\n";

const char *STR_ACTION      = "Action: ";
const char *STR_RESULT      = "Result: ";

const char *STR_OFFSET      = "    ";

const char *STR_STATE_Q0    = "q0 - rest, on the handbrake, engine shut down";
const char *STR_STATE_Q1    = "q1 - rest, on the handbrake, engine started";
const char *STR_STATE_Q2    = "q2 - rest, removed from the handbrake, engine started";
const char *STR_STATE_Q3    = "q3 - on the move";
const char *STR_STATE_Q4    = "q4 - unstable / uncontrolled";
const char *STR_STATE_Q5    = "q5 - car abandoned";

const char *STR_INPUT_A0    = "a0 - start engine";
const char *STR_INPUT_A1    = "a1 - stop engine";
const char *STR_INPUT_A2    = "a2 - remove handbrake";
const char *STR_INPUT_A3    = "a3 - raise handbrake";
const char *STR_INPUT_A4    = "a4 - drive";
const char *STR_INPUT_A5    = "a5 - stop driving";
const char *STR_INPUT_A6    = "a6 - exit car";

const char *STR_INPUT_A7    = "Unknown transition - nothing to do";

const char *STR_OUTPUT_B0   = "b0 - success";
const char *STR_OUTPUT_B1   = "b1 - error";
const char *STR_OUTPUT_B2   = "b2 - nothing to do";



/* STATES */

typedef enum
{
    Q0 = 0, // Rest, on the handbrake, engine shut down
    Q1,     // Rest, on the handbrake, engine started
    Q2,     // Rest, removed from the handbrake, engine started
    Q3,     // On the move
    Q4,     // Unstable / uncontrolled
    Q5      // Abandoned
} STATE;


typedef enum
{
    A0 = 0, // Start engine
    A1,     // Stop engine
    A2,     // Remove handbrake
    A3,     // Raise handbrake
    A4,     // Drive
    A5,     // Stop driving
    
    A6,     // Exit car
    A7      // Unknown transition
} INPUT;


typedef enum
{
    B0 = 0, // Success
    B1,     // Error
    B2      // Nothing to do
} OUTPUT;



/* TRANSITION TABLES */

const STATE Q_TABLE[7][5] =
{
    {Q1, Q1, Q2, Q3, Q4},
    {Q0, Q0, Q4, Q4, Q4},
    {Q4, Q2, Q2, Q3, Q4},
    {Q0, Q1, Q1, Q4, Q4},
    {Q0, Q4, Q3, Q3, Q4},
    {Q0, Q1, Q4, Q2, Q4},
    
    {Q5, Q5, Q5, Q5, Q5}
};

const OUTPUT B_TABLE[7][5] =
{
    {B0, B2, B2, B2, B1},
    {B2, B0, B1, B1, B1},
    {B1, B0, B2, B2, B1},
    {B2, B2, B0, B1, B1},
    {B2, B1, B0, B2, B1},
    {B2, B2, B2, B0, B1},
    
    {B0, B0, B0, B0, B0}
};



/* FUNCTIONS IMPLEMENTATIONS */

/* Print intro and available actions */

void clear_screen()
{
	#ifdef _WIN32
		system("cls");
	#else
		system("clear");
	#endif
}


void print_actions()
{
    printf("%s", STR_INPUT_A0); putchar('\n');
    printf("%s", STR_INPUT_A1); putchar('\n');
    printf("%s", STR_INPUT_A2); putchar('\n');
    printf("%s", STR_INPUT_A3); putchar('\n');
    printf("%s", STR_INPUT_A4); putchar('\n');
    printf("%s", STR_INPUT_A5); putchar('\n');
    printf("%s", STR_INPUT_A6); putchar('\n');
	
	putchar('\n');
}


/* Print greeting */

void print_intro()
{
    printf("%s", STR_INTRO);
}


/* Read symbol with skipping spaces */

char skip_spaces()
{
    char current = getchar();
    
    while(!feof(stdin) && (current == ' ' || current == '\t' || current == '\r'))
        current = getchar();
    
    return current;
}


/* Skip characters before the newline */

void skip_to_newline()
{
    char symbol = getchar();
    
    while(!feof(stdin) && symbol != '\n')
        symbol = getchar();
}


/* Read next input symbol */

INPUT read_input()
{
    printf("%s", STR_READ_ACTION);
    
    char symbol = skip_spaces();
    
    INPUT input;
    
    if(feof(stdin)) {
        
        input = A6;
        
    } else if(isdigit(symbol)) {
        
        if(symbol > A6 + '0') {
            
            /* Unknown transition */
            
            input = A7;
            
        } else input = (INPUT)(symbol - '0');
        
        
        char next_symbol = skip_spaces();
        
        if(next_symbol != '\n')
        {
            /* Few symbols - unknown transition */
            
            input = A7;
            
            /* Skipping symbols before the newline */
            
            skip_to_newline();
        }
        
    } else {
        
        input = A7;
        
        if(symbol != '\n') skip_to_newline();
    }
    
    return input;
}


/* Print state description */

void print_state(STATE state)
{
    printf("%s", STR_CURR_STATE);
    
    printf("%s", STR_OFFSET);
    
    switch(state)
    {
        case Q0: printf("%s", STR_STATE_Q0); break;
        case Q1: printf("%s", STR_STATE_Q1); break;
        case Q2: printf("%s", STR_STATE_Q2); break;
        case Q3: printf("%s", STR_STATE_Q3); break;
        case Q4: printf("%s", STR_STATE_Q4); break;
        case Q5: printf("%s", STR_STATE_Q5); break;
    }
    
    printf("%s", "\n\n");
}


/* Print actions description */

void print_action(INPUT input)
{
    printf("%s", STR_OFFSET);
    
    printf("%s", STR_ACTION);
    
    switch(input)
    {
        case A0: printf("%s", STR_INPUT_A0); break;
        case A1: printf("%s", STR_INPUT_A1); break;
        case A2: printf("%s", STR_INPUT_A2); break;
        case A3: printf("%s", STR_INPUT_A3); break;
        case A4: printf("%s", STR_INPUT_A4); break;
        case A5: printf("%s", STR_INPUT_A5); break;
        case A6: printf("%s", STR_INPUT_A6); break;
        case A7: printf("%s", STR_INPUT_A7); break;
    }
    
    printf("%s", "\n");
}


/* Print result */

void print_result(OUTPUT result)
{
    printf("%s", STR_OFFSET);
    
    printf("%s", STR_RESULT);
    
    switch(result)
    {
        case B0: printf("%s", STR_OUTPUT_B0); break;
        case B1: printf("%s", STR_OUTPUT_B1); break;
        case B2: printf("%s", STR_OUTPUT_B2); break;
    }
    
    printf("%s", "\n\n");
}


/* Handle input and change state */

OUTPUT handle_input(STATE *state, INPUT input)
{
    STATE old_state = *state;
    
    *state = Q_TABLE[input][old_state];
    
    return B_TABLE[input][old_state];
}



int main()
{
    STATE state = Q0;
	
	clear_screen();
    
    print_intro();
    
    do
    {
        print_state(state);
		
		print_actions();
        
        INPUT input = read_input();
		
		clear_screen();
		
		putchar('\n');
        
        if(input == A7) {
            
            print_action(input);
            
            printf("%s", "\n\n");
            
        } else {
            
            print_action(input);
            
            OUTPUT result = handle_input(&state, input);
            
            print_result(result);
        }
		
    } while(state != Q5);
    
    return 0;
}
