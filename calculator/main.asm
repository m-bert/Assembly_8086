;================================================================================================================================
; DATA SEGMENT
my_data segment

    ; User prompts
    input_prompt db "Wprowadz dzialanie: $"
    output_prompt db "Wynik dzialania to: $"
    result_prompt db "Wynikiem dzialania jest: $"

    ; Fail messages
    unknown_operator_msg db "Podano niewlasciwy operator!$"
    unknown_argument_msg db "Bledny argument: $"
    invalid_arguments_msg db "Bledne argumenty dzialania!$"
    invalid_arguments_number_msg db "Bledna ilosc argumentow wejsciowych!", 10, 13, '$'
    example_msg db "Przykladowe uzycie: dwa plus dwa$"

    ; Separators
    new_line db 10, 13, '$'
    space db " $"

    ; Buffers
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
    twelve db "dwanascie$"
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
;================================================================================================================================

;================================================================================================================================
;   OVERVIEW
;
;   This program is an implementation of text calculator in Assembly 8086 MASM
; 
;   At the beginning, program asks to enter operation in form <digit> <operator> <digit>, where:
;   digit is a digit in text format {"zero", "jeden", ..., "dziewiec"}
;   operator is one of the following: {"plus", "minus", "razy"}
;
;   Then algorithm proceedes to parse user input token by token. If the token is not recognized, program finishes with error message.
;   If the token is recognized, its mapped value is pushed to stack and bx register, that stores amount of passed arguments, is incremented.
;   After parsing whole input, if number of parameters is not equal to 3, program ends with error message.
;   If number of arguments is equal to 3, all 3 parameters are popped from stack, and then checked if they're correct, ie.:
;   if the first and third parameters are digit and the second parameter is operator. If parameters are invalid, program ends with error message.
;   After that, program prints the result and exits.
;
;================================================================================================================================


