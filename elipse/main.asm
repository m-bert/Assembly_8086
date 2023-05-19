;================================================================================================================================
; Defined constants

;--------------------------------------------------------------------------------------------------------------------------------
; Keys
;--------------------------------------------------------------------------------------------------------------------------------
ESCAPE equ 01h
LEFT equ 4Bh
RIGHT equ 4Dh
UP equ 48h
DOWN equ 50h
KEY_R equ 13h
KEY_G equ 22h
KEY_B equ 30h
SPACE equ 39h

;--------------------------------------------------------------------------------------------------------------------------------
; Elipse parameters
;--------------------------------------------------------------------------------------------------------------------------------
CENTER_X equ 160 
CENTER_Y equ 100
MIN_X_RADIUS equ 1
MAX_X_RADIUS equ 159
MIN_Y_RADIUS equ 1
MAX_Y_RADIUS equ 99


;--------------------------------------------------------------------------------------------------------------------------------
; SCREEN
;--------------------------------------------------------------------------------------------------------------------------------
SCREEN_WIDTH equ 320
SCREEN_HEIGHT equ 200
MAX_COLOR equ 255
;================================================================================================================================

.387                                                                        ; Directive that allows us to use FPU

;================================================================================================================================
; Data segment
my_data segment
    parse_buffer db 50, ?, 50 dup('$')
    new_line db 10, 13, '$'
    invalid_arguments_number_msg db "Bledna ilosc argumentow wejsciowych!", 10, 13, '$'
    invalid_argument_msg db "Jeden z argumentow wejsciowych nie jest liczba!", 10, 13, '$'
    invalid_radius_msg db "Podano nieprawidlowe promienie!", 10, 13, '$'
my_data ends
;================================================================================================================================

;================================================================================================================================
;   Overview
;
;   This is a program that uses VGA mode to draw elipse on screen in Assembly 8086 MASM
;
;   To start the program we need to pass two parameters - x and y radius for the elipse
;   Then we can change both of them using arrow keys:
;       - Arrow_up increments y radius
;       - Arrow_down decrements y radius
;       - Arrow_left decrements x radius
;       - Arrow_right increments x radius
;
;   We can also change colors of the elipse:
;       - R key changes color to red
;       - G key changes color to green
;       - B key changes color to blue
;       - Space increments color value by 1, and if overflow is to happen, resets color value to 0
;
;   The elipse is drawn with usage of elipse equation. First we solve the equation to get y in terms of x, which gives us:
;       y = r_y * sqrt(1-x^2/r_x^2)
;   However using only this values will result in not closing left and right part of the elipse, since we won't get value of 0.
;   To fix that, we analitically solve equation for x in terms of y. That gives us:
;       x = r_x * sqrt(1-y^2/r_y^2)
;
;   Now we can combine both of the results which will cover all points in a first quadrant.
;   Using symmetry of elipse, we only calculate values in first quadrant, and then apply symmetry to get all four points
;   Also all calculations are done with respsect to center of elipse at (0,0). Later translation is applied, ti move points
;   to actual place of the elipse (with center at 160, 100).
;================================================================================================================================


