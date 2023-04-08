my_data segment
input_buffer db 50,?,50 dup('$') ; Input buffer of size 50 bytes
new_line_text db 10, 13, "$"

buffer db 50, ?, 50 dup('$')

my_data ends

my_code segment
    main:
        call my_input                           

        mov dx, offset new_line_text            ; Move new_line_text to dx as parameter for my_print
        call my_print                          

        call parse_line                         

        ; END PROGRAM
        mov ah, 4Ch                             ; 4Ch - code of program termination
        int 21h                                 ; 21h - DOS interruption (with flag 4Ch)
    

    ;========================================================
    ; my_print - procedure that prints string 
    ;
    ; Parameters:
    ; dx: offset of string to be printed
    ;========================================================
    my_print:
        mov ax, seg my_data                     ; Move my_data segment to ax
        mov ds, ax                              ; Move my_data segment from ax to ds

        mov ah, 09h                             ; 09h - code for printing string
        int 21h                                 ; 21h - DOS interruption (with flag 09h)

        ret                                     ; Return from procedure

    ;========================================================
    ; my_input - procedure that gets user input
    ;========================================================
    my_input:
        mov ax, seg my_data                     ; Move my_data segment to ax
        mov ds, ax                              ; Move my_data segment from ax to ds

        mov dx, offset input_buffer             ; Moving buffer offset to dx
        mov ah, 0Ah                             ; 0Ah - code for getting user input
        int 21h                                 ; 21h - DOS interruption (with flag 0Ah)

        ret                                     ; Return from procedure        


    ;========================================================
    ; parse_line - procedure that parses input word by word 
    ;========================================================
    parse_line:
        mov si, offset input_buffer + 2         ; Move input_buffer to si (+2 ommits length and CR)
        mov di, offset buffer                   ; Move output buffer offset ti di

        parse_loop:
            mov al, [si]                        ; Read character from source into al
            mov [di], al                        ; Copy character into buffer

            cmp al, 32                          ; If character is space, print word and return to loop
            je print_word

            cmp al, '$'                         ; If character is '$', print word and end loop
            je end_loop

            inc si
            inc di

            loop parse_loop

        print_word:
            mov dx, offset buffer
            call my_print
            
            mov dx, offset new_line_text
            call my_print

            mov byte ptr [di], 0                ; Clear buffer after printing word
            mov di, offset buffer               ; Reset di register, so it points once again to start of buffer

            inc si                              ; Inc si, so we don't and in infinite loop

            jmp parse_loop                      ; Go back to our parsing loop

            ret

        end_loop:
            mov dx, offset buffer
            call my_print
            
            mov dx, offset new_line_text
            call my_print

            ret
    


my_code ends

my_stack segment stack
    dw 300 dup(?)
    stack_top dw ?
my_stack ends  

end main


