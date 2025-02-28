; ===== Configuração inicial =====
.org 0x0000            ; Ponto inicial do programa
rjmp main              ; Saltar para o programa principal

; ===== Armazenar tabela ASCII =====
store_ascii:
    ldi ZH, 0x02       ; Início da memória 0x200
    ldi ZL, 0x00

    ; Armazenar caracteres maiúsculos (A-Z)
    ldi r16, 'A'
store_uppercase:
    st Z+, r16
    inc r16
    cpi r16, 'Z' + 1
    brne store_uppercase

    ; Armazenar caracteres minúsculos (a-z)
    ldi r16, 'a'
store_lowercase:
    st Z+, r16
    inc r16
    cpi r16, 'z' + 1
    brne store_lowercase

    ; Armazenar dígitos (0-9)
    ldi r16, '0'
store_digits:
    st Z+, r16
    inc r16
    cpi r16, '9' + 1
    brne store_digits

    ; Armazenar espaço e <ESC>
    ldi r16, 0x20       ; Espaço
    st Z+, r16
    ldi r16, 0x1B       ; <ESC>
    st Z+, r16

    ret                 ; Retorna para o programa principal

; ===== Configuração das portas =====
setup_ports:
    clr r16
    out DDRD, r16       ; PORTD como entrada
    ldi r16, 0xFF
    out DDRC, r16       ; PORTC como saída
    ret

; ===== Programa principal =====
main:
    rcall store_ascii   ; Armazena a tabela ASCII na memória
    rcall setup_ports   ; Configura as portas

main_loop:
    in r16, PIND        ; Lê comando da porta de entrada
    cpi r16, 0x1C
    breq read_sequences ; Lê sequência de caracteres (0x1C)
    cpi r16, 0x1D
    breq count_chars    ; Conta caracteres (0x1D)
    cpi r16, 0x1E
    breq count_specific ; Conta ocorrências de um caractere (0x1E)
    cpi r16, 0x1F
    breq criaTabelaF    ; Cria tabela de frequências (0x1F)
    rjmp main_loop      ; Continua no loop principal

; ===== Ler sequência de caracteres =====
read_sequences:
    ldi ZH, 0x03        ; Início da memória 0x300
    ldi ZL, 0x00
    clr r19             ; Zera o contador de caracteres

read_char:
    in r16, PIND
    cpi r16, 0x1B       ; Verifica <ESC>
    breq end_sequence
    cpi r16, 0x20       ; Verifica caractere válido
    brlt read_char
    cpi r16, 0x7F
    brge read_char

    st Z+, r16          ; Armazena caractere na memória
    inc r19             ; Incrementa contador
    ldi r17, 0x04       ; Verifica limite de memória (0x400)
    cp ZH, r17
    brne read_char

end_sequence:
    ldi r16, 0x20       ; Marca final da sequência
    st Z+, r16
    rjmp main_loop

; ===== Contar número de caracteres =====
count_chars:
    ldi ZH, 0x04        ; Endereço 0x401
    ldi ZL, 0x01
    st Z+, r19          ; Armazena o contador
    out PORTC, r19      ; Envia à saída
    rjmp main_loop

; ===== Contar ocorrências de um caractere =====
count_specific:
    in r16, PIND        ; Lê caractere para contar
    clr r20             ; Zera o contador de ocorrências
	clr r16             ; Zera o contador de ocorrências
	in r16, PIND        ; Lê caractere para contar

    ldi ZH, 0x03        ; Início da memória 0x300
    ldi ZL, 0x00
count_loop:
    ld r18, Z+          ; Lê caractere da tabela
    cpi r18, 0x20       ; Verifica final da sequência
    breq store_count
    cp r16, r18         ; Compara com o caractere dado
    brne count_loop
    inc r20             ; Incrementa se houver correspondência
    rjmp count_loop

store_count:
    ldi ZH, 0x04        ; Endereço 0x402
    ldi ZL, 0x02
    st Z+, r20          ; Armazena resultado
	inc ZL
    out PORTC, r20      ; Envia à saída
    rjmp main_loop

; ===== Criar tabela de frequência =====
criaTabelaF:
    ldi ZH, 0x03        ; Início da sequência de caracteres (0x300)
    ldi ZL, 0x00
    clr r20             ; Zera contador auxiliar

    ; Zerando tabela de frequência
    ldi YH, 0x04        ; Início da tabela 0x400
    ldi YL, 0x00


fimZeraTabela:
    ; Contando frequências
contaFrequencias:
    ld r18, Z+          ; Lê caractere da sequência
    cpi r18, 0x20       ; Verifica final da sequência (espaço)
    breq fimTabela
    ldi YH, 0x04        ; Início da tabela de frequência (0x400)
    mov YL, r18         ; Índice do caractere (valor ASCII)
    ld r21, Y           ; Lê a frequência atual
    cpi r21, 0xFF       ; Verifica se a frequência é 0xFF (não inicializado)
    breq inicializaFrequencia
    inc r21             ; Incrementa a frequência
    st Y, r21           ; Atualiza a tabela

    rjmp contaFrequencias

inicializaFrequencia:
    ldi r21, 0x01       ; Inicializa a frequência como 1
    st Y, r21           ; Armazena na tabela

    rjmp contaFrequencias

fimTabela:
    rjmp main_loop      ; Retorna ao loop principal
