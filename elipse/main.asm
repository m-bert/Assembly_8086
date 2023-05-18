;================================================================================================================================
; DATA SEGMENT
my_data segment
    parse_buffer db 50, ?, 50 dup('$')
    new_line db 10, 13, '$'
    invalid_arguments_number_msg db "Bledna ilosc argumentow wejsciowych!", 10, 13, '$'
    invalid_argument_msg db "Jeden z argumentow wejsciowych nie jest liczba!", 10, 13, '$'

my_data ends
;================================================================================================================================

;================================================================================================================================
; CODE SEGMENT
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
        jg fail_invalid_arguments_number                                    ; If not, we exit program with proper error message

        cmp bx, 1
        jle fail_invalid_arguments_number
    
        pop ax                                                              ; Get first parameter from stack and store it in r_x variable 
        mov word ptr cs:[r_x], ax

        pop ax                                                              ; Get second parameter from stack and store it in r_y variable
        mov word ptr cs:[r_y], ax 
        
        jmp init_gui                                                        ; Start graphic interface

    init_gui:

        mov al, 13h                                                         ; Code for DOS interruption, that sets gui to 320x200 mode with 256 colors
        mov ah, 0                                                           ; Code for DOS interruption to start graphic mode
        int 10h                                                             ; DOS interruption that starts the graphic interface


        elipse_loop:
            ; call clear
            ; call handle_key
            ; call draw


        mov ax, 3h                                                         ; Code for DOS interruption, that sets gui to 320x200 mode with 256 colors
        int 10h                                                             ; DOS interruption that starts the graphic interface

        jmp end_program


















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

        ret                                                                 ; Return from procedure                                        
        
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
color dw ?                                                                  ; c point
        
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


