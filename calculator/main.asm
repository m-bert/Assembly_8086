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

        jmp parse_line

        ; call end_program

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
            je choose_operator

            cmp al, 13                              ; If character is '$', handle word and end loop
            je choose_operator

            mov [di], al                            ; Copy character into buffer

            inc si
            inc di

            loop parse_loop


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
        push si
        push ax

        mov si, offset parse_buffer
        mov di, offset zero
        mov dx, 0
        call compare_strings

        mov si, offset parse_buffer
        mov di, offset one
        mov dx, 1
        call compare_strings

        mov si, offset parse_buffer
        mov di, offset two
        mov dx, 2
        call compare_strings

        mov si, offset parse_buffer
        mov di, offset three
        mov dx, 3
        call compare_strings

        mov si, offset parse_buffer
        mov di, offset four
        mov dx, 4
        call compare_strings

        mov si, offset parse_buffer
        mov di, offset five
        mov dx, 5
        call compare_strings

        mov si, offset parse_buffer
        mov di, offset six
        mov dx, 6
        call compare_strings

        mov si, offset parse_buffer
        mov di, offset seven
        mov dx, 7
        call compare_strings

        mov si, offset parse_buffer
        mov di, offset eight
        mov dx, 8
        call compare_strings

        mov si, offset parse_buffer
        mov di, offset nine
        mov dx, 9
        call compare_strings

        ;============================ 

        mov si, offset parse_buffer
        mov di, offset plus
        mov dx, "+"
        call compare_strings

        mov si, offset parse_buffer
        mov di, offset minus
        mov dx, "-"
        call compare_strings

        mov si, offset parse_buffer
        mov di, offset times
        mov dx, "*"
        call compare_strings

        jmp end_program

    ;===================================================================================
    ; compare_strings - compares string from source (SI) to string in destination (DI) 
    ;
    ; Parameters:
    ; si: offset of string that is being compared (namely user input)
    ; di: offset of string to compare to
    ;===================================================================================
    compare_strings:
        compare_loop:
            mov al, [si]                        ; Move character from adress si to al
            cmp al, [di]                        ; Compare character stored in al to character at address di
            jne end_compare                     ; If characters are not equal end loop                   

            cmp al, '$'
            je add_to_stack

            inc si                              ; Increment si index
            inc di                              ; Increment di index

            loop compare_loop                   ; Loop back

        end_compare:    
            ret


    add_to_stack:
        pop ax ;remove return address from stack
        jmp back_to_parsing

    back_to_parsing:
        call clear_buffer ; Clear buffer after printing word; -1 to finish exactly at given place

        pop ax
        pop si

        push dx

        cmp al, 13
        je perform_operation

        mov di, offset parse_buffer             ; Reset di register, so it points once again to start of buffer
        inc si                                  ; Inc si, so we don't end in infinite loop

        jmp parse_loop                          ; Go back to our parsing loop


    perform_operation:
        pop dx
        pop bx
        pop ax    

        cmp bx, '+'
        je perform_addition

        cmp bx, '-'
        je perform_subtraction

        cmp bx, '*'
        je perform_multiplication

        add ax, dx
        jmp print_number


    perform_addition:
        add ax, dx 
        jmp print_number

    perform_subtraction:
        sub ax, dx
        jmp print_number

    perform_multiplication:
        mul dx
        jmp print_number

    print_number:
        ; Push to stack character '$' - this will indicate that all digits have been read
        mov bx, '$'
        push bx

        mov bx, 10                              ; Move base of our system to bx to perform division

        divide_loop:
            xor dx, dx                          ; Clear dx register
            div bx                              ; Divide value in ax by bx
            push dx                             ; Push remainder to stack
            cmp ax, 0                           ; Check if all digits have been pushed to stack
            jne divide_loop                     ; If there are more digits, loop back

        print_loop:
            pop dx                              ; Get element from stack

            ; If value is '$', then whole number have been read, so we can end program
            cmp dx, '$'                         
            je end_program

            add dl, '0'                         ; Add '0' to convert digit to ASCII
            mov ah, 02h                         ; 02h - code to print digit
            int 21h                             ; 21h - DOS interruption (with flag 02h)
            loop print_loop                     ; Loop back to print remaining digits

        jmp end_program
        
               

        
my_code ends

my_stack segment stack
    dw 300 dup(?)
    stack_top dw ?
my_stack ends  

end main


