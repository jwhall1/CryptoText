;Main.asm
;This program will ask the user for a file to encrypt, encrypt/decrypt the file, and display the key to the screen
;Author: Corey Maryan, John William Hall Jr

INCLUDE Irvine32.inc
TAB = 9                                                          ;ascii code for tab in HEX

.data
prompt1 BYTE "Enter the name of the file you wish to encrypt/decrypt: ",0
prompt2 BYTE "Enter the name of the file to be written to: ",0
prompt3 BYTE "Run the program again Y/N? ",0
prompt4 BYTE "Your files were successfully encrypted/decrypted",0
readFileHandle DWORD ?	                                        ;the filehandle for the file to read from
writeFileHandle DWORD ?	                                        ;the filehandle for the file to write to
bytesRead DWORD ?	                                             ;the amount of bytes read from the file
key BYTE 16 DUP(0)	                                             ;the key will be 16 hex bytes in size
buffer BYTE 16 DUP(0)	                                        ;buffer for the reader file string

.code
main PROC
	mov ecx,100
     call random                                                 ;generate the 16 hex byte random key
L1:
			                                   
     mov edx, OFFSET key
     call writeString
     call Crlf
	call openInput	                                             ;ask for the name of the file to be read from and open in if possible
	call Crlf	                                                  ;move down a line in the terminal
	call openOutput	                                        ;ask for the name of the file to be written to and open it
	call Crlf	                                                  ;move down a line in the terminal
    	call encryptFile	                                        ;encrypt the file
	call writeKey	                                             ;write the random key to the screen
	mov edx,OFFSET prompt4	                                   ;move the success display into edx
	call WriteString	                                        ;write it to the screen
	call Crlf	                                                  ;move down a line
	mov edx,OFFSET prompt3                                      ;move the final prompt asking to continue the program into edx
	call WriteString	                                        ;write the string to the screen
     call ReadChar
     xor eax, 5497
     jnz CONTINUE
	loop L1
CONTINUE:
     
	exit
main ENDP

openInput PROC
	;asked for the file and opens the file to  read
	;returns the file open and edx = offset of the file name,eax = valid file handle if opened succefully otherwise eax = invalid file handle
	;requires nothing
	mov edx,OFFSET prompt1                            
	call WriteString                                            ;displays contents of edx to terminal
	mov edx, OFFSET buffer	                                   ;points to the buffer the string will be copied into
	mov ecx, SIZEOF buffer	                                   ;maximum characters the user can enter for the filename
	call ReadString	                                        ;input the String
	call OpenInputFile	                                        ;opens the file
	cmp eax,INVALID_HANDLE_VALUE	;checks to see if eax contains the contant for file not found
	jne	L2	;jump to the end of the procedure if the register does not contain the invalid file handle i.e. the file was opened successfully
	call WriteWindowsMsg	;prints the the screen the most recent error generated which in this case would be file not found
	exit
L2:
	mov readFileHandle, eax	                                   ;save the file handle of the input file in memory
	ret
openInput ENDP

openOutput PROC
	;asked for the file and opens the file to  write to
	;returns the file open and edx = offset of the file name,eax = valid file handle if opened succefully otherwise eax = 2 
	;requires the file to exist
	mov edx, OFFSET prompt2
	call WriteString	                                        ;display the prompt
	mov edx, OFFSET buffer	                                   ;points to the buffer the string will be copied into
	mov ecx, SIZEOF buffer	                                   ;maximum characters the user can enter for the filename
	call ReadString	                                        ;input the String
	call CreateOutputFile	                                   ;opens the file
	cmp eax,INVALID_HANDLE_VALUE	;checks to see if eax contains the contant for file not found
	jne	L1	;jump to the end of the procedure if the register does not equal the invalid file handle i.e. the file was opened successfully
	call WriteWindowsMsg	;prints the the screen the most recent error generated which in this case would be file not found
	exit
L1:
	mov writeFileHandle,eax	                                   ;save the write file handle in memory
	ret
openOutput ENDP
		
