my_data segment
input_prompt db "Wprowadz dzialanie: $"
input_buffer db 50,?,50 dup('$') ; Input buffer of size 50 bytes
new_line_text db 10, 13, "$"
my_data ends

my_code segment
    main:
        ; Print user input prompt
        mov dx, offset input_prompt             ; Set input_prompt as parameter for my_print
        call my_print                           ; Calling my_print function

        ; Get user input
        call my_input                           ; Calling my_input function

        mov dx, offset new_line_text            ; Set new_line_text as parameter for my_print
        call my_print                           ; Calling my_print function

        ; Print string entered by user
        mov dx, offset input_buffer + 2         ; Set input_buffer as parameter for my_print, +2 omits length and CR
        call my_print 

        ; END PROGRAM
        mov ah, 4Ch                             ; 4Ch - code of program termination
        int 21h                                 ; 21h - DOS interruption (with flag 4Ch)
    

    ;========================================================
    ; my_print - Subroutine that prints string 
    ;
    ; Parameters:
    ; dx: offset of string to be printed
    ;========================================================
    my_print:
        mov ax, seg my_data                     ; Move my_data segment to ax
        mov ds, ax                              ; Move my_data segment from ax to ds

        mov ah, 09h                             ; 09h - code for printing string
        int 21h                                 ; 21h - DOS interruption (with flag 09h)
        ret                                     ; Return from subroutine

    ;========================================================
    ; my_input - Subroutine that gets user input
    ;========================================================
    my_input:
        mov ax, seg my_data                     ; Move my_data segment to ax
        mov ds, ax                              ; Move my_data segment from ax to ds

        mov dx, offset input_buffer             ; Moving buffer offset to dx
        mov ah, 0Ah                             ; 0Ah - code for getting user input
        int 21h                                 ; 21h - DOS interruption (with flag 0Ah)
        ret                                     ; Return from subroutine        


my_code ends

my_stack segment stack
    dw 300 dup(?)
    stack_top dw ?
my_stack ends  

end main


