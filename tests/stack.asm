my_data segment
    input_buffer db 50,?,50 dup('$') ; Input buffer of size 50 bytes
    new_line_text db 10, 13, "$"
    one db "one$"
    success_prompt db "Match!$"
    failure_prompt db "Failure!$"
my_data ends

my_code segment
    main:
        
        ; Add first number to stack
        mov ax, 10 
        push ax

        ; Add operator to stack
        mov ax, '+'
        push ax

        ; Add second number to stack
        mov ax, 345
        push ax

        ; Get all values from stack
        pop dx
        pop bx
        pop ax

        ; If operator is '+', then add numbers
        cmp bx, '+'
        je my_add

        call end_program

    end_program:
        mov ah, 4Ch                             ; 4Ch - code of program termination
        int 21h                                 ; 21h - DOS interruption (with flag 4Ch)

    my_add:
        add ax, dx                              ; Add value in dx to ax
        call print_number

    ;========================================================
    ; print_number: procedure that outputs number
    ;
    ; Parameters:
    ; ax: number to be printed
    ;========================================================
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

        call end_program


my_code ends

my_stack segment stack
    dw 300 dup(?)
    stack_top dw ?
my_stack ends  

end main


