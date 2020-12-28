format ELF executable 3

jmp start   ; Jump to entry point


; SYSCALLS PARAMETERS

; EAX, function names

exit    = 1
read    = 3
write   = 4

; EBX, function arguments

stdin   = 0
stdout  = 1

byte_buffer db 1, 0


; SPECIAL SYMBOLS

slash_n = 0x0A   ; Newline


; TEXT STRINGS

@@: CLEAR           db @f - $, 0x1B, "[H", 0x1B, "[J"

@@: STR_INTRO       db @f - $, "Welcome to car driving simulator!", slash_n, slash_n
@@: STR_CURR_STATE  db @f - $, "Current state: "
@@: STR_READ_ACTION db @f - $, "Action (digit): "
@@: STR_ACTION      db @f - $, "Action: "
@@: STR_RESULT      db @f - $, "Result: "
@@: STR_OFFSET      db @f - $, "    "
@@: STR_NEWLINE     db @f - $, slash_n
@@: STR_TWO_NL      db @f - $, slash_n, slash_n

@@: STR_STATE_Q0    db @f - $, "q0 - rest, on the handbrake, engine shut down"
@@: STR_STATE_Q1    db @f - $, "q1 - rest, on the handbrake, engine started"
@@: STR_STATE_Q2    db @f - $, "q2 - rest, removed from the handbrake, engine started"
@@: STR_STATE_Q3    db @f - $, "q3 - on the move"
@@: STR_STATE_Q4    db @f - $, "q4 - unstable / uncontrolled"
@@: STR_STATE_Q5    db @f - $, "q5 - car abandoned"

@@: STR_INPUT_A0    db @f - $, "a0 - start engine"
@@: STR_INPUT_A1    db @f - $, "a1 - stop engine"
@@: STR_INPUT_A2    db @f - $, "a2 - remove handbrake"
@@: STR_INPUT_A3    db @f - $, "a3 - raise handbrake"
@@: STR_INPUT_A4    db @f - $, "a4 - drive"
@@: STR_INPUT_A5    db @f - $, "a5 - stop driving"
@@: STR_INPUT_A6    db @f - $, "a6 - exit car"

@@: STR_INPUT_A7    db @f - $, "unknown transition - nothing to do"

@@: STR_OUTPUT_B0   db @f - $, "b0 - success"
@@: STR_OUTPUT_B1   db @f - $, "b1 - error"
@@: STR_OUTPUT_B2   db @f - $, "b2 - nothing to do"
@@:

STR_STATE_ALL       dd STR_STATE_Q0, STR_STATE_Q1, STR_STATE_Q2, STR_STATE_Q3, STR_STATE_Q4, STR_STATE_Q5
STR_INPUT_ALL       dd STR_INPUT_A0, STR_INPUT_A1, STR_INPUT_A2, STR_INPUT_A3, STR_INPUT_A4, STR_INPUT_A5, STR_INPUT_A6, STR_INPUT_A7
STR_OUTPUT_ALL      dd STR_OUTPUT_B0, STR_OUTPUT_B1, STR_OUTPUT_B2
str_input_size = 7


; STATES

; Automate state

Q0 = 0      ; Rest, on the handbrake, engine shut down
Q1 = 1      ; Rest, on the handbrake, engine started
Q2 = 2      ; Rest, removed from the handbrake, engine started
Q3 = 3      ; On the move
Q4 = 4      ; Unstable / uncontrolled
Q5 = 5      ; Abandoned

; Automate input

A0 = 0      ; Start engine
A1 = 1      ; Stop engine
A2 = 2      ; Remove handbrake
A3 = 3      ; Raise handbrake
A4 = 4      ; Drive
A5 = 5      ; Stop driving

A6 = 6      ; Exit car
A7 = 7      ; Unknown transition

; Automate output

B0 = 0      ; Success
B1 = 1      ; Error
B2 = 2      ; Nothing to do


; TRANSITION TABLES

table_row_length = 5

Q_TABLE db  Q1, Q1, Q2, Q3, Q4, \
            Q0, Q0, Q4, Q4, Q4, \
            Q4, Q2, Q2, Q3, Q4, \
            Q0, Q1, Q1, Q4, Q4, \
            Q0, Q4, Q3, Q3, Q4, \
            Q0, Q1, Q4, Q2, Q4, \
            Q5, Q5, Q5, Q5, Q5

B_TABLE db  B0, B2, B2, B2, B1, \
            B2, B0, B1, B1, B1, \
            B1, B0, B2, B2, B1, \
            B2, B2, B0, B1, B1, \
            B2, B1, B0, B2, B1, \
            B2, B2, B2, B0, B1, \
            B0, B0, B0, B0, B0


; BASIC FUNCTIONS

; Print string
; Args: ECX - pointer to string
;       EDX - length