encryptFile PROC
	;encrypts the file by xoring it with the key
	;returns the encrpted file written to the output file and the input file is now xor with the key
	;requires the file the user wants to encrypt to be open 
	mov ecx,SIZEOF buffer	                                        ;number of bytes to be read
	mov edx,OFFSET buffer                                            ;file to be read from
	mov eax,readFileHandle	                                        ;file handle to be read from
    
L1:
     mov ecx, SIZEOF buffer
     push ecx                                                         ;save state of ecx
     push edx                                                         ;save state of edx
     push eax                                                         ;save state of eax
     call ReadFromFile	                                             ;read the file
    	jc END1	                                        ;if there was an error the carry flag will be set so jump to display the error
	mov bytesRead,eax	                              ;save the amount of bytes read
	cmp eax,0	                                        ;compare the number of bytes read with 0
	je END2	                                        ;jump to the end if no bytes were read
	mov ecx,bytesRead	                              ;number of bytes to be xorD 
	mov esi,0	                                        ;starting point for the buffer and key
     mov edx,0                                         ;clears out edx
     mov edx, OFFSET buffer                            ;loads contents of buffer into edx

	L2:
          mov al,key[esi]	                         ;move the contents of key at index esi into al
		xor buffer[esi],al	                         ;encrypt the file using the key
         	inc esi	                                   ;go to the next location for each array
		loop L2
          mov edx,OFFSET buffer                        ;loads edx with contents of buffer
		mov ecx,bytesRead	                         ;move the amount of bytes to write into ecx
		;mov edx,OFFSET buffer	                    ;move the file to be written to into the edx register
		mov eax,writefileHandle	                    ;moving a valid file handle into eax
		call WriteToFile	                         ;write the encrypted bytes to the file
		cmp eax,0	                                   ;see if there was an error writting to the file
		jne L3
		call WriteWindowsmsg	                    ;display the error
		exit	                                        ;exit
	L3:
	pop eax	                                        ;restore eax
	pop edx	                                        ;restore edx
	pop ecx	                                        ;restore ecx
	loop L1
END1:
	call WriteWindowsMsg	                         ;display the most recent error
	exit
END2:    
     pop ecx                                            ;returns to previous state        
     pop edx                                            ;returns to previous state  
     pop eax                                            ;returns to previous state  
     mov eax,readFileHandle	                          ;move into eax the file handle of the file we were writing to
	call CloseFile	                                    ;close the file we were writing to 
	mov eax,writeFileHandle	                          ;move into eax the file handle of the file we were reading from
	call CloseFile	                                    ;close the file we were reading from                                            
     ret
encryptFile ENDP

random PROC
	;creates a random 16 hex byte key and displays it to the screen then saves it in memory to xor with the file
	;returns the key now has 16 random hex BYTES
	;requires nothing
	mov eax,0	                                             ;clear out eax
	mov esi,0
	call Randomize	                                        ;the random range of numbers you want to choose from
	mov ecx,SIZEOF key	                                   ;number of times you want the loop to execute
L1:
	 call Random32	                                        ;produces a random number from 0 to 49 in eax
      mov key[esi],al	                                   ;we want to use just what is in al here since we are moving into an array of bytes
	 inc esi	                                             ;increase the index of the key by 1
	 loop L1
	 ret
random ENDP

writeKey PROC
	;writes the random key to the screen
	;returns the key displayed to the screen, AL = last index of key
	;requires nothing
	mov ecx,SIZEOF key	                                   ;number of times we want to loop
	mov esi,0	                                             ;starting point
L1:
	 mov ebx,TYPE key                                      ;this is the type of integer format we want to display
	 mov al,key[esi]	       ;we want to use just what is in al here since we are moving into an array of bytes
	 call WriteHexB	                                   ;display the integer to the screen in HEX format
	 inc esi	                                             ;increase the index of the key by 1
	 mov al,TAB
	 call WriteChar	                                   ;put a space between each number
	 loop L1
	 call Crlf	                                        ;move down a line on the terminal
	 ret
writeKey ENDP
END main