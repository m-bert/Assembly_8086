my_data segment
input_buffer db 50,?,50 dup('$') ; Input buffer of size 50 bytes
new_line_text db 10, 13, "$"


; Variables to compare with input
lorem db "lorem$"
ipsum db "ipsum$"

; Result prompts
success_prompt db "Match!$"
failure_prompt db "Failure!$"

my_data ends

my_code segment
    main:
        call my_input                           ; Call my_input to get user input

        mov dx, offset new_line_text            ; Move new_line_text to dx as parameter for my_print
        call my_print                           ; Call my_print procedure

        mov si, offset input_buffer + 2         ; Move input_buffer to si as first parameter for compare_strings (+2 ommits 10, and 13)
        mov di, offset ipsum                    ; Move lorem to di as second parameter for compare_strings
        call compare_strings                    ; Call compare_strings

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
    ; compare_strings - procedure that compares two strings
    ;
    ; Parameters:
    ; si: offset of string that is being compared (namely user input)
    ; di: offset of string to compare to
    ;========================================================
    compare_strings:
        ; Main loop
        compare_loop:
            mov al, [si]                        ; Move character from adress si to al
            cmp al, [di]                        ; Compare character stored in al to character at address di
            jne end_compare                     ; If characters are not equal end loop

            inc si                              ; Increment si index
            inc di                              ; Increment di index

            loop compare_loop                   ; Loop back

        end_compare:    
            mov al, [di]                        ; Move character from adress di to al  
            cmp al, '$'                         ; Check if our pattern ended
            jne match_fail                      ; If pattern didn't end - match fails

            mov al, [si]                        ; Move character from adress si to al    
            cmp al, 13                          ; Check if our input ended (DOSBOX ends line with CR)
            jne match_fail                      ; If input didn't end - match fails

            jmp match_found                     ; Match successful


        match_found:
            mov dx, offset success_prompt       
            call my_print                       

            mov dx, offset new_line_text        
            call my_print                      

            ret
        
        match_fail:
            mov dx, offset failure_prompt       
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