;================================================================================================================================
; Code segment
my_code segment
    main:
        ; Set stack
        mov ax, seg my_stack                                                ; Store stack segment address in ax
        mov ss, ax                                                          ; Move address of stack to stack segment register
        mov sp, offset stack_top                                            ; Move stack top to stack pointer

        ; Copy PSP to args variable
        mov ax, seg args                                                    ; Move to ax segment of args variable
        mov es, ax                                                          ; Store args segement in extra segment (command line arguments are currently in DS
                                                                            ; so we don't want to lose them
        mov si, 082h                                                        ; 082h - address of first PSP character
        mov di, offset args                                                 ; Moving to destination index offset of args variable

        xor cx, cx                                                          ; Clean CX register
        mov cl, byte ptr ds:[080h]                                          ; Store in cl amount of characters in PSP

        cld                                                                 ; Set direction change mode in indexing registers to positive
        rep movsb                                                           ; Instruction that copies command line arguments to args variable

        ; Set data segment to my_data
        mov ax, seg my_data                                                 ; Move data segment to ax   
        mov ds, ax                                                          ; Set ds value to my_data segment

        ; Parse line
        mov bx, 0                                                           ; bx will be used as counter for number of arguments, so we set this to 0

        mov si, offset args                                                 ; Set source index to arguments from PSP
        mov di, offset parse_buffer + 2                                     ; Set destination index to parse buffer

        cmp byte ptr cs:[si], '$'                                           ; If first character in command line arguments is '$', that means, that arguments
        je fail_invalid_arguments_number                                    ; were not provided and we have to end program

        ;--------------------------------------------------------------------------------------------------------------------------------
        ; parse_loop - loop that scans each character from arguments and after receiving ' ' or '$' proceedes to recognize token
        ;--------------------------------------------------------------------------------------------------------------------------------
        parse_loop:
            mov al, byte ptr cs:[si]                                        ; Read character from source into al

            cmp al, 32                                                      ; If character is space, we either found token, or a sequeance of spaces
            je handle_separator                                             ; so we call handle separator to check which situation occurred

            cmp al, 13                                                      ; If character is '$', we either found token, or finished input with sequence
            je handle_separator                                             ; of spaces, so we call handle separator to check which situation occurred

            mov byte ptr ds:[di], al                                        ; Copy character from input into parse buffer

            inc si                                                          ; Increment si to point to next character of input buffer
            inc di                                                          ; Increment di to point to next character of parse buffer

            jmp parse_loop                                                  ; Loop back to find rest of tokens

        ;--------------------------------------------------------------------------------------------------------------------------------
        ; handle_separator - procedure that analyzes parse buffer after reading ' ' or '$'
        ;--------------------------------------------------------------------------------------------------------------------------------
        handle_separator:
            mov di, offset parse_buffer + 2                                 ; Set di to point to first character of parse buffer
            mov dl, byte ptr ds:[di]                                        ; Set dl value to first character of parse buffer
                                                                            ; Here dl is used, because later on program checks if al, that currently
                                                                            ; points to last read character from user input is '$', so it is better to use dl
                                                                            ; instead of putting ax on stack and then popping it (dx is not in use at that point)
            
            cmp dl, '$'                                                     ; Check if first character of parse buffer is '$'
            jne parse_number                                                ; If it isn't, it means that parse buffer contains token and we have to map it to
                                                                            ; operators used in our program

            cmp al, 13                                                      ; If last character was 13 and parse buffer is empty,
            je check_arguments                                              ; we can proceed to check whether arguments are valid

            inc si                                                          ; Otherwise, if character was ' ' and parse buffer is empty
            jmp parse_loop                                                  ; we go back to parsing loop to find next token


    ;--------------------------------------------------------------------------------------------------------------------------------
    ; parse_number - procedure that converts string to a number
    ;--------------------------------------------------------------------------------------------------------------------------------
    parse_number:
        push bx                                                             ; Store current amount of arguments on stack
        push ax                                                             ; Store ax on stack (because al contains last read character)

        mov ax, 0                                                           ; ax now represents current result of conversion
        mov bx, 10                                                          ; bx stands for system basis (i.e. 10)

        xor cx, cx                                                          ; cx will hold current digit (because dx is used in multiplication)

        parse_number_loop:
            mov cl, byte ptr ds:[di]                                        ; Get next digit from argument

            cmp cl, '$'                                                     ; If we reached '$', that means that parsing has been finished
            je end_parsing_number   

            sub cl, '0'                                                     ; Subtract from current digit '0', which will result in cl holding actual value of digit, not ascii code

            cmp cl, 0                                                       ; If value is less than 0, that means that character wasn't actually a digit
            jl fail_invalid_argument                                        ; We end program with fail message

            cmp cl, 9                                                       ; If value is greater than 9, that means that character wasn't actually a digit
            jg fail_invalid_argument                                        ; We end program with fail message

            mul bx                                                          ; Multiply current result by 10
            add ax, cx                                                      ; Add current digit to result

            inc di                                                          ; Move destination index to next digit
            jmp parse_number_loop                                           ; Loop back to convert whole number

            end_parsing_number:
                mov dx, ax                                                  ; Store result in dx, because we want to store it on stack. However, we also want to pop 
                                                                            ; previous value of ax

                pop ax                                                      ; Restore ax to value before conversion
                pop bx                                                      ; Restore bx to value before conversion

                push dx                                                     ; Store converted value on stack

                jmp back_to_parsing                                         ; Go back to main barsing loop

        back_to_parsing:
            inc bx                                                          ; Inrement arguments counter
            inc si                                                          ; increment source index counter

            cmp al, 13                                                      ; If last read character was 13, there are no more arguments to parse and we can check if 
            je check_arguments                                              ; user entered right amount of arguments

            call clear_buffer                                               ; Otherwise we clear the buffer

            mov di, offset parse_buffer + 2                                 ; Set di to point to the beginning of parse buffer
            jmp parse_loop                                                  ; Go back to main parsing loop

    check_arguments:
        cmp bx, 2                                                           ; Check if user entered exactly 2 parameters
        jne fail_invalid_arguments_number                                   ; If not, we exit program with proper error message
    
        pop ax                                                              ; Get first parameter from stack

        cmp ax, MIN_Y_RADIUS                                                ; Check if y-radius is correct value (ie. that elipse with this parameter will fit on screen)
        jl fail_invalid_radius                                               ; If not, we exit program with proper error message
        cmp ax, MAX_Y_RADIUS
        jg fail_invalid_radius

        mov word ptr cs:[r_y], ax                                           ; Store first parameter in r_y variable 

        pop ax                                                              ; Get second parameter from stack

        cmp ax, MIN_X_RADIUS                                                ; Similar to y-radius situation
        jl fail_invalid_radius
        cmp ax, MAX_X_RADIUS
        jg fail_invalid_radius

        mov word ptr cs:[r_x], ax                                           ; Store second parameter in r_x variable 
        
        jmp init_gui                                                        ; Start graphic interface

    init_gui:
        mov al, 13h                                                         ; Code for DOS interruption, that sets gui to 320x200 mode with 256 colors
        mov ah, 0                                                           ; Code for DOS interruption to start graphic mode
        int 10h                                                             ; DOS interruption that starts the graphic interface

        elipse_loop:                                                        ; Main loop of program
            call clear_screen                                               ; Clear screen so that we see only one elipse at a time
            call draw                                                       ; Draw elipse to the screen
            call handle_key                                                 ; Wait for user to press a key

            jmp elipse_loop                                                 ; Loop back


    ;--------------------------------------------------------------------------------------------------------------------------------
    ; clear_screen - procedure that clears screen
    ;--------------------------------------------------------------------------------------------------------------------------------
    clear_screen:
        mov ax, 0a000h                                                      ; Move to ax beginning of graphics memory
        mov es, ax                                                          ; Store this address in es

        xor ax, ax                                                          ; Clear ax register
        mov di, ax                                                          ; Set di to 0

        cld                                                                 ; Set flag for chain instruction. This effectively results in di += 1 after each call of chain instruction
        mov cx, SCREEN_WIDTH * SCREEN_HEIGHT                                ; Set number of calls for chain instruction
        rep stosb                                                           ; Call change instruction that will clear whole graphics memory

        ret                                                                 ; Return from procedure

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; handle_key - procedure that gets key pressed by user
    ;--------------------------------------------------------------------------------------------------------------------------------
    handle_key:
        in al, 60h                                                          ; Instruction that will store in al last pressed key

        cmp al, ESCAPE                                                      ; If the key was esc, we finish program
        je restore_text_interface

        cmp al, byte ptr cs:[last_pressed_key]                              ; Pressing key generates two different scan codes - one on press and another one on release
        je handle_key                                                       ; We can use this to check, whether key was released, so we won't perform action infinitely many times

        mov byte ptr cs:[last_pressed_key], al                              ; Store last pressed key in last_pressed_key variable, to make comparison above possible

        cmp al, LEFT                                                        ; Here we will check which key was pressed, and then proceed with action
        je left_key

        cmp al, RIGHT
        je right_key

        cmp al, UP
        je up_key

        cmp al, DOWN
        je down_key

        cmp al, KEY_R
        je r_key

        cmp al, KEY_G
        je g_key

        cmp al, KEY_B
        je b_key

        cmp al, SPACE
        je space_key

        ret                                                                 ; Unrecognized key

        left_key:
            mov bx, offset r_x                                              ; Store offset of radius in bx variable - this will serve as a parameter for decrement_radius procedure
            cmp word ptr cs:[r_x], 1                                        ; If we can decrement radius, we will do this
            jg decrement_radius

            ret                                                             ; Otherwise we return

        right_key:                                                          ; Same as above, but for increment
            mov bx, offset r_x 
            cmp word ptr cs:[r_x], 159
            jl increment_radius

            ret

        up_key:
            mov bx, offset r_y
            cmp word ptr cs:[r_y], 99
            jl increment_radius

            ret

        down_key:
            mov bx, offset r_y
            cmp word ptr cs:[r_y], 1
            jg decrement_radius

            ret

            ;--------------------------------------------------------------------------------------------------------------------------------
            ; decrement_radius - procedure that decrements radius passed in bx
            ;--------------------------------------------------------------------------------------------------------------------------------
            decrement_radius:
                dec word ptr cs:[bx]                                        ; Decrement radius
                ret                                                         ; Go back to main loop
            
            ;--------------------------------------------------------------------------------------------------------------------------------
            ; increment_radius - procedure that increments radius passed in bx
            ;--------------------------------------------------------------------------------------------------------------------------------
            increment_radius:
                inc word ptr cs:[bx]                                        ; Increment radius
                ret                                                         ; Go back to main loop

        r_key:
            mov  byte ptr cs:[color], 40                                    ; If key was 'r', change color to red
            ret

        g_key:
            mov  byte ptr cs:[color], 50                                    ; If key was 'g', change color to green
            ret

        b_key:
            mov  byte ptr cs:[color], 55                                    ; If key was 'b', change color to blue
            ret

        space_key:
            cmp byte ptr cs:[color], MAX_COLOR                              ; If we cannot increment color variable (because it would cause overflow), we reset it to 0
            je reset_color                  

            inc byte ptr cs:[color]                                         ; Otherwise we increment color

            ret

            reset_color:
                mov byte ptr cs:[color], 0                                  ; Reset color to 0                
                ret                                                        


    ;--------------------------------------------------------------------------------------------------------------------------------
    ; draw - procedure that calls calculations and highlight points on the elipse
    ;--------------------------------------------------------------------------------------------------------------------------------  
    draw:
        mov word ptr cs:[x], 0                                              ; Set starting point to (0,0)
        mov word ptr cs:[y], 0
        mov cx, word ptr cs:[r_x]                                           ; We will calculate value for each X on interval [0, x_radius]    
        

        elipse_draw_loop_from_x:                                            ; This loops calculate Y values based on X coordinate

            call calculate_elipse_from_x                                    ; Perform calculation
            call highlight_points                                           ; Highlight calculated points
            inc word ptr cs:[x]                                             ; Move to next X coordinate

            loop elipse_draw_loop_from_x                                    ; Loop back

        mov word ptr cs:[x], 0                                              ; Reset starting point
        mov word ptr cs:[y], 0
        mov cx, word ptr cs:[r_y]                                           ; Now we will iterate on Y values on the interval [0, y_radius]

        elipse_draw_loop_from_y:                                            ; This loops works like the previous one

            call calculate_elipse_from_y
            call highlight_points
            inc word ptr cs:[y]

            loop elipse_draw_loop_from_y

        ret                                                                 ; Go back to main loop
    ;--------------------------------------------------------------------------------------------------------------------------------
    ; calculate_elipse_from_x - procedure that calculates Y coordinates based on X coordinates with equation y = r_y * sqrt(1 - x^2/r_x^2)
    ;--------------------------------------------------------------------------------------------------------------------------------  
    calculate_elipse_from_x:
        finit                                                               ; Start calculations on FPU

        fild        word ptr cs:[x]                                         ; Put x value on stack
        fmul        st(0), st(0)                                            ; Square x

        fild        word ptr cs:[r_x]                                       ; Put r_x value on stack
        fmul        st(0), st(0)                                            ; Square r_x

        fdivp       st(1), st(0)                                            ; Divide x^2 by r_x^2

        fld1                                                                ; Put 1 value on stack

        fsub        st(0), st(1)                                            ; Subtract from 1 value ov x^2 divided by r_x^2

        fsqrt                                                               ; Calculate square root of the value above

        fild        word ptr cs:[r_y]                                       ; Put on stack value of r_y
        fmul                                                                ; Multiply last result by r_y

        fist        word ptr cs:[y]                                         ; Now retrieve calculated value to y variable

        ret                                                                 ; Return to drawing loop

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; calculate_elipse_from_y - procedure that calculates X coordinates based on Y coordinates with equation x = r_x * sqrt(1 - y^2/r_y^2)
    ;--------------------------------------------------------------------------------------------------------------------------------  
    calculate_elipse_from_y:
        finit                                                               ; Start calculations on FPU

        fild        word ptr cs:[y]                                         ; Put y value on stack
        fmul        st(0), st(0)                                            ; Square y

        fild        word ptr cs:[r_y]                                       ; Put r_y value on stack
        fmul        st(0), st(0)                                            ; Square r_y

        fdivp       st(1), st(0)                                            ; Divide y^2 by r_y^2

        fld1                                                                ; Put 1 value on stack

        fsub        st(0), st(1)                                            ; Subtract from 1 value ov y^2 divided by r_y^2

        fsqrt                                                               ; Calculate square root of the value above

        fild        word ptr cs:[r_x]                                       ; Put on stack value of r_x
        fmul                                                                ; Multiply last result by r_x

        fist        word ptr cs:[x]                                         ; Now retrieve calculated value to y variable

        ret                                                                 ; Return to drawing loop

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; highlight_points - procedure that highlights four points on elipse based on calculated one
    ; To highlight point at (x, y) we have to pass offset, calculated by the equation offset = y * screen_width + x
    ;--------------------------------------------------------------------------------------------------------------------------------  
    highlight_points:
        mov     ax, 0a000h                                                  ; Move to ax beginning of graphics memory
        mov     es, ax                                                      ; Store this address in es  

        ; First point (x, y)
        mov     ax, CENTER_Y                                                ; Move to ax y coordinate of center of elipse
        add     ax, word ptr cs:[y]                                         ; Add to ax value of y coordinate

        mov     bx, SCREEN_WIDTH                                            ; Set bx to screen width
        mul     bx                                                          ; Multiply ax by screen width

        mov     bx, CENTER_X                                                ; Move to bx value of x coordinate of center of elipse
        add     bx, word ptr cs:[x]                                         ; Now add to bx actual value of x coordinate

        add     bx, ax                                                      ; Add ax to bx, so we get offset on memory at which we have to draw point
        mov     al, byte ptr cs:[color]                                     ; Store in al color of the point

        mov     byte ptr es:[bx], al                                        ; Draw point on screen

        ; Code below works in the same manner, but highlights 3 other points of elipse

        ; Second point (-x, -y)
        mov     ax, CENTER_Y
        sub     ax, word ptr cs:[y]

        mov     bx, SCREEN_WIDTH
        mul     bx

        mov     bx, CENTER_X
        sub     bx, word ptr cs:[x]

        add     bx, ax
        mov     al, byte ptr cs:[color]
        mov     byte ptr es:[bx], al

        ; Third point (-x, y)
        mov     ax, CENTER_Y
        add     ax, word ptr cs:[y]

        mov     bx, SCREEN_WIDTH
        mul     bx

        mov     bx, CENTER_X
        sub     bx, word ptr cs:[x]

        add     bx, ax
        mov     al, byte ptr cs:[color]
        mov     byte ptr es:[bx], al

        ; Forth point (x, -y)
        mov     ax, CENTER_Y
        sub     ax, word ptr cs:[y]

        mov     bx, SCREEN_WIDTH
        mul     bx

        mov     bx, CENTER_X
        add     bx, word ptr cs:[x]

        add     bx, ax
        mov     al, byte ptr cs:[color]
        mov     byte ptr es:[bx], al

        ret                                                                 ; Go back to main loop


    ;--------------------------------------------------------------------------------------------------------------------------------
    ; fail_invalid_arguments - procedure that ends program when either first or last argument is not a digit
    ;--------------------------------------------------------------------------------------------------------------------------------
    fail_invalid_argument:
        mov dx, offset invalid_argument_msg                                 ; Set my_print parameter to invalid_arguments_msg
        call my_print                                                       ; Display error message
        jmp end_program                                                     ; Exit program

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; fail_invalid_arguments_number - procedure that ends program when user entered wrong amount of arguments
    ;--------------------------------------------------------------------------------------------------------------------------------
    fail_invalid_arguments_number:
        mov dx, offset invalid_arguments_number_msg                         ; Set my_print parameter to invalid_arguments_number_msg
        call my_print                                                       ; Display error message
        jmp end_program                                                     ; Exit program

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; fail_invalid_radius - procedure that ends program when user entered wrong radius
    ;--------------------------------------------------------------------------------------------------------------------------------
    fail_invalid_radius:
        mov dx, offset invalid_radius_msg                                   ; Set my_print parameter to invalid_radius_msg
        call my_print                                                       ; Display error message
        jmp end_program                                                     ; Exit program
    

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; clear_buffer - procedure that clears parse buffer after mapping token
    ;--------------------------------------------------------------------------------------------------------------------------------
    clear_buffer:
        push ax                                                             ; Store value of ax on stack, because it will be modified in this procedure
        mov al, '$'                                                         ; Move end of string char to al

        mov di, offset parse_buffer + 2                                     ; Set di to beginning of parse buffer
        mov cx, 50                                                          ; Parse buffer has length 50, so we put 50 into cx to loop 50 times

        ;--------------------------------------------------------------------------------------------------------------------------------
        ; clear_loop - loop that resets each of parse buffer characters to '$'
        ;--------------------------------------------------------------------------------------------------------------------------------
        clear_loop:
            mov byte ptr ds:[di], al                                        ; Replace character at [di] with '$'
            inc di                                                          ; Increment di to point to next character
            loop clear_loop                                                 ; Loop back to clear whole buffer

        pop ax                                                              ; Get back original value of ax

        ret                                                                 ; Return from procedure

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; my_print - procedure that prints string 
    ;
    ; Parameters:
    ; dx: offset of string to be printed
    ;--------------------------------------------------------------------------------------------------------------------------------
    my_print:
        push ax                                                             ; Store value of ax on stack, because it will be modified in this procedure              

        mov ax, seg my_data                                                 ; Move my_data segment to ax
        mov ds, ax                                                          ; Move my_data segment from ax to ds

        mov ah, 09h                                                         ; 09h - code for printing string
        int 21h                                                             ; 21h - DOS interruption (with flag 09h)

        pop ax                                                              ; Get back original value of ax

        ret      
        
                                                               ; Return from procedure                                        
        
    ;================================================================================================================================
    ; end_program - procedure that terminates program
    ;================================================================================================================================
    restore_text_interface:
        call clear_screen                                                   ; Clear screen before going back to text interface

        mov ax, 3h                                                          ; Code for DOS interruption, that resets DOS to text interface
        int 10h                                                             ; DOS interruption that starts the graphic interface
        jmp end_program
    ;================================================================================================================================
    ; end_program - procedure that terminates program
    ;================================================================================================================================
    end_program:
        mov ah, 4Ch                                                         ; 4Ch - code to exit program
        int 21h                                                             ; 21h - DOS interruption (with flag 09h)

; Variables
args db 200 dup('$')                                                        ; PSP arguments
r_x dw ?                                                                    ; X radii for elipse
r_y dw ?                                                                    ; Y radii for elipse
x dw ?                                                                      ; x point 
y dw ?                                                                      ; y point
color db 13                                                                  ; c point
last_pressed_key db ?                                                       ; Scan code of last pressed key
        
my_code ends
;================================================================================================================================

;================================================================================================================================
; STACK SEGMENT
my_stack segment stack                                                      ; Declare stack segment
    dw 300 dup(?)                                                           ; Declare stack size
    stack_top dw ?                                                          ; Declare stack top
my_stack ends  
;================================================================================================================================

end main                                                                    ; Entry point for program