print:
    
    xor edx, edx    ; Reset size
    mov dl, [ecx]   ; Load value
    
    inc ecx         ; Fix real string offset
    dec edx         ; Subtract size byte
    
    mov eax, write
    mov ebx, stdout
    
    int 0x80
    
    ret


; Read byte

getchar:
    
    mov eax, read
    mov ebx, stdin
    mov ecx, byte_buffer + 1
    mov edx, 1
    
    int 0x80
    
    ret


; Clear screen

clear_screen:
    
    mov ecx, CLEAR
    call print
    
    ret


; Print state description
; Args: ESI - state

print_state:
    
    ; Offset
    
    mov ecx, STR_OFFSET
    call print
    
    ; First line
    
    mov ecx, STR_CURR_STATE
    call print
    
    mov ecx, [STR_STATE_ALL + 4 * esi]
    call print
    
    mov ecx, STR_TWO_NL
    call print
    
    ret


; Skip spaces in stdin

skip_spaces:
    
    @@:
        
        call getchar
        mov al, [byte_buffer + 1]
        
        cmp al, ' '     ; Space
        je @b
        
        cmp al, 0x09    ; Tab
        je @b
        
        cmp al, 0x0D
        je @b
        
        jmp @f
    
    @@: ret


; Read to newline in stdin

read_to_newline:
    
    @@:
        
        call getchar
        mov al, [byte_buffer + 1]
        
        cmp al, slash_n
        jne @b
    
    ret
    


; Read input from stdin

read_input:
    
    mov ecx, STR_READ_ACTION
    call print
    
    call skip_spaces    ; Read character
    
    mov di, A7          ; DI - input code
    
    ; Check if digit in range
    
    cmp al, '0' - 1
    jle @f
    
    cmp al, '0' + A6 + 1
    jge @f
    
    jmp read_input_good
    
    @@:
        ; If unexpected byte
        
        cmp al, slash_n
        je @f
        
        call read_to_newline
        
        @@: ret
    
    read_input_good:
        
        sub al, '0'
        mov di, ax
        
        ; Read next symbol
        
        call skip_spaces
        
        cmp al, slash_n
        je @f
        
        ; If not newline
        
        mov di, A7
        call read_to_newline
        
        @@: ret
    
    ret


; Print descriptions of available actions

print_actions:
    
    xor ebp, ebp
    
    @@:
        
        mov ecx, [STR_INPUT_ALL + 4 * ebp]
        call print
        
        mov ecx, STR_NEWLINE
        call print
        
        ; Decrease counter
        
        inc ebp
        cmp ebp, str_input_size
        
        jne @b
    
    mov ecx, STR_NEWLINE
    call print
    
    ret


; Print action description
; Args: EDI - action code

print_action:
    
    mov ecx, STR_OFFSET
    call print
    
    mov ecx, STR_ACTION
    call print
    
    mov ecx, [STR_INPUT_ALL + 4 * edi]
    call print
    
    mov ecx, STR_NEWLINE
    call print
    
    ret


; Prints result of action

print_result:
    
    mov ecx, STR_OFFSET
    call print
    
    mov ecx, STR_RESULT
    call print
    
    mov ecx, [STR_OUTPUT_ALL + 4 * ebp]
    call print
    
    mov ecx, STR_NEWLINE
    call print
    
    ret

; Handle action

handle_input:
    
    ; Calculating offset
    
    mov eax, edi
    mov ebx, table_row_length
    mul ebx
    add eax, esi
    
    ; Use Q_TABLE offset
    
    mov ebp, eax
    add ebp, Q_TABLE
    
    xor ebx, ebx
    
    mov bl, [ebp]
    mov esi, ebx    ; ESI - state register
    
    ; Use B_TABLE offset
    
    sub ebp, Q_TABLE
    add ebp, B_TABLE
    
    mov bl, [ebp]
    mov ebp, ebx
    
    ret


; Exit with code 0

quit:
    
    mov eax, exit
    mov ebx, 0
    
    int 0x80



; ENTRY POINT

start:
    
    xor edi, edi    ; Reset action code
    
    ; Clear screen
    
    call clear_screen
    
    ; Print intro
    
    mov ecx, STR_INTRO
    call print
    
    ; Initialize automate state
    
    mov esi, Q0     ; Initial state - Q0
    
    
    ; Commands loop
    
    next_command:
        
        call print_state
        call print_actions
        call read_input
        call clear_screen
        
        mov ecx, STR_NEWLINE
        call print
        
        call print_action
        
        cmp di, A7
        
        jne @f
        
        mov ecx, STR_NEWLINE
        call print
        
        jmp continue
        
        @@:
            
            ; Handle and print result of action
            
            call handle_input
            call print_result
        
        continue:
        
        mov ecx, STR_NEWLINE
        call print
        
        ; Exit if abandoned
        
        cmp esi, Q5
        je quit
        
        jmp next_command
