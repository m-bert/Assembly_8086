my_data segment
input_prompt db "Wprowadz dzialanie: $"
output_prompt db "Wynik dzialania to: $"
my_data ends

my_code segment
    main:
        mov ax, my_data                 ; Move input_prompt segment to ax
        mov dx, offset input_prompt    ; Move input_prompt offset to dx

        call my_print

        mov ah, 4ch                     ; Code of program termination
        int 21h                         ; Terminate program
    

    ;Parameter stored in ax: segment of string to be printed
    ;Parameter stored in dx: offset of string to be printed
    my_print:
        mov ds, ax                      ; Move input_prompt do ds
        mov ah, 09h                     ; 09h - code for printing string
        int 21h                         ; 21h - DOS interruption (with flag 09h)
        ret



my_code ends

my_stack segment stack
    dw 300 dup(?)
    stack_top dw ?
my_stack ends  

end main


