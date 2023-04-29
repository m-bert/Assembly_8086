my_data segment
    ; User prompts
    input_prompt db "Wprowadz dzialanie: $"
    output_prompt db "Wynik dzialania to: $"

    unknown_operator_msg db "Podano niewlasciwy operator!$"
    unknown_argument_msg db "Blad danych wejsciowych!$"
    invalid_arguments_msg db "Bledne argumenty dzialania!$"
    invalid_arguments_number_msg db "Bledna ilosc argumentow wejsciowych!$"

    new_line db 10, 13, "$"
    space db " $"

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
    ten db "dziesiec$"
    eleven db "jedenascie$"
    twelve db "dwanaśsie$"
    thirteen db "trzynascie$"
    fourteen db "czternascie$"
    fifteen db "pietnascie$"
    sixteen db "szesnascie$"
    seventeen db "siedemnascie$"
    eighteen db "osiemnascie$"
    nineteen db "dziewietnascie$"
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
        mov bx, 0
        mov si, offset input_buffer + 2             ; Move input_buffer to si (+2 ommits length and CR)
        mov di, offset parse_buffer + 2                 ; Move output buffer offset to di

        ; Loop that scans input char by char and splits it into 
        ; words containted in parse_buffer
        parse_loop:
            mov al, [si]                            ; Read character from source into al

            cmp al, 32                              ; If character is space, handle word and return to loop
            je handle_space

            cmp al, 13                              ; If character is '$', handle word and end loop
            je handle_eof

            mov [di], al                            ; Copy character into buffer

            inc si
            inc di

            loop parse_loop


    clear_buffer:
        mov si, offset parse_buffer + 2
        mov cx, 50

        clear_loop:
            mov byte ptr[si], "$"
            inc si
            loop clear_loop  

        ret

    handle_space:
        push di

        mov di, offset parse_buffer + 2
        mov dl, [di]
        
        pop di

        cmp dl, "$"
        jne choose_operator

        inc si
        jmp parse_loop        

    handle_eof:
        push di

        mov di, offset parse_buffer + 2
        mov dl, [di]
        
        pop di

        cmp dl, "$"
        jne choose_operator

        inc si
        jmp check_arguments 
            
    ;========================================================
    ; choose_operator - handler for each of input words
    ;========================================================
    choose_operator:
        push si
        push ax

        mov si, offset parse_buffer + 2
        mov di, offset zero
        mov dx, 0
        call compare_strings

        mov si, offset parse_buffer + 2
        mov di, offset one
        mov dx, 1
        call compare_strings

        mov si, offset parse_buffer + 2
        mov di, offset two
        mov dx, 2
        call compare_strings

        mov si, offset parse_buffer + 2
        mov di, offset three
        mov dx, 3
        call compare_strings

        mov si, offset parse_buffer + 2
        mov di, offset four
        mov dx, 4
        call compare_strings

        mov si, offset parse_buffer + 2
        mov di, offset five
        mov dx, 5
        call compare_strings

        mov si, offset parse_buffer + 2
        mov di, offset six
        mov dx, 6
        call compare_strings

        mov si, offset parse_buffer + 2
        mov di, offset seven
        mov dx, 7
        call compare_strings

        mov si, offset parse_buffer + 2
        mov di, offset eight
        mov dx, 8
        call compare_strings

        mov si, offset parse_buffer + 2
        mov di, offset nine
        mov dx, 9
        call compare_strings

        ;============================ 

        mov si, offset parse_buffer + 2
        mov di, offset plus
        mov dx, "+"
        call compare_strings

        mov si, offset parse_buffer + 2
        mov di, offset minus
        mov dx, "-"
        call compare_strings

        mov si, offset parse_buffer + 2
        mov di, offset times
        mov dx, "*"
        call compare_strings

        jmp fail_unknown_argument

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
        inc bx

        cmp al, 13
        je check_arguments

        mov di, offset parse_buffer + 2             ; Reset di register, so it points once again to start of buffer
        inc si                                  ; Inc si, so we don't end in infinite loop

        jmp parse_loop                          ; Go back to our parsing loop


    check_arguments:
        cmp bx, 3
        jne fail_invalid_arguments_number

        pop dx
        pop bx
        pop ax

        cmp ax, 9
        jg fail_invalid_arguments

        cmp dx, 9
        jg fail_invalid_arguments

        jmp perform_operation


    perform_operation:
        cmp bx, '+'
        je perform_addition

        cmp bx, '-'
        je perform_subtraction

        cmp bx, '*'
        je perform_multiplication

        jmp fail_unknown_operator


    perform_addition:
        add ax, dx 
        jmp print_result

    perform_subtraction:
        sub ax, dx
        jmp print_result

    perform_multiplication:
        mul dx
        jmp print_result


    print_result:
        cmp ax, 0
        jl print_minus

        jmp print_value


    print_minus:
        push ax

        mov dx, offset minus
        call my_print

        mov dx, offset space
        call my_print

        pop ax

        mov bx, -1
        mul bx

        jmp print_value

    print_value:
        cmp ax, 0
        je print_zero

        cmp ax, 1
        je print_one

        cmp ax, 2
        je print_two

        cmp ax, 3
        je print_three

        cmp ax, 4
        je print_four

        cmp ax, 5
        je print_five

        cmp ax, 6
        je print_six

        cmp ax, 7
        je print_seven

        cmp ax, 8
        je print_eight

        cmp ax, 9
        je print_nine

        cmp ax, 10
        je print_ten

        cmp ax, 11
        je print_eleven

        cmp ax, 12
        je print_twelve

        cmp ax, 13
        je print_thirteen

        cmp ax, 14
        je print_fourteen

        cmp ax, 15
        je print_fifteen

        cmp ax, 16
        je print_sixteen

        cmp ax, 17
        je print_seventeen

        cmp ax, 18
        je print_eighteen

        ; ax - dziesiatki
        ; dx - jednosci
        mov bx, 10
        div bx

        print_first_digit:
            cmp ax, 2
            je print_twenty

            cmp ax, 3
            je print_thirty

            cmp ax, 4
            je print_forty

            cmp ax, 5
            je print_fifty

            cmp ax, 6
            je print_sixty

            cmp ax, 7
            je print_seventy

            cmp ax, 8
            je print_eighty

            cmp ax, 9
            je print_ninety

        print_last_digit:
            cmp dx, 0
            je end_program

            cmp dx, 1
            je print_one

            cmp dx, 2
            je print_two

            cmp dx, 3
            je print_three

            cmp dx, 4
            je print_four

            cmp dx, 5
            je print_five

            cmp dx, 6
            je print_six

            cmp dx, 7
            je print_seven

            cmp dx, 8
            je print_eight

            cmp dx, 9
            je print_nine


    ;PRINT NUMBERS

    print_zero:
        mov dx, offset zero
        call my_print
        jmp end_program

    print_one:
        mov dx, offset one
        call my_print
        jmp end_program

    print_two:
        mov dx, offset two
        call my_print
        jmp end_program

    print_three:
        mov dx, offset three
        call my_print
        jmp end_program

    print_four:
        mov dx, offset four
        call my_print
        jmp end_program

    print_five:
        mov dx, offset five
        call my_print
        jmp end_program

    print_six:
        mov dx, offset six
        call my_print
        jmp end_program

    print_seven:
        mov dx, offset seven
        call my_print
        jmp end_program

    print_eight:
        mov dx, offset eight
        call my_print
        jmp end_program

    print_nine:
        mov dx, offset nine
        call my_print
        jmp end_program

    print_ten:
        mov dx, offset ten
        call my_print
        jmp end_program

    print_eleven:
        mov dx, offset eleven
        call my_print
        jmp end_program

    print_twelve:
        mov dx, offset twelve
        call my_print
        jmp end_program

    print_thirteen:
        mov dx, offset thirteen
        call my_print
        jmp end_program

    print_fourteen:
        mov dx, offset fourteen
        call my_print
        jmp end_program

    print_fifteen:
        mov dx, offset fifteen
        call my_print
        jmp end_program

    print_sixteen:
        mov dx, offset sixteen
        call my_print
        jmp end_program

    print_seventeen:
        mov dx, offset seventeen
        call my_print
        jmp end_program

    print_eighteen:
        mov dx, offset eighteen
        call my_print
        jmp end_program

    print_nineteen:
        mov dx, offset nineteen
        call my_print
        jmp end_program

    print_twenty:
        push dx

        mov dx, offset twenty
        call my_print

        mov dx, offset space
        call my_print

        pop dx

        jmp print_last_digit


    print_thirty:
        push dx

        mov dx, offset thirty
        call my_print

        mov dx, offset space
        call my_print

        pop dx

        jmp print_last_digit

    print_forty:
        push dx

        mov dx, offset forty
        call my_print

        mov dx, offset space
        call my_print

        pop dx

        jmp print_last_digit

    print_fifty:
        push dx

        mov dx, offset fifty
        call my_print

        mov dx, offset space
        call my_print

        pop dx

        jmp print_last_digit

    print_sixty:
        push dx

        mov dx, offset sixty
        call my_print

        mov dx, offset space
        call my_print

        pop dx

        jmp print_last_digit

    print_seventy:
        push dx

        mov dx, offset seventy
        call my_print

        mov dx, offset space
        call my_print

        pop dx

        jmp print_last_digit

    print_eighty:
        push dx

        mov dx, offset eighty
        call my_print

        mov dx, offset space
        call my_print

        pop dx

        jmp print_last_digit

    print_ninety:
        push dx

        mov dx, offset ninety
        call my_print

        mov dx, offset space
        call my_print

        pop dx

        jmp print_last_digit
        
    ; FAILS

    fail_unknown_operator:
        mov dx, offset unknown_operator_msg
        call my_print

        jmp end_program

    fail_unknown_argument:
        mov dx, offset unknown_argument_msg
        call my_print

        jmp end_program

    fail_invalid_arguments:
        mov dx, offset invalid_arguments_msg
        call my_print

        jmp end_program

    fail_invalid_arguments_number:
        mov dx, offset invalid_arguments_number_msg
        call my_print

        jmp end_program
        
    ;========================================================
    ; end_program - procedure that terminates program
    ;========================================================
    end_program:
        mov ah, 4Ch                                 ; 4Ch - code to exit program
        int 21h                                     ; 21h - DOS interruption (with flag 09h)

        
my_code ends

my_stack segment stack
    dw 300 dup(?)
    stack_top dw ?
my_stack ends  

end main


