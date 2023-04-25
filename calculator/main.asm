my_data segment
    ; User prompts
    input_prompt db "Wprowadz dzialanie: $"
    output_prompt db "Wynik dzialania to: $"
    new_line db 10, 13, "$"

    input_buffer db 50, ?, 50 dup('$')             
    parse_buffer db 50, ?, 50 dup('$')

    ; Variables that store numbers
    zero db "zero$"
    one db "jeden$"
    two db "dwa$"
    three db "trzy$"
    four db "cztery$"
    five db "piec$"
    six db "szesc$"
    seven db "siedem$"
    eight db "osiem$"
    nine db "dziewiec$"
    eleven db "jedenascie$"
    twelve db "dwanaśsie$"
    thirteen db "trzynascie$"
    fourteen db "czternascie$"
    fifteen db "pietnascie$"
    sixteen db "szesnascie$"
    seventeen db "siedemnascie$"
    eighteen db "osiemnascie$"
    ninetten db "dziewietnascie$"
    twenty db "dwadziescia$"
    thirty db "trzydziesci$"
    forty db "czterdziesci$"
    fifty db "piecdziesiat$"
    sixty db "szescdziesiat$"
    seventy db "siedemdziesiat$"
    eighty db "osiemdziesiat$"
    ninety db "dziewiecdziesiat$"

    ;Variables that store operations
    plus db "plus$"
    minus db "minus$"
    times db "razy$"

my_data ends

my_code segment
    main:
        mov dx, offset input_prompt                  ; Set input_prompt as parameter for my_print
        call my_print                                

        call my_input

        mov dx, offset new_line
        call my_print                                

        call parse_line

        call end_program

    ;========================================================
    ; end_program - procedure that terminates program
    ;========================================================
    end_program:
        mov ah, 4Ch                                 ; 4Ch - code to exit program
        int 21h                                     ; 21h - DOS interruption (with flag 09h)

    ;========================================================
    ; my_print - procedure that prints string 
    ;
    ; Parameters:
    ; dx: offset of string to be printed
    ;========================================================
    my_print:
        mov ax, seg my_data                         ; Move my_data segment to ax
        mov ds, ax                                  ; Move my_data segment from ax to ds

        mov ah, 09h                                 ; 09h - code for printing string
        int 21h                                     ; 21h - DOS interruption (with flag 09h)

        ret                                         ; Return from procedure

    ;========================================================
    ; my_input - procedure that gets user input
    ;========================================================
    my_input:
        mov ax, seg my_data                         ; Move my_data segment to ax
        mov ds, ax                                  ; Move my_data segment from ax to ds

        mov dx, offset input_buffer                 ; Moving buffer offset to dx
        mov ah, 0Ah                                 ; 0Ah - code for getting user input
        int 21h                                     ; 21h - DOS interruption (with flag 0Ah)

        ret                                         ; Return from procedure   

    ;========================================================
    ; parse_line - procedure that parses input word by word 
    ;========================================================
    parse_line:
        mov si, offset input_buffer + 2             ; Move input_buffer to si (+2 ommits length and CR)
        mov di, offset parse_buffer                 ; Move output buffer offset ti di

        ; Loop that scans input char by char and splits it into 
        ; words containted in parse_buffer
        parse_loop:
            mov al, [si]                            ; Read character from source into al

            cmp al, 32                              ; If character is space, handle word and return to loop
            je handle_word

            cmp al, 13                              ; If character is '$', handle word and end loop
            je end_loop

            mov [di], al                            ; Copy character into buffer

            inc si
            inc di


            loop parse_loop

        ;--------------------------------------------------------
        ; handle_word - procedure that calls choose_operator on
        ; each of input words, then clears the buffer and returns
        ; to the parsing loop
        ;--------------------------------------------------------
        handle_word:
            push si
            call choose_operator  
            call clear_buffer ; Clear buffer after printing word; -1 to finish exactly at given place
            pop si

            mov di, offset parse_buffer             ; Reset di register, so it points once again to start of buffer

            inc si                                  ; Inc si, so we don't end in infinite loop

            jmp parse_loop                          ; Go back to our parsing loop


        end_loop:
            call choose_operator
            call end_program

    clear_buffer:
        mov si, offset parse_buffer
        mov cx, 50

        clear_loop:
            mov byte ptr[si], "$"
            inc si
            loop clear_loop  

        ret               
            
    ;========================================================
    ; choose_operator - handler for each of input words
    ;========================================================
    choose_operator:
        mov si, offset parse_buffer
        mov di, offset eight
        call compare_strings

        mov si, offset parse_buffer
        mov di, offset nine
        call compare_strings

        mov si, offset parse_buffer
        mov di, offset plus
        call compare_strings

        ret

    ;===================================================================================
    ; compare_strings - compares string from source (SI) to string in destination (DI) 
    ;
    ; Parameters:
    ; si: offset of string that is being compared (namely user input)
    ; di: offset of string to compare to
    ;===================================================================================
    compare_strings:
        ; Main loop
        compare_loop:
            mov al, [si]                        ; Move character from adress si to al
            cmp al, [di]                        ; Compare character stored in al to character at address di
            jne end_compare                     ; If characters are not equal end loop                   

            cmp al, '$'
            je match_found

            inc si                              ; Increment si index
            inc di                              ; Increment di index

            loop compare_loop                   ; Loop back

        end_compare:    
            mov dx, offset zero
            call my_print 
            mov dx, offset new_line
            call my_print 

            ret


        match_found:
            mov dx, offset one     
            call my_print                       

            mov dx, offset new_line      
            call my_print   

            ret                   

        
my_code ends

my_stack segment stack
    dw 300 dup(?)
    stack_top dw ?
my_stack ends  

end main