;================================================================================================================================
; CODE SEGMENT
my_code segment
    main:
        mov dx, offset input_prompt                                         ; Set my_print parameter to input_prompt
        call my_print                                                       ; Print message to user

        call get_input                                                      ; Call procedure to get input from user

        mov dx, offset new_line                                             ; Set my_print parameter to new_line
        call my_print                                                       ; Print new line

        jmp parse_line                                                      ; Start algorithm

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; parse_line - procedure that parses user input - splits it into tokens and performs mapping on each of them
    ;--------------------------------------------------------------------------------------------------------------------------------
    parse_line:
        mov bx, 0                                                           ; Set value of bx to 0. This register will be used as
                                                                            ; a counter for tokens amount, therefore will help to identify
                                                                            ; if user entered right amount of arguments

        mov si, offset input_buffer + 2                                     ; Set si to point to first character of input buffer (+2 omits length and CR)
        mov di, offset parse_buffer + 2                                     ; Set di to point to first character of parse buffer (+2 omits length and CR)

        ;--------------------------------------------------------------------------------------------------------------------------------
        ; parse_loop - loop that scans each character from user input and after receiving ' ' or '$' proceedes to recognize token
        ;--------------------------------------------------------------------------------------------------------------------------------
        parse_loop:
            mov al, [si]                                                    ; Read character from source into al

            cmp al, 32                                                      ; If character is space, we either found token, or a sequeance of spaces
            je handle_separator                                             ; so we call handle separator to check which situation occurred

            cmp al, 13                                                      ; If character is '$', we either found token, or finished input with sequence
            je handle_separator                                             ; of spaces, so we call handle separator to check which situation occurred

            mov [di], al                                                    ; Copy character from input into parse buffer

            inc si                                                          ; Increment si to point to next character of input buffer
            inc di                                                          ; Increment di to point to next character of parse buffer

            loop parse_loop                                                 ; Loop back to find rest of tokens

        ;--------------------------------------------------------------------------------------------------------------------------------
        ; handle_separator - procedure that analyzes parse buffer after reading ' ' or '$'
        ;--------------------------------------------------------------------------------------------------------------------------------
        handle_separator:
            mov di, offset parse_buffer + 2                                 ; Set di to point to first character of parse buffer
            mov dl, [di]                                                    ; Set dl value to first character of parse buffer
                                                                            ; Here dl is used, because later on program checks if al, that currently
                                                                            ; points to last read character from user input is '$', so it is better to use dl
                                                                            ; instead of putting ax on stack and then popping it (dx is not in use at that point)
            
            cmp dl, '$'                                                     ; Check if first character of parse buffer is '$'
            jne choose_operator                                             ; If it isn't, it means that parse buffer contains token and we have to map it to
                                                                            ; operators used in our program

            cmp al, 13                                                      ; If last character was 13 and parse buffer is empty,
            je check_arguments                                              ; we can proceed to check whether arguments are valid

            inc si                                                          ; Otherwise, if character was ' ' and parse buffer is empty
            jmp parse_loop                                                  ; we go back to parsing loop to find next token

            
    ;--------------------------------------------------------------------------------------------------------------------------------
    ; choose_operator - procedure that recognizes inpout token
    ;--------------------------------------------------------------------------------------------------------------------------------
    choose_operator:
        push si                                                             ; In comparing string we will be using di and si registers
                                                                            ; Since we parsed whole token, di register will be reset after
                                                                            ; recognizing token
                                                                            ; However, we have to keep value of si, which stores current posiiton 
                                                                            ; in user input, to be able to parse rest of the user input 

        push ax                                                             ; al stores last character read from user input. We will need this
                                                                            ; value to decide whether we've finished parsing or not
                                                                            ; Because we can't push only al to stack, we push ax instead
                                                                            
        ; Recognizing digits (all of the blocks below work in the same way)

        mov si, offset parse_buffer + 2                                     ; Set si to point to beginning of parse buffer (+2 to omit length and CR)
        mov di, offset zero                                                 ; Set di to first digit to compare to
        mov dx, 0                                                           ; Set dx to mapped equivalent of our token. This will be later pushed to stack
        call compare_strings                                                ; Call comparing method

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

        ; Recognizing operator 

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

        jmp fail_unknown_argument                                           ; If the token was not recognized, we exit program
                                                                            ; with appropriate error message

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; compare_strings - compares string from source (SI) to string in destination (DI) 
    ;
    ; Parameters:
    ; si: offset of source string that is being compared (namely user input)
    ; di: offset of destination string to compare to
    ;--------------------------------------------------------------------------------------------------------------------------------
    compare_strings:
        compare_loop:
            mov al, [si]                                                    ; Move current character from source to al
            cmp al, [di]                                                    ; Compare current character from source to character in destination
            jne end_compare                                                 ; If characters are not equal end loop                   

            cmp al, '$'                                                     ; If current character is "$", string match
            je remove_return_address                                        ; End loop with matching strings

            inc si                                                          ; Increment si index - change current character in source
            inc di                                                          ; Increment di index - change current character in destination

            loop compare_loop                                               ; Loop back to check next character

        end_compare:    
            ret                                                             ; Strings are not equal, so we go back to check next operator

        remove_return_address:
            pop ax                                                          ; Strings do match, but program got here through "call" instruction.
                                                                            ; That means, that return address is still on top of the stack and we have
                                                                            ; to manually pop it.

            jmp back_to_parsing                                             ; We go back to parsing next word in input

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; back_to_parsing - procedure that does cleanup, so that parse line will correctly scan next input token
    ;--------------------------------------------------------------------------------------------------------------------------------
    back_to_parsing:
        call clear_buffer                                                   ; Clear parsing buffer

        pop ax                                                              ; Value at al stores last character read from input
                                                                            ; Based on that we can check, whether it was 13, which means
                                                                            ; that we reached end of user input and we can now start checking
                                                                            ; received arguments

        pop si                                                              ; Value that is being popped to si stores address of last character read from input

        push dx                                                             ; At this point, dx stores mapped argument for our operation, so we store its value in stack

        inc bx                                                              ; bx is used as a counter for number of passed arguments, so after
                                                                            ; parsing each of them, we have to increment value of bx

        cmp al, 13                                                          ; If last character in input was 13, it means that we finished parsing user's input
                                                                            ; and now we can proceed to check whether arguments are valid

        je check_arguments                                                  ; Jump to procedure that checks arguments

        mov di, offset parse_buffer + 2                                     ; If last character wasn't 13, it means that we still have to parse rest of user input
                                                                            ; We reset di register, so it points once again to start of parsing buffer

        inc si                                                              ; At this point we know, that last character read from input was space (32)
                                                                            ; In order not to end up in infinite loop, we have to increment value of si, 
                                                                            ; so it points to the next character in user input

        jmp parse_loop                                                      ; Go back to our parsing loop

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; check_arguments - procedure that checks if arguments enetred by user are valid
    ;--------------------------------------------------------------------------------------------------------------------------------
    check_arguments:
        cmp bx, 3                                                           ; bx stores amount of arguments that user entered.
                                                                            ; If amount of these arguments is not equal to 3, 
                                                                            ; we display error message and exit the program

        jne fail_invalid_arguments_number                                   ; Fail program if user entered wrong amount of arguments

        pop dx                                                              ; Pop to dx third argument entered by user
        pop bx                                                              ; Pop to bx second argument entered by user
        pop ax                                                              ; Pop to ax first argument entered by user

        cmp ax, 9                                                           ; ax should store first digit for our operation
                                                                            ; Since this program accepts only digits 0-9 and operators {+, -, *}
                                                                            ; if value of ax is greater than 9, that means that user enetred operation type
                                                                            ; as first parameter.
                                                                            ; In that case, we end the program with proper error message

        jg fail_invalid_arguments                                           ; Fail program if first argument is not a digit

        cmp dx, 9                                                           ; dx should store second digit for our operation
        jg fail_invalid_arguments                                           ; Fail program if third argument is not a digit

        jmp perform_operation                                               ; If user properly entered digit, we try to perform operation


    ;================================================================================================================================
    ; OPERATIONS
    ;================================================================================================================================

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; perform_operation - procedure that tries to perform operation entered by user
    ;--------------------------------------------------------------------------------------------------------------------------------
    perform_operation:
        cmp bx, '+'                                                         ; bx stores operation type that user entered, in case of '+'
        je perform_addition                                                 ; we perform addition

        cmp bx, '-'                                                         ; In case of '-' we perform subtraction
        je perform_subtraction                                              

        cmp bx, '*'                                                         ; In case of '*' we perform multiplication
        je perform_multiplication                                       

        jmp fail_unknown_operator                                           ; If the operator is not one of {+, -, *} (which at that point means that
                                                                            ; user entered digit as second argument), we end program with error message

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; perform_addition - procedure that adds numbers entered by user
    ;--------------------------------------------------------------------------------------------------------------------------------
    perform_addition:
        add ax, dx                                                          ; Add to first argument in ax value of second argument in dx
                                                                            ; Result of this operation in stored in ax
        jmp print_result_wrapper                                            ; Jump to print result

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; perform_subtraction - procedure that subtracts numbers entered by user
    ;--------------------------------------------------------------------------------------------------------------------------------
    perform_subtraction:
        sub ax, dx                                                          ; Subtract from first argument in ax value of second argument in dx
                                                                            ; Result of this operation in stored in ax
        jmp print_result_wrapper                                            ; Jump to print result

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; perform_multiplication - procedure that multiplies numbers entered by user
    ;--------------------------------------------------------------------------------------------------------------------------------
    perform_multiplication:
        mul dx                                                              ; Multiply first argument stored in ax by value of second argument stored in dx
                                                                            ; Result of this operation in stored in ax
        jmp print_result_wrapper                                            ; Jump to print result


    ;================================================================================================================================
    ; PRINTS
    ;================================================================================================================================

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; print_result_wrapper - wrapper for printing result of our operation, which checks if result is negative
    ;--------------------------------------------------------------------------------------------------------------------------------
    print_result_wrapper:
        mov dx, offset result_prompt                                        ; Set my_print parameter to result prompt
        call my_print                                                       ; Print result prompt

        cmp ax, 0                                                           ; Compare value of result with 0
        jl print_minus                                                      ; If our result is negative, we print minus before rest of result

        jmp print_result                                                    ; If result is non-negative, we print it immediately

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; print_minus - procedure that prints minus if result is negative
    ;--------------------------------------------------------------------------------------------------------------------------------
    print_minus:
        mov dx, offset minus                                                ; Set my_print parameter to minus
        call my_print                                                       ; Print minus

        mov dx, offset space                                                ; Set my_print parameter to space
        call my_print                                                       ; Print space

        mov bx, -1                                                          ; Set value of bx to -1, to convert our result to positive value
        mul bx                                                              ; Convert result to its absolute value

        jmp print_result                                                    ; Print result

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; print_result - procedure that prints result
    ;--------------------------------------------------------------------------------------------------------------------------------
    print_result:
        ; Special cases
        cmp ax, 10                                                          ; Compare result value to 10
        je print_ten                                                        ; If it matches, print 10 and exit program

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

        cmp ax, 19
        je print_nineteen

        ; Rest of the cases

        cmp ax, 10                                                          ; If result < 10, then it contains only one digit
        jl print_last_digit                                                 ; so we can print only last digit

        jmp print_first_digit                                               ; Jump to procedure that prints first digit of the result

        ;--------------------------------------------------------------------------------------------------------------------------------
        ; print_first_digit - procedure that prints first digit of result (namely tens part)
        ;--------------------------------------------------------------------------------------------------------------------------------
        print_first_digit:
            xor dx, dx                                                      ; Clear dx which will store unit part of the result

            mov bx, 10                                                      ; Set bx value to 10. This will be used to divide result by 10
                                                                            ; so that we get the tens part and the unit part

            div bx                                                          ; Divide ax (our result) by 10 (bx). After this operation:
                                                                            ; ax stores tens part of the result
                                                                            ; dx stores unit part of the result

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

        ;--------------------------------------------------------------------------------------------------------------------------------
        ; print_last_digit - procedure that prints last digit of result (namely unit part)
        ;--------------------------------------------------------------------------------------------------------------------------------
        print_last_digit:
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

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; print_x - procedures that prints x value as text
    ;--------------------------------------------------------------------------------------------------------------------------------
    print_zero:
        mov dx, offset zero                                                 ; Set my_print parameter to zero
        call my_print                                                       ; Print zero
        jmp end_program                                                     ; End program

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
        push dx                                                             ; In this case, we are printing first part of the result, namely tens part
                                                                            ; dx stores unit part of the result, but its value will be modified in 
                                                                            ; my_print procedure, so we have to store it on stack

        mov dx, offset twenty                                               ; Set my_print parameter to twenty
        call my_print                                                       ; Print twenty

        jmp check_last_digit                                                ; Jump to procedure that cheks whether last digit is 0 or not


    print_thirty:
        push dx

        mov dx, offset thirty
        call my_print

        jmp check_last_digit

    print_forty:
        push dx

        mov dx, offset forty
        call my_print

        jmp check_last_digit

    print_fifty:
        push dx

        mov dx, offset fifty
        call my_print

        jmp check_last_digit

    print_sixty:
        push dx

        mov dx, offset sixty
        call my_print

        jmp check_last_digit

    print_seventy:
        push dx

        mov dx, offset seventy
        call my_print

        jmp check_last_digit

    print_eighty:
        push dx

        mov dx, offset eighty
        call my_print

        jmp check_last_digit

    print_ninety:
        push dx

        mov dx, offset ninety
        call my_print

        jmp check_last_digit

    ;================================================================================================================================
    ; UTILS
    ;================================================================================================================================
    
    ;--------------------------------------------------------------------------------------------------------------------------------
    ; get_input - procedure that gets input from user
    ;--------------------------------------------------------------------------------------------------------------------------------
    get_input:
        mov ax, seg my_data                                                 ; Move my_data segment to ax
        mov ds, ax                                                          ; Move my_data segment from ax to ds

        mov dx, offset input_buffer                                         ; Set value of dx to offset of input buffer
        mov ah, 0Ah                                                         ; Set ah value to 0Ah - code for getting user input
        int 21h                                                             ; 21h - DOS interruption (with flag 0Ah)

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
            mov [di], al                                                    ; Replace character at [di] with '$'
            inc di                                                          ; Increment di to point to next character
            loop clear_loop                                                 ; Loop back to clear whole buffer

        pop ax                                                              ; Get back original value of ax

        ret                                                                 ; Return from procedure

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; check_last_digit - procedure that check if last digit od result is 0
    ;--------------------------------------------------------------------------------------------------------------------------------
    check_last_digit:
        pop ax                                                              ; Get last digit of result to ax

        cmp ax, 0                                                           ; If last digit is 0, we end program
        je end_program                                                      ; to avoid printing result like "thirty zero"

        mov dx, offset space                                                ; Set my_print parameter to space
        call my_print                                                       ; Print space

        jmp print_last_digit                                                ; Jump to procedure that prints last digit of result
        
    ;================================================================================================================================
    ; FAILS
    ;================================================================================================================================

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; fail_unknown_operator - procedure that ends program when operator is different than {+, -, *}
    ;--------------------------------------------------------------------------------------------------------------------------------
    fail_unknown_operator:
        mov dx, offset unknown_operator_msg                                 ; Set my_print parameter to unknown_operator_msg
        call my_print                                                       ; Display error message
        jmp end_program                                                     ; Exit program

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; fail_unknown_operator - procedure that ends program when input contains unknown token
    ;--------------------------------------------------------------------------------------------------------------------------------
    fail_unknown_argument:
        mov dx, offset unknown_argument_msg                                 ; Set my_print parameter to unknown_argument_msg
        call my_print                                                       ; Display error message

        mov dx, offset parse_buffer + 2                                     ; Set my_print parameter to parse_buffer, which contains unknown token
        call my_print                                                       ; Display unknown token

        jmp end_program                                                     ; Exit program

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; fail_invalid_arguments - procedure that ends program when either first or last argument is not a digit
    ;--------------------------------------------------------------------------------------------------------------------------------
    fail_invalid_arguments:
        mov dx, offset invalid_arguments_msg                                ; Set my_print parameter to invalid_arguments_msg
        call my_print                                                       ; Display error message
        jmp end_program                                                     ; Exit program

    ;--------------------------------------------------------------------------------------------------------------------------------
    ; fail_invalid_arguments_number - procedure that ends program when user entered wrong amount of arguments
    ;--------------------------------------------------------------------------------------------------------------------------------
    fail_invalid_arguments_number:
        mov dx, offset invalid_arguments_number_msg                         ; Set my_print parameter to invalid_arguments_number_msg
        call my_print                                                       ; Display error message

        mov dx, offset example_msg
        call my_print ; Display example

        jmp end_program                                                     ; Exit program


        
    ;================================================================================================================================
    ; end_program - procedure that terminates program
    ;================================================================================================================================
    end_program:
        mov ah, 4Ch                                                         ; 4Ch - code to exit program
        int 21h                                                             ; 21h - DOS interruption (with flag 09h)

        
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


