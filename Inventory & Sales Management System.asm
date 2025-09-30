

.MODEL SMALL
.STACK 100H

.DATA
; Users (hardcoded)
user1 DB 'admin$'
pass1 DB 'admin$'
user2 DB 'cash$$'
pass2 DB 'cash$$'
user3 DB 'mgr$$$'
pass3 DB 'mgr$$$'

currentRole DB 0FFh   ; 0=Admin 1=Cashier 2=Manager 255=None

; Messages with improved ASCII aesthetics
msg_user DB 13,10,'+---------------------------------------+',13,10,'|            USER LOGIN                 |',13,10,'+---------------------------------------+',13,10,'Username: $'
msg_pass DB 13,10,'Password: $'
msg_bad  DB 13,10,'[ERROR] Invalid credentials! Please try again.$'
msg_ok   DB 13,10,'[SUCCESS] Login successful! Welcome!$'
msg_bye  DB 13,10,'Thank you for using our system. Goodbye!$'
msg_inv  DB 13,10,'[WARNING] Invalid choice! Please try again.$'
msg_out  DB 13,10,'Logged out successfully.$'

menu_admin DB 13,10,'+=============================================================+',13,10,'|                    ADMIN PANEL                            |',13,10,'+=============================================================+',13,10,'|  1. Add Product        4. View Products                   |',13,10,'|  2. Update Product     5. Sales Log                       |',13,10,'|  3. Delete Product     6. Logout                          |',13,10,'|  7. View Sales Report  8. Exit                            |',13,10,'|  9. Search Products   10. Sort Products  11. Filter Low Stock |',13,10,'| 12. Restock Product                                       |',13,10,'+=============================================================+$'
menu_cash  DB 13,10,'+=============================================================+',13,10,'|                   CASHIER PANEL                          |',13,10,'+=============================================================+',13,10,'|  1. View Products                                         |',13,10,'|  2. Sell Products                                         |',13,10,'|  3. Logout                                                |',13,10,'|  4. Exit                                                  |',13,10,'|  5. Undo Last Transaction                                 |',13,10,'+=============================================================+$'
menu_mgr   DB 13,10,'+=============================================================+',13,10
           DB '|                   MANAGER PANEL                          |',13,10
           DB '+=============================================================+',13,10
           DB '|  1. Add Product                                           |',13,10
           DB '|  2. Update Product                                        |',13,10
           DB '|  3. Delete Product                                        |',13,10
           DB '|  4. View Products                                         |',13,10
           DB '|  5. Search Products                                       |',13,10
           DB '|  6. Sort Products                                         |',13,10
           DB '|  7. Inventory Report & Low Stock Notifications            |',13,10
           DB '|  8. Undo Last Transaction                                 |',13,10
           DB '|  9. Restock Product                                       |',13,10
           DB '| 10. Reorder Queue                                         |',13,10
           DB '| 11. Logout                                                |',13,10
           DB '| 12. Exit                                                  |',13,10
           DB '+=============================================================+$'
msg_choice DB 13,10,'Your choice: $'

; Product arrays
MAX_PROD EQU 20
prod_id   DB MAX_PROD DUP(0)
prod_name DB MAX_PROD * 20 DUP('$')  ; 20 chars per name
prod_price DW MAX_PROD DUP(0)        ; word for larger prices
prod_qty  DW MAX_PROD DUP(0)         ; word for larger quantities
next_id   DB 6                       ; auto-increment ID (start from 6 after initial 5)

; Sales & Invoice System
MAX_INVOICE_ITEMS EQU 10
invoice_prod_id   DB MAX_INVOICE_ITEMS DUP(0)
invoice_qty       DW MAX_INVOICE_ITEMS DUP(0) 
invoice_price     DW MAX_INVOICE_ITEMS DUP(0)
invoice_count     DB 0                        ; current items in invoice
invoice_total     DW 0                        ; total amount
customer_paid     DW 0                        ; amount paid by customer
change_amount     DW 0                        ; change to return

; Invoice numbering
next_invoice_no   DW 1                        ; auto-increment invoice number

; Sales Log
MAX_SALES EQU 50
sales_invoice_no  DW MAX_SALES DUP(0)        ; invoice numbers
sales_prod_id     DB MAX_SALES DUP(0)        ; product IDs  
sales_qty         DW MAX_SALES DUP(0)        ; quantities sold
sales_count       DB 0                        ; total sales entries

; Reorder Queue System
MAX_REORDER EQU 20
reorder_prod_id   DB MAX_REORDER DUP(0)      ; products marked for reorder
reorder_count     DB 0                       ; number of products in reorder queue

; Sales Report working buffers and labels
sold_totals       DW 256 DUP(0)               ; total qty sold per product id (0..255)
total_sales_amount DW 0                        ; aggregate revenue (approx, 16-bit)
unique_invoice_count DW 0                      ; count of distinct invoices
best_selling_id   DB 0
best_selling_qty  DW 0
prev_invoice_no   DW 0FFFFh

; Sales Report strings
msg_sales_report   DB 13,10,'+=================================+',13,10,'|         SALES REPORT            |',13,10,'+=================================+$'
label_total_sales  DB 13,10,'Total Sales Amount:  $'
label_sales_count  DB 13,10,'Total Sales Count:   $'
label_best_selling DB 13,10,'Best-Selling Product: $'
label_units_sold   DB ' units sold$'

; Transaction Undo Messages
msg_confirm_undo   DB 13,10,'[CONFIRM] Undo last sale? (Y/N): $'
msg_no_undos       DB 13,10,'[INFO] No sales to undo.$'
msg_undo_success   DB 13,10,'[SUCCESS] Sale undone successfully.$'

; Restock Messages
msg_restock        DB 13,10,'[INFO] Enter restock quantity: $'
msg_restocked      DB 13,10,'[SUCCESS] Product restocked! New Qty: $'
msg_restock_cancel DB 13,10,'[INFO] Restock cancelled.$'
msg_restock_prompt DB 13,10,'[CONFIRM] Restock now? (Y/N): $'

; Reorder Queue Messages
msg_mark_reorder   DB 13,10,'[CONFIRM] Mark low stock products for reorder? (Y/N): $'
msg_marked_reorder DB 13,10,'[SUCCESS] Low stock products marked for reorder.$'
msg_reorder_queue_hdr DB 13,10,'+=================================+',13,10,'|        REORDER QUEUE            |',13,10,'+=================================+$'
msg_no_reorder     DB 13,10,'[INFO] No products in reorder queue.$'
msg_reorder_menu   DB 13,10,'Reorder Options: 1.Restock Selected  2.Clear Queue  3.Back$'

; Enhanced Undo Messages
msg_undo_menu      DB 13,10,'Undo Options: 1.Undo Last  2.Undo by Invoice#  3.Back$'
msg_invoice_prompt DB 13,10,'Enter Invoice Number to undo: $'
msg_invoice_not_found DB 13,10,'[ERROR] Invoice not found or already undone.$'
; Sales Report submenu strings
msg_sales_report_menu DB 13,10,'+----------------------------+',13,10,'|      SALES REPORT MENU     |',13,10,'+----------------------------+',13,10,'| 1. Summary                 |',13,10,'| 2. Last 5 invoices         |',13,10,'| 3. Last 10 invoices        |',13,10,'| 4. Last N invoices         |',13,10,'| 5. Back                    |',13,10,'+----------------------------+$'
msg_lastn_prompt      DB 13,10,'Enter N (number of recent invoices): $'
msg_invalid_n         DB 13,10,'[ERROR] Invalid N.$'

; Manager Inventory & Notifications strings
msg_inv_report_hdr DB 13,10,'+=================================+',13,10,'|     INVENTORY REPORT            |',13,10,'+=================================+$'
msg_notif_hdr      DB 13,10,'---------------------------------',13,10,'Notifications:',13,10,'---------------------------------$'
msg_low_stock_pref DB 13,10,'!! Low stock of $'
msg_low_stock_suf  DB '. Restock ASAP!$'
msg_no_low_stock   DB 13,10,'[INFO] No low stock items.$'

msg_add   DB 13,10,'+=======================================+',13,10,'|          ADD NEW PRODUCT              |',13,10,'+=======================================+$'
msg_upd   DB 13,10,'+=======================================+',13,10,'|         UPDATE PRODUCT                |',13,10,'+=======================================+$'
msg_del   DB 13,10,'+=======================================+',13,10,'|         DELETE PRODUCT                |',13,10,'+=======================================+$'
msg_view  DB 13,10,'+=======================================================================+',13,10,'|                          PRODUCT INVENTORY                           |',13,10,'+=======================================================================+$'
table_header DB 13,10,'+----+----------------------+-------------+------+',13,10,'| ID | Product Name         | Price(Taka) | Qty  |',13,10,'+----+----------------------+-------------+------+$'
table_line   DB 13,10,'+----+----------------------+-------------+------+$'
upd_menu     DB 13,10,'Update Options: 1.Name 2.Price 3.Quantity 4.All$'
msg_back     DB 13,10,'Returning to main menu...',13,10,'$'
msg_back_help DB 13,10,'(Enter 0 to go back to menu)',13,10,'$'
debug_storing DB 13,10,'STORING: $'
msg_id    DB 13,10,'Product ID: $'
msg_name  DB 13,10,'Product Name: $'
msg_price DB 13,10,'Price (Taka): $'
msg_qty   DB 13,10,'Quantity: $'
msg_full  DB 13,10,'[ERROR] Storage is full! Cannot add more products.$'
msg_dup   DB 13,10,'[ERROR] Duplicate ID! This ID already exists.$'
msg_nf    DB 13,10,'[ERROR] Product not found!$'
msg_added DB 13,10,'[SUCCESS] Product added successfully!',13,10,'$'
msg_updated DB 13,10,'[SUCCESS] Product updated successfully!',13,10,'$'
msg_deleted DB 13,10,'[SUCCESS] Product deleted successfully!',13,10,'$'
nl DB 13,10,'$'

; ====== Search + Inline Sort buffers and strings ======
LOW_STOCK_THRESHOLD EQU 20
result_idx           DB MAX_PROD DUP(0) ; indices into product arrays
result_count         DB 0
sort_mode            DB 0
low_stock_view_flag  DB 0
tmp_upper_name       DB 21 DUP(0)
tmp_upper_query      DB 21 DUP(0)
warn_truncated_flag  DB 0

msg_search_hdr2  DB 13,10,'+----------------------------+',13,10,'|        SEARCH MENU         |',13,10,'+----------------------------+$'
msg_search_menu2 DB 13,10,'| 1. Search by ID            |',13,10,'| 2. Search by Name          |',13,10,'| 3. Filter: Low Stock (<=20)|',13,10,'| 4. Back                    |',13,10,'+----------------------------+$'
msg_match_type   DB 13,10,'Match Type: 1.Exact  2.Contains (case-insensitive)$'
msg_sort_inline  DB 13,10,'Do you want to sort these results?',13,10,'1.Price ^  2.Price v  3.Qty ^  4.Qty v  5.No (keep view)  6.Back$'
msg_results_hdr  DB 13,10,'+================ RESULTS ================+$'
msg_no_matches   DB 13,10,'[INFO] No products matched your search.$'
msg_res_prompt   DB 13,10,'Next: 1.New Search  2.Back to Search Menu  3.Back to Admin$'
msg_warn_trunc   DB 13,10,'[WARN] Too many matches, showing first N only.$'

; Admin Search/Sort/Filter strings
msg_search_hdr    DB 13,10,'+=================================+',13,10,'|         SEARCH PRODUCTS         |',13,10,'+=================================+$'
msg_search_menu   DB 13,10,'Search: 1.By ID  2.By Name  3.By Price Range  4.By Quantity Range  5.Back$'
msg_sort_hdr      DB 13,10,'+=================================+',13,10,'|          SORT PRODUCTS          |',13,10,'+=================================+$'
msg_sort_menu     DB 13,10,'Sort: 1.Price Asc  2.Price Desc  3.Qty Asc  4.Qty Desc  5.Back$'
msg_filter_hdr    DB 13,10,'+=================================+',13,10,'|       LOW STOCK (<= 20)         |',13,10,'+=================================+$'
msg_no_low_stock_prod DB 13,10,'[INFO] No low stock products found.$'
; Temporaries
tmp_min DW 0
tmp_max DW 0

; Sales & Invoice Messages with improved ASCII aesthetics
msg_sell    DB 13,10,'+=======================================================================+',13,10,'|                          NEW INVOICE                                 |',13,10,'+=======================================================================+$'
msg_add_item DB 13,10,'Add Item to Invoice$'
msg_search  DB 13,10,'+----------------------------------------------------------------------+',13,10,'| 1.Add Item  2.Remove Item  3.Products  4.Invoice  5.Checkout        |',13,10,'|                           6.Cancel                                  |',13,10,'+----------------------------------------------------------------------+$'
msg_add_item_menu DB 13,10,'Search Method: 1.By ID  2.By Name  3.Back$'
msg_item_id DB 13,10,'Enter Product ID: $'
msg_item_name DB 13,10,'Enter Product Name: $'
msg_sale_qty  DB 13,10,'Sale Quantity: $'
msg_not_enough DB 13,10,'[ERROR] Not enough stock available!$'
msg_unknown_prod DB 'Unknown Product     $'  ; 20 chars for formatting
msg_item_added DB 13,10,'[SUCCESS] Item added to invoice successfully!$'
msg_invoice_empty DB 13,10,'[INFO] Invoice is empty! Add some items first.$'
msg_invoice_header DB 13,10,'+=======================================================================+',13,10,'|                          CURRENT INVOICE                            |',13,10,'+=======================================================================+$'
msg_invoice_line DB 13,10,'+----+--------------------+-----+-------+-------+',13,10,'|Item| Product            | Qty | Price | Total |',13,10,'+----+--------------------+-----+-------+-------+$'
msg_invoice_sep  DB 13,10,'+----+--------------------+-----+-------+-------+$'
msg_grand_total DB 13,10,'GRAND TOTAL: $'
msg_taka        DB ' Taka$'
msg_payment     DB 13,10,'Customer Payment (Taka): $'
msg_change      DB 13,10,'Change: $'
msg_insufficient DB 13,10,'[ERROR] Insufficient payment! Please pay the full amount.$'
msg_sale_complete DB 13,10,'[SUCCESS] Sale completed successfully! Thank you!$'

; Sales Log Messages with improved ASCII aesthetics
msg_sales_log   DB 13,10,'+=======================================================================+',13,10,'|                          SALES LOG                                   |',13,10,'+=======================================================================+$'
sales_header    DB 13,10,'+----+---+--------------------+-----+-------+',13,10,'|Inv#|ID | Product            | Qty | Total |',13,10,'+----+---+--------------------+-----+-------+',13,10,'$'
sales_line      DB 13,10,'+----+---+--------------------+-----+-------+$'
msg_no_sales    DB 13,10,'[INFO] No sales recorded yet. Start selling to see data here!$'

; Additional strings for display
space_pad       DB ' $'
space_pad2      DB '  $'
space_pad3      DB '   $'

; Welcome Banner - ASCII only
welcome_banner DB 13,10
    DB '+=======================================================================+',13,10
    DB '|                                                                       |',13,10
    DB '|               INVENTORY & SALES MANAGEMENT SYSTEM                    |',13,10
    DB '|                                                                       |',13,10
    DB '|                                                                       |',13,10
    DB '|                                                                       |',13,10
    DB '|              Streamline Your Business Operations                     |',13,10
    DB '|                                                                       |',13,10
    DB '|   Features:                                                           |',13,10
    DB '|   * Product Management      * Point of Sale                          |',13,10
    DB '|   * Multi-User Access       * Sales Analytics                        |',13,10
    DB '|   * Invoice Generation      * Secure Authentication                  |',13,10
    DB '|                                                                       |',13,10
    DB '|              Developed for CSE 341 - Assembly Language               |',13,10
    DB '|                                                                       |',13,10
    DB '+=======================================================================+',13,10,'$'

press_enter DB 13,10,'        >> Press ENTER to continue to login... <<',13,10,'$'

inbuf DB 6 DUP('$')
temp_name DB 20 DUP('$')
tab DB 9,'$'

.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
    
    ; Show welcome screen
    CALL SHOW_WELCOME
    
    ; Initialize system with sample products
    CALL INIT_PRODUCTS

LOGIN:
    ; Get username
    LEA DX,msg_user
    MOV AH,9
    INT 21h
    CALL GET_INPUT
    
    ; Check user1
    LEA SI,user1
    LEA DI,inbuf
    CALL COMPARE_STR
    CMP AL,1
    JE CHK_PASS1
    
    ; Check user2
    LEA SI,user2
    LEA DI,inbuf
    CALL COMPARE_STR
    CMP AL,1
    JE CHK_PASS2
    
    ; Check user3
    LEA SI,user3
    LEA DI,inbuf
    CALL COMPARE_STR
    CMP AL,1
    JE CHK_PASS3
    
    JMP BAD_LOGIN

CHK_PASS1:
    LEA DX,msg_pass
    MOV AH,9
    INT 21h
    CALL GET_INPUT
    LEA SI,pass1
    LEA DI,inbuf
    CALL COMPARE_STR
    CMP AL,1
    JNE BAD_LOGIN
    MOV currentRole,0    ; Admin
    JMP GOOD_LOGIN

CHK_PASS2:
    LEA DX,msg_pass
    MOV AH,9
    INT 21h
    CALL GET_INPUT
    LEA SI,pass2
    LEA DI,inbuf
    CALL COMPARE_STR
    CMP AL,1
    JNE BAD_LOGIN
    MOV currentRole,1    ; Cashier
    JMP GOOD_LOGIN

CHK_PASS3:
    LEA DX,msg_pass
    MOV AH,9
    INT 21h
    CALL GET_INPUT
    LEA SI,pass3
    LEA DI,inbuf
    CALL COMPARE_STR
    CMP AL,1
    JNE BAD_LOGIN
    MOV currentRole,2    ; Manager
    JMP GOOD_LOGIN

BAD_LOGIN:
    LEA DX,msg_bad
    MOV AH,9
    INT 21h
    LEA DX,nl
    MOV AH,9
    INT 21h
    JMP LOGIN

GOOD_LOGIN:
    LEA DX,msg_ok
    MOV AH,9
    INT 21h
    LEA DX,nl
    MOV AH,9
    INT 21h

MENU_LOOP:
    MOV AL,currentRole
    CMP AL,0
    JE SHOW_ADMIN
    CMP AL,1
    JE SHOW_CASH
    CMP AL,2
    JE SHOW_MGR
    JMP LOGIN

SHOW_ADMIN:
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,menu_admin
    MOV AH,9
    INT 21h
    JMP GET_CHOICE

SHOW_CASH:
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,menu_cash
    MOV AH,9
    INT 21h
    JMP GET_CHOICE

SHOW_MGR:
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,menu_mgr
    MOV AH,9
    INT 21h
    JMP GET_CHOICE

GET_CHOICE:
    LEA DX,msg_choice
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    ; AX now contains the number entered
    ; Convert to AL for comparison
    
    MOV BL,currentRole
    CMP BL,0          ; Admin
    JE ADMIN_MENU
    CMP BL,1          ; Cashier
    JE CASH_MENU
    CMP BL,2          ; Manager
    JE MGR_MENU
    JMP INVALID

ADMIN_MENU:
    CMP AX,1
    JE DO_ADD
    CMP AX,2
    JE DO_UPD
    CMP AX,3
    JE DO_DEL
    CMP AX,4
    JE DO_VIEW
    CMP AX,5
    JE DO_SALES_LOG
    CMP AX,6
    JE DO_LOGOUT
    CMP AX,7
    JE DO_VIEW_SALES_REPORT
    CMP AX,8
    JE DO_EXIT
    CMP AX,9
    JE DO_SEARCH
    CMP AX,10
    JE DO_SORT
    CMP AX,11
    JE DO_FILTER_LOW
    CMP AX,12
    JE DO_RESTOCK
    JMP INVALID

CASH_MENU:
    CMP AX,1
    JE DO_VIEW
    CMP AX,2
    JE DO_SELL
    CMP AX,3
    JE DO_LOGOUT
    CMP AX,4
    JE DO_EXIT
    CMP AX,5
    JE DO_UNDO_SALE
    JMP INVALID

MGR_MENU:
    CMP AX,1
    JE DO_ADD
    CMP AX,2
    JE DO_UPD
    CMP AX,3
    JE DO_DEL
    CMP AX,4
    JE DO_VIEW
    CMP AX,5
    JE DO_SEARCH
    CMP AX,6
    JE DO_SORT
    CMP AX,7
    JE DO_INV_REPORT
    CMP AX,8
    JE DO_UNDO_SALE
    CMP AX,9
    JE DO_RESTOCK
    CMP AX,10
    JE DO_REORDER_QUEUE
    CMP AX,11
    JE DO_LOGOUT
    CMP AX,12
    JE DO_EXIT
    JMP INVALID

DO_ADD:
    CALL ADD_PROD
    JMP MENU_LOOP
DO_UPD:
    CALL UPD_PROD
    JMP MENU_LOOP
DO_DEL:
    CALL DEL_PROD
    JMP MENU_LOOP
DO_VIEW:
    CALL VIEW_PROD
    JMP MENU_LOOP
DO_SALES_LOG:
    CALL VIEW_SALES_LOG
    JMP MENU_LOOP
DO_VIEW_SALES_REPORT:
    CALL SALES_REPORT_MENU
    JMP MENU_LOOP
DO_SELL:
    CALL SELL_PROD
    JMP MENU_LOOP
DO_SEARCH:
    ; Use the new integrated search menu with case-insensitive partial name search
    CALL SEARCH_MENU
    JMP MENU_LOOP
DO_SORT:
    CALL SORT_PROD
    JMP MENU_LOOP
DO_FILTER_LOW:
    CALL FILTER_LOW_STOCK
    JMP MENU_LOOP
DO_INV_REPORT:
    CALL VIEW_INVENTORY_REPORT
    JMP MENU_LOOP
DO_UNDO_SALE:
    CALL UNDO_LAST_SALE
    JMP MENU_LOOP
DO_RESTOCK:
    CALL RESTOCK_PROD
    JMP MENU_LOOP
DO_REORDER_QUEUE:
    CALL MANAGE_REORDER_QUEUE
    JMP MENU_LOOP
DO_LOGOUT:
    MOV currentRole,0FFh
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_out
    MOV AH,9
    INT 21h
    LEA DX,nl
    MOV AH,9
    INT 21h
    JMP LOGIN
DO_EXIT:
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_bye
    MOV AH,9
    INT 21h
    MOV AX,4C00h
    INT 21h

INVALID:
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_inv
    MOV AH,9
    INT 21h
    JMP MENU_LOOP

; Get 6-char input for login
GET_INPUT PROC
    PUSH SI
    LEA SI,inbuf
    MOV CX,6
GI_CLEAR:
    MOV BYTE PTR [SI],'$'
    INC SI
    LOOP GI_CLEAR
    
    LEA SI,inbuf
    MOV CX,0
GI_LOOP:
    MOV AH,1
    INT 21h
    CMP AL,13
    JE GI_DONE
    CMP CX,6
    JAE GI_LOOP
    MOV [SI],AL
    INC SI
    INC CX
    JMP GI_LOOP
GI_DONE:
    POP SI
    RET
GET_INPUT ENDP

; Get string with back option - returns AL=0 if user wants to go back
GET_STRING_BACK PROC
    PUSH SI
    PUSH CX
    PUSH BX
    MOV SI,0
    MOV CX,20
    MOV BX,DI
    ; Check if first character is '0' (go back)
    MOV AH,1
    INT 21h
    CMP AL,'0'
    JE GSB_BACK
    CMP AL,13
    JE GSB_EMPTY
    ; Store first character
    MOV [BX+SI],AL
    INC SI
GSB_LOOP:
    MOV AH,1
    INT 21h
    CMP AL,13
    JE GSB_DONE
    CMP SI,CX
    JAE GSB_LOOP
    MOV [BX+SI],AL
    INC SI
    JMP GSB_LOOP
GSB_BACK:
    ; Wait for Enter after '0'
    MOV AH,1
    INT 21h
    MOV AL,0    ; return 0 to indicate back
    JMP GSB_EXIT
GSB_EMPTY:
    MOV AL,0    ; empty input = back
    JMP GSB_EXIT
GSB_DONE:
    MOV BYTE PTR [BX+SI],0    ; null terminator for string comparison
    MOV AL,1    ; return 1 to indicate success
GSB_EXIT:
    POP BX
    POP CX
    POP SI
    RET
GET_STRING_BACK ENDP

; Get number with back option - returns AL=0 if back, AL=1 if success, number in BX
GET_NUMBER_BACK PROC
    PUSH CX
    PUSH DX
    XOR BX,BX    ; result accumulator
    ; Check first character
    MOV AH,1
    INT 21h
    CMP AL,'0'
    JE GNB_CHECK_BACK
    CMP AL,13
    JE GNB_BACK
    SUB AL,'0'
    XOR AH,AH
    MOV BX,AX
GNB_LOOP:
    MOV AH,1
    INT 21h
    CMP AL,13
    JE GNB_DONE
    CMP AL,'0'
    JB GNB_LOOP
    CMP AL,'9'
    JA GNB_LOOP
    SUB AL,'0'
    XOR AH,AH
    MOV CX,AX    ; save digit
    MOV AX,BX    ; get current result  
    MOV DX,10
    MUL DX       ; AX = BX * 10
    ADD AX,CX    ; add digit
    MOV BX,AX    ; save back
    JMP GNB_LOOP
GNB_CHECK_BACK:
    ; Check if next char is Enter (just '0' means back)
    MOV AH,1
    INT 21h
    CMP AL,13
    JE GNB_BACK
    ; Otherwise continue as number starting with 0
    SUB AL,'0'
    XOR AH,AH
    MOV BX,AX
    JMP GNB_LOOP
GNB_BACK:
    XOR AX,AX    ; return 0 for back
    POP DX
    POP CX
    RET
GNB_DONE:
    MOV AX,BX    ; return number in AX
    POP DX
    POP CX
    RET
GET_NUMBER_BACK ENDP
; Get multi-character input until Enter
GET_STRING PROC
    PUSH SI
    PUSH CX
    PUSH BX
    MOV SI,0
    MOV CX,20    ; max 20 chars
    MOV BX,DI    ; use BX as base register
GS_LOOP:
    MOV AH,1
    INT 21h
    CMP AL,13    ; Enter
    JE GS_DONE
    CMP SI,CX
    JAE GS_LOOP  ; ignore if too long
    MOV [BX+SI],AL
    INC SI
    JMP GS_LOOP
GS_DONE:
    ; Null terminate
    MOV BYTE PTR [BX+SI],0
    POP BX
    POP CX
    POP SI
    RET
GET_STRING ENDP

; Get number input until Enter, return value in AX
GET_NUMBER PROC
    PUSH BX
    PUSH CX
    PUSH DX
    XOR BX,BX    ; BX will hold our result, start with 0
GN_LOOP:
    MOV AH,1
    INT 21h
    CMP AL,13    ; Enter pressed?
    JE GN_DONE
    CMP AL,'0'
    JB GN_LOOP   ; ignore non-digits
    CMP AL,'9'
    JA GN_LOOP   ; ignore non-digits
    SUB AL,'0'   ; convert ASCII digit to number
    XOR AH,AH    ; clear high byte, now AX has the digit
    ; BX = BX * 10 + digit
    MOV CX,AX    ; save digit
    MOV AX,BX    ; get current result
    MOV DX,10
    MUL DX       ; AX = BX * 10
    ADD AX,CX    ; add new digit
    MOV BX,AX    ; save back to BX
    JMP GN_LOOP
GN_DONE:
    MOV AX,BX    ; return result in AX
    POP DX
    POP CX
    POP BX
    RET
GET_NUMBER ENDP

; Compare strings SI and DI, return AL=1 if equal
COMPARE_STR PROC
    PUSH CX
    MOV CX,6
    MOV AL,1
CS_LOOP:
    MOV BL,[SI]
    MOV BH,[DI]
    CMP BL,BH
    JNE CS_NE
    INC SI
    INC DI
    LOOP CS_LOOP
    JMP CS_DONE
CS_NE:
    MOV AL,0
CS_DONE:
    POP CX
    RET
COMPARE_STR ENDP

; Find empty slot, return SI=index or SI=255 if full
FIND_EMPTY PROC
    MOV SI,0
    MOV CX,MAX_PROD
FE_LOOP:
    CMP prod_id[SI],0
    JE FE_FOUND
    INC SI
    LOOP FE_LOOP
    MOV SI,255
FE_FOUND:
    RET
FIND_EMPTY ENDP

; Find product by ID in AL, return SI=index or SI=255 if not found
FIND_PROD PROC
    MOV SI,0
    MOV CX,MAX_PROD
FP_LOOP:
    CMP prod_id[SI],AL
    JE FP_FOUND
    INC SI
    LOOP FP_LOOP
    MOV SI,255
FP_FOUND:
    RET
FIND_PROD ENDP

ADD_PROD PROC
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_add
    MOV AH,9
    INT 21h
    LEA DX,msg_back_help
    MOV AH,9
    INT 21h
    
    CALL FIND_EMPTY
    CMP SI,255
    JE AP_FULL
    
    ; Auto-assign ID and show it
    MOV AL,next_id
    MOV prod_id[SI],AL
    LEA DX,msg_id
    MOV AH,9
    INT 21h
    XOR AH,AH
    MOV AL,next_id
    CALL PRINT_NUM
    LEA DX,nl
    MOV AH,9
    INT 21h
    INC next_id
    
    ; Get name with back option
    LEA DX,msg_name
    MOV AH,9
    INT 21h
    MOV AX,SI
    MOV BX,20
    MUL BX
    LEA DI,prod_name
    ADD DI,AX
    CALL GET_STRING_BACK
    CMP AL,0
    JE AP_BACK
    
    ; Get price with back option
    LEA DX,msg_price
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AL,0
    JE AP_BACK
    PUSH SI
    SHL SI,1     ; word offset for price array
    MOV prod_price[SI],BX
    POP SI
    
    ; Get quantity with back option
    LEA DX,msg_qty
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AL,0
    JE AP_BACK
    PUSH SI
    SHL SI,1     ; word offset for qty array
    MOV prod_qty[SI],BX
    POP SI
    
    LEA DX,msg_added
    MOV AH,9
    INT 21h
    RET

AP_BACK:
    ; Cancel - clear the assigned ID and go back
    MOV BYTE PTR prod_id[SI],0
    DEC next_id
    LEA DX,msg_back
    MOV AH,9
    INT 21h
    RET

AP_FULL:
    LEA DX,msg_full
    MOV AH,9
    INT 21h
    RET
ADD_PROD ENDP

UPD_PROD PROC
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_upd
    MOV AH,9
    INT 21h
    
    LEA DX,msg_id
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AL,0
    JE UP_BACK
    MOV BL,AL
    
    CALL FIND_PROD
    CMP SI,255
    JE UP_NF
    
    ; Show update menu
    LEA DX,upd_menu
    MOV AH,9
    INT 21h
    LEA DX,msg_choice
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    ; AX now contains the number entered
    
    CMP AX,0
    JE UP_BACK
    CMP AX,1
    JE UPD_NAME
    CMP AX,2
    JE UPD_PRICE
    CMP AX,3
    JE UPD_QTY
    CMP AX,4
    JE UPD_ALL
    JMP UP_INVALID

UPD_NAME:
    LEA DX,msg_name
    MOV AH,9
    INT 21h
    MOV AX,SI
    MOV BX,20
    MUL BX
    LEA DI,prod_name
    ADD DI,AX
    ; Clear old name
    MOV CX,20
    PUSH DI
UN_CLR:
    MOV BYTE PTR [DI],'$'
    INC DI
    LOOP UN_CLR
    POP DI
    CALL GET_STRING_BACK
    CMP AL,0
    JE UP_BACK
    JMP UP_SUCCESS

UPD_PRICE:
    LEA DX,msg_price
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AL,0
    JE UP_BACK
    PUSH SI
    SHL SI,1
    MOV prod_price[SI],BX
    POP SI
    JMP UP_SUCCESS

UPD_QTY:
    LEA DX,msg_qty
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AL,0
    JE UP_BACK
    PUSH SI
    SHL SI,1
    MOV prod_qty[SI],BX
    POP SI
    JMP UP_SUCCESS

UPD_ALL:
    ; Update name
    LEA DX,msg_name
    MOV AH,9
    INT 21h
    MOV AX,SI
    MOV BX,20
    MUL BX
    LEA DI,prod_name
    ADD DI,AX
    ; Clear old name
    MOV CX,20
    PUSH DI
UA_CLR:
    MOV BYTE PTR [DI],'$'
    INC DI
    LOOP UA_CLR
    POP DI
    CALL GET_STRING_BACK
    CMP AL,0
    JE UP_BACK
    
    ; Update price
    LEA DX,msg_price
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AL,0
    JE UP_BACK
    PUSH SI
    SHL SI,1
    MOV prod_price[SI],BX
    POP SI
    
    ; Update qty
    LEA DX,msg_qty
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AL,0
    JE UP_BACK
    PUSH SI
    SHL SI,1
    MOV prod_qty[SI],BX
    POP SI
    JMP UP_SUCCESS

UP_SUCCESS:
    LEA DX,msg_updated
    MOV AH,9
    INT 21h
    RET

UP_BACK:
    LEA DX,msg_back
    MOV AH,9
    INT 21h
    RET

UP_NF:
    LEA DX,msg_nf
    MOV AH,9
    INT 21h
    RET

UP_INVALID:
    LEA DX,msg_inv
    MOV AH,9
    INT 21h
    RET
UPD_PROD ENDP

DEL_PROD PROC
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_del
    MOV AH,9
    INT 21h
    
    LEA DX,msg_id
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AL,0
    JE DP_BACK
    MOV BL,AL    ; ID to find
    
    CALL FIND_PROD
    CMP SI,255
    JE DP_NF
    
    MOV BYTE PTR prod_id[SI],0
    
    ; Clear name (SI * 20 offset)
    MOV AX,SI
    MOV BX,20
    MUL BX
    LEA DI,prod_name
    ADD DI,AX
    MOV CX,20
DP_CLR:
    MOV BYTE PTR [DI],'$'
    INC DI
    LOOP DP_CLR
    
    ; Clear price and qty
    MOV BX,SI
    SHL BX,1
    MOV WORD PTR prod_price[BX],0
    MOV WORD PTR prod_qty[BX],0
    
    LEA DX,msg_deleted
    MOV AH,9
    INT 21h
    RET

DP_BACK:
    LEA DX,msg_back
    MOV AH,9
    INT 21h
    RET

DP_NF:
    LEA DX,msg_nf
    MOV AH,9
    INT 21h
    RET
DEL_PROD ENDP

; Print number in AX
PRINT_NUM PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV BX,10
    MOV CX,0
PN_DIVIDE:
    XOR DX,DX
    DIV BX       ; AX = AX/10, DX = remainder
    PUSH DX      ; save digit
    INC CX       ; count digits
    CMP AX,0
    JNE PN_DIVIDE
    
PN_PRINT:
    POP DX
    ADD DL,'0'
    MOV AH,2
    INT 21h
    LOOP PN_PRINT
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUM ENDP

; Calculate string length and return in CX
STR_LEN PROC
    PUSH SI
    PUSH AX
    MOV CX,0
    MOV SI,DI
SL_LOOP:
    MOV AL,[SI]
    CMP AL,'$'
    JE SL_DONE
    INC CX
    INC SI
    CMP CX,20    ; max length check
    JAE SL_DONE
    JMP SL_LOOP
SL_DONE:
    POP AX
    POP SI
    RET
STR_LEN ENDP

; Print spaces for padding
PRINT_SPACES PROC
    ; BL = number of spaces to print
    PUSH AX
    PUSH DX
    MOV DL,' '
    MOV AH,2
PS_LOOP:
    CMP BL,0
    JE PS_DONE
    INT 21h
    DEC BL
    JMP PS_LOOP
PS_DONE:
    POP DX
    POP AX
    RET
PRINT_SPACES ENDP

VIEW_PROD PROC
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_view
    MOV AH,9
    INT 21h
    
    ; Print table header
    LEA DX,table_header
    MOV AH,9
    INT 21h
    LEA DX,table_line
    MOV AH,9
    INT 21h
    
    MOV SI,0
    MOV CX,MAX_PROD
VP_LOOP:
    CMP prod_id[SI],0
    JE VP_NEXT
    
    LEA DX,nl
    MOV AH,9
    INT 21h
    
    ; Print ID (5-char field including space)
    XOR AH,AH
    MOV AL,prod_id[SI]
    CALL PRINT_NUM
    MOV BL,4    ; pad to match "ID   " (4 spaces after)
    CALL PRINT_SPACES
    
    ; Print name with proper padding (21-char field)
    PUSH SI
    PUSH CX
    MOV AX,SI
    MOV BX,20
    MUL BX
    LEA DI,prod_name
    ADD DI,AX
    ; Print the name
    MOV DX,DI
    MOV AH,9
    INT 21h
    ; Calculate padding needed (21 - name_length)
    CALL STR_LEN
    MOV BL,21
    SUB BL,CL
    CALL PRINT_SPACES
    POP CX
    POP SI
    
    ; Print price (9-char field)
    MOV BX,SI
    SHL BX,1
    MOV AX,prod_price[BX]
    CALL PRINT_NUM
    MOV BL,5    ; pad to match "Price    " spacing
    CALL PRINT_SPACES
    
    ; Print qty with proper alignment
    MOV BX,SI
    SHL BX,1
    MOV AX,prod_qty[BX]
    CMP AX,10   ; Check if single digit
    JGE QTY_NO_PAD
    MOV BL,2    ; Add 2 spaces for single digit alignment
    CALL PRINT_SPACES
QTY_NO_PAD:
    CALL PRINT_NUM

VP_NEXT:
    INC SI
    LOOP VP_LOOP
    RET
VIEW_PROD ENDP

; Print a single product row by index SI (assumes table headers already printed)
DISPLAY_PRODUCT_AT_INDEX PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; New line
    LEA DX,nl
    MOV AH,9
    INT 21h

    ; Print ID and spaces
    XOR AH,AH
    MOV AL,prod_id[SI]
    CALL PRINT_NUM
    MOV BL,4
    CALL PRINT_SPACES

    ; Print name padded to 21
    PUSH SI
    MOV AX,SI
    MOV BX,20
    MUL BX
    LEA DI,prod_name
    ADD DI,AX
    MOV DX,DI
    MOV AH,9
    INT 21h
    CALL STR_LEN
    MOV BL,21
    SUB BL,CL
    CALL PRINT_SPACES
    POP SI

    ; Price
    MOV BX,SI
    SHL BX,1
    MOV AX,prod_price[BX]
    CALL PRINT_NUM
    MOV BL,5
    CALL PRINT_SPACES

    ; Qty
    MOV BX,SI
    SHL BX,1
    MOV AX,prod_qty[BX]
    CALL PRINT_NUM

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DISPLAY_PRODUCT_AT_INDEX ENDP

; Swap product records at indices SI and DI (id, name[20], price, qty)
SWAP_PRODUCTS PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    ; Swap IDs
    MOV AL,prod_id[SI]
    MOV BL,prod_id[DI]
    MOV prod_id[SI],BL
    MOV prod_id[DI],AL

    ; Swap names (20 bytes)
    MOV AX,SI
    MOV BX,20
    MUL BX
    LEA SI,prod_name
    ADD SI,AX
    MOV AX,DI
    MOV BX,20
    MUL BX
    LEA DI,prod_name
    ADD DI,AX
    MOV CX,20
SWAP_NAME_LOOP:
    MOV AL,[SI]
    MOV BL,[DI]
    MOV [SI],BL
    MOV [DI],AL
    INC SI
    INC DI
    LOOP SWAP_NAME_LOOP

    ; Restore SI/DI indices to byte indices for price/qty swap
    POP DI
    POP SI
    PUSH SI
    PUSH DI

    ; Swap price without illegal [DX] addressing
    ; Read both prices
    MOV BX,SI
    SHL BX,1
    MOV AX,prod_price[BX] ; AX = price[SI]
    MOV BX,DI
    SHL BX,1
    MOV CX,prod_price[BX] ; CX = price[DI]
    ; Write swapped
    MOV prod_price[BX],AX ; price[DI] = old price[SI]
    MOV BX,SI
    SHL BX,1
    MOV prod_price[BX],CX ; price[SI] = old price[DI]

    ; Swap qty similarly
    MOV BX,SI
    SHL BX,1
    MOV AX,prod_qty[BX]   ; AX = qty[SI]
    MOV BX,DI
    SHL BX,1
    MOV CX,prod_qty[BX]   ; CX = qty[DI]
    MOV prod_qty[BX],AX   ; qty[DI] = old qty[SI]
    MOV BX,SI
    SHL BX,1
    MOV prod_qty[BX],CX   ; qty[SI] = old qty[DI]

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SWAP_PRODUCTS ENDP

; ========================= VIEW_SALES_LOG PROCEDURE =========================
VIEW_SALES_LOG PROC
    LEA DX,msg_sales_log
    MOV AH,9
    INT 21h
    
    ; Display sales log header
    LEA DX,sales_header
    MOV AH,9
    INT 21h
    
    ; Check if any sales logged
    MOV AL,sales_count
    CMP AL,0
    JE NO_SALES_LOG
    
    XOR SI,SI  ; Sales index
VSL_LOOP:
    ; Check if we've displayed all sales
    MOV AL,sales_count
    XOR AH,AH
    CMP SI,AX
    JGE VSL_DONE
    
    ; Display sale entry
    CALL DISPLAY_SALE_ENTRY
    INC SI
    JMP VSL_LOOP
    
NO_SALES_LOG:
    LEA DX,msg_no_sales
    MOV AH,9
    INT 21h
    
VSL_DONE:
    LEA DX,nl
    MOV AH,9
    INT 21h
    RET
VIEW_SALES_LOG ENDP

; Helper procedure to display a single sale entry - SIMPLE VERSION
DISPLAY_SALE_ENTRY PROC
    PUSH SI
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; SI contains the sales index (0, 1, 2, ...)
    ; Use EXACT same logic as storage
    
    ; Display Invoice Number 
    MOV BX,SI               ; BX = sales index
    SHL BX,1                ; BX = sales index * 2 (word index)
    MOV AX,sales_invoice_no[BX]
    CALL PRINT_NUMBER_AX
    MOV DL,' '
    MOV AH,2
    INT 21h
    
    ; Display Product ID
    MOV BX,SI               ; BX = sales index (byte index)
    MOV AL,sales_prod_id[BX]
    CALL PRINT_NUMBER_AL
    MOV DL,' '
    MOV AH,2
    INT 21h
    
    ; Find and display product name
    MOV AL,sales_prod_id[SI] ; Get product ID 
    PUSH SI                  ; Save sales index
    
    ; Search for product name
    XOR SI,SI               ; Start from product 0
FIND_NAME:
    CMP SI,MAX_PROD
    JGE DISPLAY_NAME_NOT_FOUND
    CMP AL,prod_id[SI]      ; Compare with product ID
    JE NAME_FOUND
    INC SI
    JMP FIND_NAME
    
NAME_FOUND:
    ; SI = product index, calculate name address
    MOV AX,SI
    MOV BX,20
    MUL BX                  ; AX = SI * 20
    LEA SI,prod_name
    ADD SI,AX               ; SI points to name
    
    ; Print 20 chars
    MOV CX,20
PRINT_NAME_CHAR:
    MOV AL,[SI]
    CMP AL,0
    JE PAD_NAME
    CMP AL,'$'
    JE PAD_NAME
    MOV DL,AL
    MOV AH,2
    INT 21h
    INC SI
    DEC CX
    JNZ PRINT_NAME_CHAR
    JMP NAME_DONE
    
PAD_NAME:
    CMP CX,0
    JE NAME_DONE
    MOV DL,' '
    MOV AH,2
    INT 21h
    DEC CX
    JMP PAD_NAME
    
DISPLAY_NAME_NOT_FOUND:
    MOV CX,20
PRINT_UNKNOWN:
    MOV DL,'?'
    MOV AH,2
    INT 21h
    DEC CX
    JNZ PRINT_UNKNOWN
    
NAME_DONE:
    POP SI                  ; Restore sales index
    MOV DL,' '
    MOV AH,2
    INT 21h
    
    ; Display quantity
    MOV BX,SI               ; BX = sales index
    SHL BX,1                ; BX = sales index * 2 (word index)
    MOV AX,sales_qty[BX]
    CALL PRINT_NUMBER_AX
    MOV DL,' '
    MOV AH,2
    INT 21h
    
    ; Calculate total: Get unit price and multiply by quantity
    MOV AL,sales_prod_id[SI] ; Get product ID again
    PUSH SI                  ; Save sales index
    
    ; Find product price
    XOR SI,SI
FIND_PRICE:
    CMP SI,MAX_PROD
    JGE PRICE_NOT_FOUND
    CMP AL,prod_id[SI]
    JE PRICE_FOUND
    INC SI
    JMP FIND_PRICE
    
PRICE_FOUND:
    SHL SI,1                ; SI = product index * 2
    MOV AX,prod_price[SI]   ; Get unit price
    JMP CALC_TOTAL
    
PRICE_NOT_FOUND:
    MOV AX,0                ; Default price
    
CALC_TOTAL:
    POP SI                  ; Restore sales index
    ; AX = unit price
    MOV BX,SI
    SHL BX,1                ; BX = sales index * 2
    MOV CX,sales_qty[BX]    ; CX = quantity
    MUL CX                  ; AX = price * quantity
    
    ; Display total
    CALL PRINT_NUMBER_AX
    
    ; New line
    LEA DX,nl
    MOV AH,9
    INT 21h
    
    POP DX
    POP CX
    POP BX
    POP AX
    POP SI
    RET
DISPLAY_SALE_ENTRY ENDP

; ========================= VIEW_SALES_REPORT PROCEDURE =========================
; Computes total revenue (approx via logged line-items), sales count (distinct invoices),
; and best-selling product by quantity sold, then prints a formatted report.
VIEW_SALES_REPORT PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    ; Header
    LEA DX,msg_sales_report
    MOV AH,9
    INT 21h

    ; Clear accumulators
    MOV total_sales_amount,0
    MOV unique_invoice_count,0
    MOV best_selling_id,0
    MOV best_selling_qty,0
    MOV prev_invoice_no,0FFFFh
    ; Clear sold_totals[0..255]
    XOR DI,DI
    MOV CX,256
CLR_SOLD_TOTALS:
    MOV WORD PTR sold_totals[DI],0
    ADD DI,2
    LOOP CLR_SOLD_TOTALS

    ; If no sales, show info and exit
    MOV AL,sales_count
    CMP AL,0
    JNE SR_HAVE_SALES
    LEA DX,msg_no_sales
    MOV AH,9
    INT 21h
    JMP SR_PRINT_ZERO

SR_HAVE_SALES:
    XOR SI,SI          ; SI = sales index
    XOR BX,BX
SR_LOOP:
    ; Check end
    MOV AL,sales_count
    XOR AH,AH
    CMP SI,AX
    JGE SR_DONE

    ; Get invoice number at index SI
    MOV BX,SI
    SHL BX,1
    MOV DX,sales_invoice_no[BX]
    ; Count unique invoices (assuming log grouped by invoice in order; also handle dedup)
    CMP DX,prev_invoice_no
    JE SR_SKIP_INV_INC
    ; First line of a new invoice number
    INC unique_invoice_count
    MOV prev_invoice_no,DX
SR_SKIP_INV_INC:

    ; Aggregate per-product qty
    ; product id in sales_prod_id[SI] (byte)
    MOV BL,sales_prod_id[SI] ; BL=id
    XOR BH,BH
    SHL BX,1                ; word offset into sold_totals
    ; add quantity from sales_qty[SI] using temp index in BX
    PUSH BX                 ; save sold_totals offset
    MOV BX,SI
    SHL BX,1                ; BX = SI*2
    MOV AX,sales_qty[BX]    ; AX = qty
    POP BX                  ; restore sold_totals offset
    ; Add to sold_totals[id]
    ADD sold_totals[BX],AX

    ; Track best selling
    MOV DX,sold_totals[BX]
    CMP DX,best_selling_qty
    JBE SR_BEST_SKIP
    MOV best_selling_qty,DX
    MOV DL,sales_prod_id[SI]
    MOV best_selling_id,DL
SR_BEST_SKIP:

    ; Approx revenue: price(id) * qty
    ; find product index by id (DL)
    MOV DL,sales_prod_id[SI]
    XOR DI,DI
FIND_PRICE_FOR_ID:
    CMP DI,MAX_PROD
    JGE SR_PRICE_NOT_FOUND
    CMP prod_id[DI],DL
    JE SR_PRICE_FOUND
    INC DI
    JMP FIND_PRICE_FOR_ID
SR_PRICE_FOUND:
    SHL DI,1
    MOV CX,prod_price[DI]
    SHR DI,1
    JMP SR_GOT_PRICE
SR_PRICE_NOT_FOUND:
    XOR CX,CX
SR_GOT_PRICE:
    ; qty in AX from above
    PUSH AX
    MOV AX,CX
    POP CX              ; CX=qty, AX=price
    MUL CX              ; AX = price*qty (16-bit wrap)
    ADD total_sales_amount,AX

    ; Next
    INC SI
    JMP SR_LOOP

SR_DONE:
    ; Fallthrough to print
SR_PRINT_ZERO:
    ; Print Total Sales Amount
    LEA DX,label_total_sales
    MOV AH,9
    INT 21h
    MOV AX,total_sales_amount
    CALL PRINT_NUMBER_AX
    LEA DX,msg_taka
    MOV AH,9
    INT 21h

    ; Print Sales Count
    LEA DX,label_sales_count
    MOV AH,9
    INT 21h
    MOV AX,unique_invoice_count
    CALL PRINT_NUMBER_AX

    ; Print Best-Selling Product line
    LEA DX,label_best_selling
    MOV AH,9
    INT 21h
    ; Print product name by id
    MOV AL,best_selling_id
    CALL PRINT_PRODUCT_NAME_BY_ID
    MOV DL,' '
    MOV AH,2
    INT 21h
    MOV DL,'('
    MOV AH,2
    INT 21h
    MOV AX,best_selling_qty
    CALL PRINT_NUMBER_AX
    LEA DX,label_units_sold
    MOV AH,9
    INT 21h
    MOV DL,')'
    MOV AH,2
    INT 21h

    ; Footer line
    LEA DX,table_line
    MOV AH,9
    INT 21h

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
VIEW_SALES_REPORT ENDP

; ========================= SALES_REPORT_MENU =========================
; Presents options: Summary, Last 5, Last 10, Last N, Back
SALES_REPORT_MENU PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    ; Loop until back
SRM_LOOP:
    LEA DX,msg_sales_report_menu
    MOV AH,9
    INT 21h
    LEA DX,msg_choice
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    ; AL=0 back pressed -> return
    CMP AL,0
    JE SRM_DONE
    ; number in AX
    CMP AX,1
    JE SRM_SUMMARY
    CMP AX,2
    JE SRM_LAST5
    CMP AX,3
    JE SRM_LAST10
    CMP AX,4
    JE SRM_LASTN
    CMP AX,5
    JE SRM_DONE
    ; invalid -> prompt again
    LEA DX,msg_inv
    MOV AH,9
    INT 21h
    JMP SRM_LOOP

SRM_SUMMARY:
    CALL VIEW_SALES_REPORT
    JMP SRM_LOOP

SRM_LAST5:
    MOV AX,5
    CALL SHOW_LAST_N_INVOICES
    JMP SRM_LOOP

SRM_LAST10:
    MOV AX,10
    CALL SHOW_LAST_N_INVOICES
    JMP SRM_LOOP

SRM_LASTN:
    LEA DX,msg_lastn_prompt
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AL,0
    JE SRM_LOOP
    ; AX has N
    CALL SHOW_LAST_N_INVOICES
    JMP SRM_LOOP

SRM_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SALES_REPORT_MENU ENDP

; ========================= SHOW_LAST_N_INVOICES =========================
; Input: AX = N (how many recent invoices to show)
; Uses the sales log arrays; scans from the end, counting distinct invoice numbers
; until N distinct invoice numbers have been printed.
SHOW_LAST_N_INVOICES PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    ; If no sales, print and return
    MOV AL,sales_count
    CMP AL,0
    JNE SLN_HAVE_SALES
    LEA DX,msg_no_sales
    MOV AH,9
    INT 21h
    JMP SLN_DONE

SLN_HAVE_SALES:
    ; Print header reused from sales log
    LEA DX,msg_sales_log
    MOV AH,9
    INT 21h
    LEA DX,sales_header
    MOV AH,9
    INT 21h

    ; Clamp N to at least 1
    CMP AX,0
    JG SLN_N_OK
    MOV AX,1
SLN_N_OK:
    ; SI = sales_count - 1 (last entry)
    XOR SI,SI
    MOV BL,sales_count
    DEC BL
    MOV BH,0
    MOV SI,BX
    ; DI = remaining invoices to show (word)
    MOV DI,AX
    ; prev_inv = 0FFFFh so first counts
    MOV DX,0FFFFh

SLN_LOOP:
    ; bounds check: if SI < 0 -> done
    CMP SI,0
    JL SLN_OUT

    ; Load invoice number at SI
    MOV BX,SI
    SHL BX,1
    MOV CX,sales_invoice_no[BX]
    ; If new invoice number boundary
    CMP CX,DX
    JE SLN_PRINT
    ; If we've already shown N distinct invoices, stop before printing another invoice
    CMP DI,0
    JE SLN_OUT
    ; Otherwise, start a new invoice group: remember and decrement remaining
    MOV DX,CX
    DEC DI
SLN_PRINT:
    ; Display the log line at SI
    CALL DISPLAY_SALE_ENTRY
    ; Move to previous entry
    DEC SI
    JMP SLN_LOOP

SLN_OUT:
    ; Footer line
    LEA DX,table_line
    MOV AH,9
    INT 21h

SLN_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SHOW_LAST_N_INVOICES ENDP
; Helper: Print product name by product ID in AL (falls back to Unknown Product)
PRINT_PRODUCT_NAME_BY_ID PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    MOV DL,AL
    XOR SI,SI
PPN_FIND:
    CMP SI,MAX_PROD
    JGE PPN_NOT_FOUND
    CMP prod_id[SI],DL
    JE PPN_FOUND
    INC SI
    JMP PPN_FIND
PPN_FOUND:
    MOV AX,SI
    MOV BX,20
    MUL BX
    LEA DI,prod_name
    ADD DI,AX
    MOV DX,DI
    MOV AH,9
    INT 21h
    JMP PPN_DONE
PPN_NOT_FOUND:
    LEA DX,msg_unknown_prod
    MOV AH,9
    INT 21h
PPN_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_PRODUCT_NAME_BY_ID ENDP

; ========================= VIEW_INVENTORY_REPORT =========================
VIEW_INVENTORY_REPORT PROC
    ; Reuse VIEW_PROD and then show notifications
    LEA DX,msg_inv_report_hdr
    MOV AH,9
    INT 21h
    CALL VIEW_PROD
    ; Notifications
    LEA DX,msg_notif_hdr
    MOV AH,9
    INT 21h
    CALL CHECK_LOW_STOCK
    RET
VIEW_INVENTORY_REPORT ENDP

; ========================= CHECK_LOW_STOCK =========================
; Alerts if any product quantity < 20 and offers reorder marking
CHECK_LOW_STOCK PROC
    PUSH SI
    PUSH BX
    PUSH AX
    PUSH DX
    MOV SI,0
    MOV CX,MAX_PROD
    MOV BL,0            ; flag printed any notification
CLS_LOOP:
    CMP prod_id[SI],0
    JE CLS_NEXT
    ; qty
    MOV BX,SI
    SHL BX,1
    MOV AX,prod_qty[BX]
    CMP AX,20
    JGE CLS_NEXT
    ; Print: !! Low stock of <name>. Restock ASAP!
    LEA DX,msg_low_stock_pref
    MOV AH,9
    INT 21h
    ; name
    PUSH SI
    MOV AX,SI
    MOV BX,20
    MUL BX
    LEA DI,prod_name
    ADD DI,AX
    MOV DX,DI
    MOV AH,9
    INT 21h
    POP SI
    LEA DX,msg_low_stock_suf
    MOV AH,9
    INT 21h
    MOV BL,1
CLS_NEXT:
    INC SI
    LOOP CLS_LOOP
    CMP BL,1
    JE CLS_PROMPT_MARK_REORDER
    LEA DX,msg_no_low_stock
    MOV AH,9
    INT 21h
    JMP CLS_DONE

CLS_PROMPT_MARK_REORDER:
    ; Ask if user wants to mark all low stock products for reorder
    LEA DX,msg_mark_reorder
    MOV AH,9
    INT 21h
    
    ; Get user input
    MOV AH,1
    INT 21h
    CMP AL,'Y'
    JE CLS_MARK_ALL_REORDER
    CMP AL,'y'
    JE CLS_MARK_ALL_REORDER
    JMP CLS_DONE

CLS_MARK_ALL_REORDER:
    CALL MARK_LOW_STOCK_FOR_REORDER
    LEA DX,msg_marked_reorder
    MOV AH,9
    INT 21h
    
CLS_DONE:
    POP DX
    POP AX
    POP BX
    POP SI
    RET
CHECK_LOW_STOCK ENDP

; Helper to print date from packed format
PRINT_DATE PROC
    ; AX contains packed date: (year-2000)*512 + month*32 + day
    PUSH AX
    
    ; Extract day (bits 0-4)
    AND AX,31
    CMP AL,10
    JAE PD_DAY_2DIGIT
    MOV DL,'0'
    MOV AH,2
    INT 21h
PD_DAY_2DIGIT:
    CALL PRINT_NUMBER_AL
    MOV DL,'/'
    MOV AH,2
    INT 21h
    
    ; Extract month (bits 5-8)
    POP AX
    PUSH AX
    SHR AX,5       ; Shift right by 5 to get month in lower bits
    AND AX,15      ; Mask to get 4 bits (month 1-12)
    CMP AL,10
    JAE PD_MONTH_2DIGIT
    MOV DL,'0'
    MOV AH,2
    INT 21h
PD_MONTH_2DIGIT:
    CALL PRINT_NUMBER_AL
    MOV DL,'/'
    MOV AH,2
    INT 21h
    
    ; Extract year (bits 9-15)
    POP AX
    SHR AX,9      ; Shift right by 9 to get year in lower bits
    ADD AX,2000   ; Convert back to full year
    CALL PRINT_NUMBER_AX
    RET
PRINT_DATE ENDP

; Helper to print time from packed format
PRINT_TIME PROC
    ; AX contains packed time: hour*256 + minute
    PUSH AX
    
    ; Extract hour (high byte)
    MOV AL,AH
    XOR AH,AH
    CMP AL,10
    JAE PT_HOUR_2DIGIT
    MOV DL,'0'
    MOV AH,2
    INT 21h
PT_HOUR_2DIGIT:
    CALL PRINT_NUMBER_AL
    MOV DL,':'
    MOV AH,2
    INT 21h
    
    ; Extract minute (low byte)
    POP AX
    AND AX,255
    CMP AL,10
    JAE PT_MINUTE_2DIGIT
    MOV DL,'0'
    MOV AH,2
    INT 21h
PT_MINUTE_2DIGIT:
    CALL PRINT_NUMBER_AL
    RET
PRINT_TIME ENDP

; ========================= SELL_PROD PROCEDURE =========================
SELL_PROD PROC
    ; Initialize invoice
    MOV invoice_count,0
    MOV invoice_total,0
    
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_sell
    MOV AH,9
    INT 21h
    
SELL_LOOP:
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_search
    MOV AH,9
    INT 21h
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_choice
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE SELL_EXIT
    CMP AX,1
    JE ADD_ITEM_MENU
    CMP AX,2
    JE REMOVE_ITEM
    CMP AX,3
    JE SHOW_PRODUCTS
    CMP AX,4
    JE SHOW_INVOICE
    CMP AX,5
    JE CHECKOUT
    CMP AX,6
    JE SELL_EXIT
    JMP SELL_LOOP

ADD_ITEM_MENU:
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_add_item_menu
    MOV AH,9
    INT 21h
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_choice
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE SELL_LOOP
    CMP AX,1
    JE SELL_BY_ID
    CMP AX,2
    JE SELL_BY_NAME
    CMP AX,3
    JE SELL_LOOP
    JMP ADD_ITEM_MENU

SHOW_PRODUCTS:
    CALL VIEW_PROD
    JMP SELL_LOOP

SELL_BY_ID:
    LEA DX,msg_item_id
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE ADD_ITEM_MENU
    MOV BL,AL
    CALL FIND_PROD
    CMP SI,0FFh
    JE ID_NOT_FOUND
    JMP ADD_TO_INVOICE

SELL_BY_NAME:
    LEA DX,msg_item_name
    MOV AH,9
    INT 21h
    LEA DI,temp_name
    CALL GET_STRING_BACK
    MOV AL,[DI]
    CMP AL,0
    JE ADD_ITEM_MENU
    CALL FIND_PROD_NAME
    CMP SI,0FFh
    JE NAME_NOT_FOUND
    JMP ADD_TO_INVOICE

ADD_TO_INVOICE:
    ; Check if invoice is full
    MOV AL,invoice_count
    CMP AL,10
    JGE INVOICE_FULL
    
    ; Get quantity
    LEA DX,msg_sale_qty
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE ADD_ITEM_MENU
    
    ; Check if enough stock
    MOV BX,SI
    SHL BX,1
    CMP AX,prod_qty[BX]
    JG INSUFFICIENT_STOCK
    
    ; Add to invoice
    MOV BL,invoice_count
    XOR BH,BH
    PUSH AX  ; Save quantity value
    ; Store product ID (not index!) 
    MOV AL,prod_id[SI]  ; Get actual product ID from product index
    MOV invoice_prod_id[BX],AL  ; Store product ID
    SHL BX,1
    POP AX   ; Restore quantity value
    MOV invoice_qty[BX],AX
    
    ; Calculate price
    PUSH AX
    MOV BX,SI
    SHL BX,1
    MOV AX,prod_price[BX]
    POP BX
    MUL BX
    PUSH AX  ; Save calculated price
    MOV BL,invoice_count
    XOR BH,BH
    SHL BX,1
    POP AX   ; Restore calculated price
    MOV invoice_price[BX],AX
    
    ; Add to total
    ADD invoice_total,AX
    
    ; Increment count
    INC invoice_count
    
    LEA DX,msg_item_added
    MOV AH,9
    INT 21h
    JMP ADD_ITEM_MENU

SHOW_INVOICE:
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_invoice_header
    MOV AH,9
    INT 21h
    
    MOV AL,invoice_count
    CMP AL,0
    JE EMPTY_INVOICE
    
    ; Print table top border
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_invoice_line
    MOV AH,9
    INT 21h
    LEA DX,msg_invoice_sep
    MOV AH,9
    INT 21h
    
    XOR SI,SI
    MOV CL,invoice_count
SHOW_INV_LOOP:
    ; Print item number
    LEA DX,nl
    MOV AH,9
    INT 21h
    MOV AX,SI   ; Move SI to AX first
    INC AL      ; Increment the low byte
    XOR AH,AH   ; Clear high byte
    CMP AX,10
    JAE NO_ITEM_PAD
    MOV DL,' '  ; Add space for alignment
    MOV AH,2
    INT 21h
NO_ITEM_PAD:
    MOV AX,SI   ; Restore SI to AX
    INC AL      ; Re-increment the low byte
    XOR AH,AH   ; Clear high byte
    CALL PRINT_NUM
    MOV DL,' '  ; Space after item number
    MOV AH,2
    INT 21h
    MOV DL,' '  ; Extra space for column width
    MOV AH,2
    INT 21h
    
    ; Get product info - FIXED to find by product ID
    MOV AL,invoice_prod_id[SI]  ; Get product ID
    
    ; Print name (20 chars fixed width)
    PUSH SI
    PUSH CX
    
    ; Find product index from product ID using DI instead of SI
    MOV DL,AL               ; DL = product ID to find (use DL instead of CL)
    XOR DI,DI               ; Start searching from index 0
FIND_INV_PROD_INDEX:
    CMP DI,MAX_PROD
    JGE INV_PROD_NOT_FOUND
    CMP prod_id[DI],DL      ; Compare with product ID (use DL)
    JE INV_PROD_INDEX_FOUND
    INC DI
    JMP FIND_INV_PROD_INDEX
    
INV_PROD_INDEX_FOUND:
    ; DI now contains the correct product index
    MOV AX,DI
    MOV BX,20
    MUL BX
    LEA DI,prod_name
    ADD DI,AX
    MOV DX,DI
    MOV AH,9
    INT 21h
    JMP INV_NAME_CALC_PAD
    
INV_PROD_NOT_FOUND:
    ; Print "Unknown Product     " (20 chars)
    LEA DX,msg_unknown_prod
    MOV AH,9
    INT 21h
    
INV_NAME_CALC_PAD:
    ; Calculate padding to make name column fixed width (20 chars)
    CALL STR_LEN  ; Returns length in CX
    MOV BL,20
    SUB BL,CL
    CALL PRINT_SPACES
    POP CX
    POP SI
    
    ; Print quantity with right alignment (5 spaces)
    MOV BX,SI
    SHL BX,1
    MOV AX,invoice_qty[BX]
    
    ; Add padding based on number size (5 spaces total)
    CMP AX,10
    JAE QTY_CHECK_HUNDRED
    MOV BL,4     ; 1 digit - add 4 spaces
    JMP QTY_PAD_DONE
QTY_CHECK_HUNDRED:
    CMP AX,100
    JAE QTY_CHECK_THOUSAND
    MOV BL,3     ; 2 digits - add 3 spaces
    JMP QTY_PAD_DONE
QTY_CHECK_THOUSAND:
    CMP AX,1000
    JAE QTY_BIG_NUM
    MOV BL,2     ; 3 digits - add 2 spaces
    JMP QTY_PAD_DONE
QTY_BIG_NUM:
    MOV BL,1     ; 4+ digits - add 1 space
QTY_PAD_DONE:
    CALL PRINT_SPACES
    
    MOV BX,SI
    SHL BX,1
    MOV AX,invoice_qty[BX]
    CALL PRINT_NUM
    
    ; Print price (unit price) with right alignment (7 spaces)
    MOV BL,2     ; Add 2 spaces between qty and price
    CALL PRINT_SPACES
    
    ; Get unit price from product array - FIXED to find by product ID
    MOV AL,invoice_prod_id[SI]  ; Get product ID
    PUSH SI      ; Save current SI
    
    ; Find product index from product ID using DI instead of SI
    MOV DL,AL               ; DL = product ID to find (use DL instead of CL)
    XOR DI,DI               ; Start searching from index 0
FIND_INV_PRICE_INDEX:
    CMP DI,MAX_PROD
    JGE INV_PRICE_NOT_FOUND
    CMP prod_id[DI],DL      ; Compare with product ID (use DL)
    JE INV_PRICE_INDEX_FOUND
    INC DI
    JMP FIND_INV_PRICE_INDEX
    
INV_PRICE_INDEX_FOUND:
    ; DI now contains the correct product index
    SHL DI,1     ; DI*2 for word array
    MOV AX,prod_price[DI]  ; Get unit price
    JMP INV_PRICE_DONE
    
INV_PRICE_NOT_FOUND:
    MOV AX,0     ; Default price if not found
    
INV_PRICE_DONE:
    POP SI       ; Restore invoice item index
    
    ; Add padding based on unit price size (7 spaces total)
    PUSH AX      ; Save unit price
    CMP AX,10
    JAE UNIT_PRICE_CHECK_HUNDRED
    MOV BL,6     ; 1 digit - add 6 spaces
    JMP UNIT_PRICE_PAD_DONE
UNIT_PRICE_CHECK_HUNDRED:
    CMP AX,100
    JAE UNIT_PRICE_CHECK_THOUSAND
    MOV BL,5     ; 2 digits - add 5 spaces
    JMP UNIT_PRICE_PAD_DONE
UNIT_PRICE_CHECK_THOUSAND:
    CMP AX,1000
    JAE UNIT_PRICE_CHECK_10K
    MOV BL,4     ; 3 digits - add 4 spaces
    JMP UNIT_PRICE_PAD_DONE
UNIT_PRICE_CHECK_10K:
    CMP AX,10000
    JAE UNIT_PRICE_BIG_NUM
    MOV BL,3     ; 4 digits - add 3 spaces
    JMP UNIT_PRICE_PAD_DONE
UNIT_PRICE_BIG_NUM:
    MOV BL,2     ; 5+ digits - add 2 spaces
UNIT_PRICE_PAD_DONE:
    CALL PRINT_SPACES
    POP AX       ; Restore unit price
    CALL PRINT_NUM
    
    ; Print total (unit price × quantity) with right alignment
    MOV BL,2     ; Add 2 spaces between price and total
    CALL PRINT_SPACES
    
    ; Calculate total = unit price × quantity
    MOV BX,SI
    SHL BX,1
    MOV DX,invoice_qty[BX]  ; Get quantity
    MUL DX                  ; AX = unit price × quantity
    
    ; Add padding based on total size (7 spaces total)
    PUSH AX      ; Save total
    CMP AX,10
    JAE TOTAL_ITEM_CHECK_HUNDRED
    MOV BL,6     ; 1 digit - add 6 spaces
    JMP TOTAL_ITEM_PAD_DONE
TOTAL_ITEM_CHECK_HUNDRED:
    CMP AX,100
    JAE TOTAL_ITEM_CHECK_THOUSAND
    MOV BL,5     ; 2 digits - add 5 spaces
    JMP TOTAL_ITEM_PAD_DONE
TOTAL_ITEM_CHECK_THOUSAND:
    CMP AX,1000
    JAE TOTAL_ITEM_CHECK_10K
    MOV BL,4     ; 3 digits - add 4 spaces
    JMP TOTAL_ITEM_PAD_DONE
TOTAL_ITEM_CHECK_10K:
    CMP AX,10000
    JAE TOTAL_ITEM_BIG_NUM
    MOV BL,3     ; 4 digits - add 3 spaces
    JMP TOTAL_ITEM_PAD_DONE
TOTAL_ITEM_BIG_NUM:
    MOV BL,2     ; 5+ digits - add 2 spaces
TOTAL_ITEM_PAD_DONE:
    CALL PRINT_SPACES
    POP AX       ; Restore total
    CALL PRINT_NUM
    
    INC SI
    LOOP SHOW_INV_LOOP
    
    ; Print bottom border
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_invoice_sep
    MOV AH,9
    INT 21h
    
    ; Print grand total with proper alignment
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_grand_total
    MOV AH,9
    INT 21h
    
    ; Add padding based on total size
    MOV AX,invoice_total
    PUSH AX
    CMP AX,10
    JAE TOTAL_CHECK_HUNDRED
    MOV BL,6     ; 1 digit - add 6 spaces
    JMP TOTAL_PAD_DONE
TOTAL_CHECK_HUNDRED:
    CMP AX,100
    JAE TOTAL_CHECK_THOUSAND
    MOV BL,5     ; 2 digits - add 5 spaces
    JMP TOTAL_PAD_DONE
TOTAL_CHECK_THOUSAND:
    CMP AX,1000
    JAE TOTAL_CHECK_10K
    MOV BL,4     ; 3 digits - add 4 spaces
    JMP TOTAL_PAD_DONE
TOTAL_CHECK_10K:
    CMP AX,10000
    JAE TOTAL_BIG_NUM
    MOV BL,3     ; 4 digits - add 3 spaces
    JMP TOTAL_PAD_DONE
TOTAL_BIG_NUM:
    MOV BL,2     ; 5+ digits - add 2 spaces
TOTAL_PAD_DONE:
    CALL PRINT_SPACES
    POP AX
    CALL PRINT_NUM
    LEA DX,msg_taka
    MOV AH,9
    INT 21h
    
    ; Add bottom closing border
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_invoice_sep
    MOV AH,9
    INT 21h
    JMP SELL_LOOP

CHECKOUT:
    MOV AL,invoice_count
    CMP AL,0
    JE EMPTY_INVOICE
    
    ; Show complete invoice before payment
    CALL SHOW_INVOICE_DISPLAY
    
    ; Ask for payment
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_payment
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE SELL_LOOP
    
    CMP AX,invoice_total
    JL INSUFFICIENT_PAYMENT
    
    ; Calculate change
    SUB AX,invoice_total
    MOV change_amount,AX
    
    ; Process sale
    CALL PROCESS_SALE
    
    LEA DX,msg_change
    MOV AH,9
    INT 21h
    MOV AX,change_amount
    CALL PRINT_NUM
    LEA DX,msg_taka
    MOV AH,9
    INT 21h
    
    LEA DX,msg_sale_complete
    MOV AH,9
    INT 21h
    
    ; Reset invoice
    MOV invoice_count,0
    MOV invoice_total,0
    JMP SELL_LOOP

PROCESS_SALE:
    ; Update inventory and log sales
    XOR SI,SI
    MOV CL,invoice_count
    
    ; Get current invoice number for this sale
    MOV DX,next_invoice_no  ; Store invoice number in DX for this invoice
    INC next_invoice_no     ; Increment for next invoice
    
PROCESS_LOOP:
    ; Get product index
    MOV BL,invoice_prod_id[SI]
    XOR BH,BH
    
    ; Reduce quantity
    PUSH SI
    MOV BX,SI
    SHL BX,1
    PUSH DX                 ; Save invoice number
    MOV DX,invoice_qty[BX]  ; Get quantity from invoice
    MOV AL,invoice_prod_id[SI]  ; Get product ID
    XOR AH,AH
    PUSH AX                 ; Save product ID
    
    ; Find product index from product ID - FIXED to not corrupt loop counters
    PUSH CX                 ; Save loop counter
    MOV BL,AL               ; BL = product ID to find (use BL instead of CX)
    XOR DI,DI               ; Start searching from index 0 (use DI instead of SI)
FIND_PROD_INDEX:
    CMP DI,MAX_PROD
    JGE PROD_NOT_FOUND      ; Product ID not found
    CMP prod_id[DI],BL      ; Compare with product ID (use BL and DI)
    JE PROD_INDEX_FOUND
    INC DI
    JMP FIND_PROD_INDEX
    
PROD_INDEX_FOUND:
    ; DI now contains the correct product index
    SHL DI,1                ; DI*2 for word array
    SUB prod_qty[DI],DX     ; Reduce product quantity
    SHR DI,1                ; Restore DI to byte index
    JMP REDUCTION_DONE
    
PROD_NOT_FOUND:
    ; Should not happen, but handle gracefully
    
REDUCTION_DONE:
    POP CX                  ; Restore loop counter
    POP AX                  ; Restore product ID
    POP DX                  ; Restore invoice number
    POP SI                  ; Restore invoice item index
    
    ; Log sale entry - SIMPLE AND CORRECT
    PUSH SI                 ; Save invoice item index
    PUSH DX                 ; Save invoice number  
    PUSH AX                 ; Save product ID
    
    ; Check if sales log has space
    CMP sales_count,MAX_SALES
    JGE SKIP_LOGGING        ; Skip if full
    
    ; Get current sales_count as our index
    XOR BX,BX
    MOV BL,sales_count      ; BL = current sales index (0,1,2...)
    
    ; Store invoice number (word array)
    PUSH BX                 ; Save sales index
    SHL BX,1                ; BX = sales index * 2 (for word array)
    MOV sales_invoice_no[BX],DX  ; Store invoice number (DX has it)
    POP BX                  ; Restore sales index
    
    ; Store product ID (byte array)  
    MOV sales_prod_id[BX],AL ; Store product ID (AL has it)
    
    ; Get quantity from invoice_qty array for current invoice item SI
    PUSH BX                 ; Save sales index
    MOV BX,SI               ; BX = invoice item index
    SHL BX,1                ; BX = invoice item index * 2 (for word array)
    MOV AX,invoice_qty[BX]  ; Get quantity from invoice
    POP BX                  ; Restore sales index
    
    ; Store quantity (word array)
    PUSH BX                 ; Save sales index 
    SHL BX,1                ; BX = sales index * 2 (for word array)  
    MOV sales_qty[BX],AX    ; Store quantity
    POP BX                  ; Restore sales index
    
    ; Increment sales count
    INC sales_count
    
SKIP_LOGGING:
    POP AX                  ; Restore product ID
    POP DX                  ; Restore invoice number
    POP SI                  ; Restore invoice item index

PROCESS_NEXT:
    INC SI
    LOOP PROCESS_LOOP
    RET

FIND_PROD_NAME:
    XOR SI,SI
    MOV CX,20
FPN_LOOP:
    MOV AL,prod_id[SI]
    CMP AL,0
    JE FPN_NEXT
    
    PUSH SI
    PUSH CX
    MOV AX,SI
    MOV BX,20
    MUL BX
    LEA DI,prod_name
    ADD DI,AX
    LEA SI,temp_name
    CALL COMPARE_STRING
    POP CX
    POP SI
    CMP AL,1
    JE FPN_FOUND
    
FPN_NEXT:
    INC SI
    LOOP FPN_LOOP
    MOV SI,0FFh
    RET
FPN_FOUND:
    RET

COMPARE_STRING:
    ; Compare strings at SI and DI, return AL=1 if equal
CMPSTR_LOOP:
    MOV AL,[SI]
    MOV BL,[DI]
    CMP AL,BL
    JNE CMPSTR_NOT_EQUAL
    CMP AL,0
    JE CMPSTR_EQUAL
    INC SI
    INC DI
    JMP CMPSTR_LOOP
CMPSTR_EQUAL:
    MOV AL,1
    RET
CMPSTR_NOT_EQUAL:
    MOV AL,0
    RET

ID_NOT_FOUND:
    LEA DX,msg_nf
    MOV AH,9
    INT 21h
    JMP ADD_ITEM_MENU

NAME_NOT_FOUND:
    LEA DX,msg_nf
    MOV AH,9
    INT 21h
    JMP ADD_ITEM_MENU

INSUFFICIENT_STOCK:
    LEA DX,msg_not_enough
    MOV AH,9
    INT 21h
    JMP ADD_ITEM_MENU

INVOICE_FULL:
    LEA DX,msg_full
    MOV AH,9
    INT 21h
    JMP ADD_ITEM_MENU

EMPTY_INVOICE:
    LEA DX,msg_invoice_empty
    MOV AH,9
    INT 21h
    JMP SELL_LOOP

INSUFFICIENT_PAYMENT:
    LEA DX,msg_insufficient
    MOV AH,9
    INT 21h
    JMP SELL_LOOP

REMOVE_ITEM:
    CALL REMOVE_ITEM_PROC
    JMP SELL_LOOP

SELL_EXIT:
    RET
SELL_PROD ENDP

; ========================= SHOW INVOICE DISPLAY PROCEDURE =========================
SHOW_INVOICE_DISPLAY PROC
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_invoice_header
    MOV AH,9
    INT 21h
    
    ; Print table headers and borders (same as SHOW_INVOICE)
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_invoice_line
    MOV AH,9
    INT 21h
    LEA DX,msg_invoice_sep
    MOV AH,9
    INT 21h
    
    XOR SI,SI
    MOV CL,invoice_count
SHOW_DISP_LOOP:
    ; Print each item (same logic as SHOW_INVOICE)
    LEA DX,nl
    MOV AH,9
    INT 21h
    MOV AX,SI
    INC AL
    XOR AH,AH
    CMP AX,10
    JAE NO_DISP_ITEM_PAD
    MOV DL,' '
    MOV AH,2
    INT 21h
NO_DISP_ITEM_PAD:
    MOV AX,SI
    INC AL
    XOR AH,AH
    CALL PRINT_NUM
    MOV DL,' '
    MOV AH,2
    INT 21h
    MOV DL,' '
    MOV AH,2
    INT 21h
    
    ; Get and print product name - FIXED to find by product ID
    MOV AL,invoice_prod_id[SI]  ; Get product ID
    PUSH SI
    PUSH CX
    
    ; Find product index from product ID using DI instead of SI
    MOV DL,AL               ; DL = product ID to find (use DL instead of CL)
    XOR DI,DI               ; Start searching from index 0
FIND_DISP_PROD_INDEX:
    CMP DI,MAX_PROD
    JGE DISP_PROD_NOT_FOUND
    CMP prod_id[DI],DL      ; Compare with product ID (use DL)
    JE DISP_PROD_INDEX_FOUND
    INC DI
    JMP FIND_DISP_PROD_INDEX
    
DISP_PROD_INDEX_FOUND:
    ; DI now contains the correct product index
    MOV AX,DI
    MOV BX,20
    MUL BX
    LEA DI,prod_name
    ADD DI,AX
    MOV DX,DI
    MOV AH,9
    INT 21h
    CALL STR_LEN
    MOV BL,20
    SUB BL,CL
    CALL PRINT_SPACES
    JMP DISP_NAME_DONE
    
DISP_PROD_NOT_FOUND:
    ; Print "Unknown Product    " (20 chars)
    LEA DX,msg_unknown_prod
    MOV AH,9
    INT 21h
    
DISP_NAME_DONE:
    POP CX
    POP SI
    
    ; Print quantity, unit price, and total (abbreviated)
    MOV BX,SI
    SHL BX,1
    MOV AX,invoice_qty[BX]
    CALL PRINT_NUM
    MOV BL,5
    CALL PRINT_SPACES
    
    ; Unit price - FIXED to find by product ID
    MOV AL,invoice_prod_id[SI]  ; Get product ID
    PUSH SI
    
    ; Find product index from product ID using DI instead of SI
    MOV DL,AL               ; DL = product ID to find (use DL instead of CL)
    XOR DI,DI               ; Start searching from index 0
FIND_DISP_PRICE_INDEX:
    CMP DI,MAX_PROD
    JGE DISP_PRICE_NOT_FOUND
    CMP prod_id[DI],DL      ; Compare with product ID (use DL)
    JE DISP_PRICE_INDEX_FOUND
    INC DI
    JMP FIND_DISP_PRICE_INDEX
    
DISP_PRICE_INDEX_FOUND:
    ; DI now contains the correct product index
    SHL DI,1
    MOV AX,prod_price[DI]
    JMP DISP_PRICE_DONE
    
DISP_PRICE_NOT_FOUND:
    MOV AX,0                ; Default price if not found
    
DISP_PRICE_DONE:
    POP SI
    CALL PRINT_NUM
    MOV BL,7
    CALL PRINT_SPACES
    
    ; Total
    MOV BX,SI
    SHL BX,1
    MOV AX,invoice_price[BX]
    CALL PRINT_NUM
    
    INC SI
    LOOP SHOW_DISP_LOOP
    
    ; Print total
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_invoice_sep
    MOV AH,9
    INT 21h
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_grand_total
    MOV AH,9
    INT 21h
    MOV AX,invoice_total
    CALL PRINT_NUM
    LEA DX,msg_taka
    MOV AH,9
    INT 21h
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_invoice_sep
    MOV AH,9
    INT 21h
    RET
SHOW_INVOICE_DISPLAY ENDP

; ========================= REMOVE ITEM PROCEDURE =========================
REMOVE_ITEM_PROC PROC
    MOV AL,invoice_count
    CMP AL,0
    JE RM_EMPTY_INVOICE
    
    ; Show current invoice
    CALL SHOW_INVOICE_DISPLAY
    
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_choice
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE RM_EXIT
    
    ; Validate item number (1-based input)
    CMP AL,invoice_count
    JA RM_INVALID_ITEM
    CMP AL,1
    JB RM_INVALID_ITEM
    
    ; Convert to 0-based index
    DEC AL
    XOR AH,AH
    MOV SI,AX  ; SI = item index to remove (0-based)
    
    ; Subtract item total from invoice total
    MOV BX,SI
    SHL BX,1
    MOV AX,invoice_price[BX]
    SUB invoice_total,AX
    
    ; Calculate number of items to shift
    XOR AH,AH
    MOV AL,invoice_count  ; AX = invoice_count
    SUB AX,SI             ; AX = items after the one being removed
    DEC AX                ; AX = number of items to shift
    CMP AX,0
    JE RM_REMOVE_LAST_ITEM  ; No items to shift
    
    MOV CL,AL  ; CL = number of items to shift (low byte)
    
RM_SHIFT_ITEMS:
    ; Calculate source and destination indices
    MOV BX,SI
    INC BX     ; BX = source index (item to move)
    
    ; Shift product ID
    MOV AL,invoice_prod_id[BX]
    MOV invoice_prod_id[SI],AL
    
    ; Shift quantity (word array)
    PUSH SI
    PUSH BX
    SHL SI,1   ; SI*2 for destination word offset
    SHL BX,1   ; BX*2 for source word offset
    MOV AX,invoice_qty[BX]
    MOV invoice_qty[SI],AX
    
    ; Shift price (word array)
    MOV AX,invoice_price[BX]
    MOV invoice_price[SI],AX
    POP BX
    POP SI
    
    INC SI     ; Move to next position
    LOOP RM_SHIFT_ITEMS
    
RM_REMOVE_LAST_ITEM:
    DEC invoice_count
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_deleted
    MOV AH,9
    INT 21h
    JMP RM_EXIT

RM_INVALID_ITEM:
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_inv
    MOV AH,9
    INT 21h
    JMP RM_EXIT

RM_EMPTY_INVOICE:
    LEA DX,msg_invoice_empty
    MOV AH,9
    INT 21h

RM_EXIT:
    RET
REMOVE_ITEM_PROC ENDP

; ========================= UTILITY PROCEDURES =========================
; Print number in AL (0-255)
PRINT_NUMBER_AL PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    XOR AH,AH  ; AX now contains the number to print
    XOR CX,CX  ; digit counter
    MOV BX,10  ; divisor
    
    ; Handle zero case
    CMP AX,0
    JNE PN_AL_LOOP
    MOV DL,'0'
    MOV AH,2
    INT 21h
    JMP PN_AL_DONE
    
PN_AL_LOOP:
    CMP AX,0
    JE PN_AL_PRINT
    XOR DX,DX
    DIV BX      ; AX = quotient, DX = remainder
    PUSH DX     ; save digit
    INC CX      ; increment digit count
    JMP PN_AL_LOOP
    
PN_AL_PRINT:
    CMP CX,0
    JE PN_AL_DONE
    POP DX      ; get digit
    ADD DL,'0'  ; convert to ASCII
    MOV AH,2
    INT 21h
    DEC CX
    JMP PN_AL_PRINT
    
PN_AL_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUMBER_AL ENDP

; Print number in AX (0-65535)
PRINT_NUMBER_AX PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    XOR CX,CX  ; digit counter
    MOV BX,10  ; divisor
    
    ; Handle zero case
    CMP AX,0
    JNE PN_AX_LOOP
    MOV DL,'0'
    MOV AH,2
    INT 21h
    JMP PN_AX_DONE
    
PN_AX_LOOP:
    CMP AX,0
    JE PN_AX_PRINT
    XOR DX,DX
    DIV BX      ; AX = quotient, DX = remainder
    PUSH DX     ; save digit
    INC CX      ; increment digit count
    JMP PN_AX_LOOP
    
PN_AX_PRINT:
    CMP CX,0
    JE PN_AX_DONE
    POP DX      ; get digit
    ADD DL,'0'  ; convert to ASCII
    MOV AH,2
    INT 21h
    DEC CX
    JMP PN_AX_PRINT
    
PN_AX_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUMBER_AX ENDP

; ========================= INITIALIZATION PROCEDURE =========================
INIT_PRODUCTS PROC
    ; Initialize system with 5 sample products for testing
    
    ; Product 1: Rice (ID=1, stored at index 0)
    MOV prod_id[0], 1
    MOV SI, 0
    MOV AX, SI
    MOV BX, 20
    MUL BX
    LEA DI, prod_name
    ADD DI, AX
    
    ; Copy "Rice" + null terminator
    MOV BYTE PTR [DI], 'R'
    MOV BYTE PTR [DI+1], 'i'
    MOV BYTE PTR [DI+2], 'c'
    MOV BYTE PTR [DI+3], 'e'
    MOV BYTE PTR [DI+4], 0
    
    ; Set price and quantity (using word array indexing)
    MOV BX, 0           ; Index 0
    SHL BX, 1           ; BX = 0 * 2 = 0 for word arrays
    MOV prod_price[BX], 50    ; 50 Taka per unit
    MOV prod_qty[BX], 100     ; 100 units in stock
    
    ; Product 2: Oil (ID=2, stored at index 1)
    MOV prod_id[1], 2
    MOV SI, 1
    MOV AX, SI
    MOV BX, 20
    MUL BX
    LEA DI, prod_name
    ADD DI, AX
    
    ; Copy "Oil" + null terminator  
    MOV BYTE PTR [DI], 'O'
    MOV BYTE PTR [DI+1], 'i'
    MOV BYTE PTR [DI+2], 'l'
    MOV BYTE PTR [DI+3], 0
    
    ; Set price and quantity (using word array indexing)
    MOV BX, 1           ; Index 1
    SHL BX, 1           ; BX = 1 * 2 = 2 for word arrays
    MOV prod_price[BX], 200   ; 200 Taka per unit
    MOV prod_qty[BX], 50      ; 50 units in stock
    
    ; Product 3: Sugar (ID=3, stored at index 2)
    MOV prod_id[2], 3
    MOV SI, 2
    MOV AX, SI
    MOV BX, 20
    MUL BX
    LEA DI, prod_name
    ADD DI, AX
    
    ; Copy "Sugar" + null terminator
    MOV BYTE PTR [DI], 'S'
    MOV BYTE PTR [DI+1], 'u'
    MOV BYTE PTR [DI+2], 'g'
    MOV BYTE PTR [DI+3], 'a'
    MOV BYTE PTR [DI+4], 'r'
    MOV BYTE PTR [DI+5], 0
    
    ; Set price and quantity (using word array indexing)
    MOV BX, 2           ; Index 2
    SHL BX, 1           ; BX = 2 * 2 = 4 for word arrays
    MOV prod_price[BX], 80    ; 80 Taka per unit
    MOV prod_qty[BX], 75      ; 75 units in stock
    
    ; Product 4: Tea (ID=4, stored at index 3)
    MOV prod_id[3], 4
    MOV SI, 3
    MOV AX, SI
    MOV BX, 20
    MUL BX
    LEA DI, prod_name
    ADD DI, AX
    
    ; Copy "Tea" + null terminator
    MOV BYTE PTR [DI], 'T'
    MOV BYTE PTR [DI+1], 'e'
    MOV BYTE PTR [DI+2], 'a'
    MOV BYTE PTR [DI+3], 0
    
    ; Set price and quantity (using word array indexing)
    MOV BX, 3           ; Index 3
    SHL BX, 1           ; BX = 3 * 2 = 6 for word arrays
    MOV prod_price[BX], 150   ; 150 Taka per unit
    MOV prod_qty[BX], 60      ; 60 units in stock
    
    ; Product 5: Bread (ID=5, stored at index 4)
    MOV prod_id[4], 5
    MOV SI, 4
    MOV AX, SI
    MOV BX, 20
    MUL BX
    LEA DI, prod_name
    ADD DI, AX
    
    ; Copy "Bread" + null terminator
    MOV BYTE PTR [DI], 'B'
    MOV BYTE PTR [DI+1], 'r'
    MOV BYTE PTR [DI+2], 'e'
    MOV BYTE PTR [DI+3], 'a'
    MOV BYTE PTR [DI+4], 'd'
    MOV BYTE PTR [DI+5], 0
    
    ; Set price and quantity (using word array indexing)
    MOV BX, 4           ; Index 4
    SHL BX, 1           ; BX = 4 * 2 = 8 for word arrays
    MOV prod_price[BX], 25    ; 25 Taka per unit
    MOV prod_qty[BX], 120     ; 120 units in stock
    
    RET
INIT_PRODUCTS ENDP

; ========================= WELCOME SCREEN =========================
SHOW_WELCOME PROC
    ; Clear screen with multiple newlines
    MOV CX,3
CLEAR_LOOP:
    LEA DX,nl
    MOV AH,9
    INT 21h
    LOOP CLEAR_LOOP
    
    ; Display welcome banner
    LEA DX,welcome_banner
    MOV AH,9
    INT 21h
    
    ; Wait for user to press Enter
    LEA DX,press_enter
    MOV AH,9
    INT 21h
    
    ; Wait for Enter key
    MOV AH,1
    INT 21h
    
    RET
SHOW_WELCOME ENDP

; ========================= ADMIN: SEARCH PRODUCTS =========================
SEARCH_PROD PROC
    LEA DX,msg_search_hdr
    MOV AH,9
    INT 21h
SP_MENU:
    LEA DX,msg_search_menu
    MOV AH,9
    INT 21h
    LEA DX,msg_choice
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE SP_EXIT
    CMP AX,1
    JE SP_BY_ID
    CMP AX,2
    JE SP_BY_NAME
    CMP AX,3
    JE SP_BY_PRICE
    CMP AX,4
    JE SP_BY_QTY
    CMP AX,5
    JE SP_EXIT
    JMP SP_MENU

SP_BY_ID:
    LEA DX,msg_id
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE SP_MENU
    MOV BL,AL
    CALL FIND_PROD
    CMP SI,255
    JE SP_NOT_FOUND
    ; header
    LEA DX,table_header
    MOV AH,9
    INT 21h
    LEA DX,table_line
    MOV AH,9
    INT 21h
    CALL DISPLAY_PRODUCT_AT_INDEX
    JMP SP_MENU

SP_BY_NAME:
    LEA DX,msg_name
    MOV AH,9
    INT 21h
    LEA DI,temp_name
    CALL GET_STRING_BACK
    CMP AL,0
    JE SP_MENU
    ; header
    LEA DX,table_header
    MOV AH,9
    INT 21h
    LEA DX,table_line
    MOV AH,9
    INT 21h
    ; iterate all and compare temp_name to prod_name (prefix/case-sensitive simple)
    XOR SI,SI
    MOV CX,MAX_PROD
SP_NAME_LOOP:
    CMP prod_id[SI],0
    JE SP_NAME_NEXT
    PUSH SI
    MOV AX,SI
    MOV BX,20
    MUL BX
    LEA DI,prod_name
    ADD DI,AX
    LEA SI,temp_name
    CALL COMPARE_STRING
    POP SI
    CMP AL,1
    JNE SP_NAME_NEXT
    CALL DISPLAY_PRODUCT_AT_INDEX
SP_NAME_NEXT:
    INC SI
    LOOP SP_NAME_LOOP
    JMP SP_MENU

SP_BY_PRICE:
    LEA DX,msg_price
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE SP_MENU
    MOV tmp_min,AX
    LEA DX,msg_price
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE SP_MENU
    MOV tmp_max,AX
    ; header
    LEA DX,table_header
    MOV AH,9
    INT 21h
    LEA DX,table_line
    MOV AH,9
    INT 21h
    XOR SI,SI
    MOV CX,MAX_PROD
SP_PRICE_LOOP:
    CMP prod_id[SI],0
    JE SP_PRICE_NEXT
    PUSH SI
    MOV BX,SI
    SHL BX,1
    MOV AX,prod_price[BX]
    ; normalize min/max using tmp vars
    PUSH AX
    MOV DX,tmp_min
    MOV BX,tmp_max
    CMP DX,BX
    JBE SP_PM_OK
    XCHG DX,BX
SP_PM_OK:
    POP AX
    CMP AX,DX
    JB SP_P_NO
    CMP AX,BX
    JA SP_P_NO
    POP SI
    CALL DISPLAY_PRODUCT_AT_INDEX
    JMP SP_PRICE_CONT
SP_P_NO:
    POP SI
SP_PRICE_CONT:
SP_PRICE_NEXT:
    INC SI
    LOOP SP_PRICE_LOOP
    JMP SP_MENU

SP_BY_QTY:
    LEA DX,msg_qty
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE SP_MENU
    MOV tmp_min,AX
    LEA DX,msg_qty
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE SP_MENU
    MOV tmp_max,AX
    ; header
    LEA DX,table_header
    MOV AH,9
    INT 21h
    LEA DX,table_line
    MOV AH,9
    INT 21h
    XOR SI,SI
    MOV CX,MAX_PROD
SP_QTY_LOOP:
    CMP prod_id[SI],0
    JE SP_QTY_NEXT
    PUSH SI
    MOV BX,SI
    SHL BX,1
    MOV AX,prod_qty[BX]
    ; normalize using tmp vars
    PUSH AX
    MOV DX,tmp_min
    MOV BX,tmp_max
    CMP DX,BX
    JBE SP_QM_OK
    XCHG DX,BX
SP_QM_OK:
    POP AX
    CMP AX,DX
    JB SP_Q_NO
    CMP AX,BX
    JA SP_Q_NO
    POP SI
    CALL DISPLAY_PRODUCT_AT_INDEX
    JMP SP_Q_CONT
SP_Q_NO:
    POP SI
SP_Q_CONT:
SP_QTY_NEXT:
    INC SI
    LOOP SP_QTY_LOOP
    JMP SP_MENU

SP_NOT_FOUND:
    LEA DX,msg_nf
    MOV AH,9
    INT 21h
    JMP SP_MENU
SP_EXIT:
    RET
SEARCH_PROD ENDP

; ========================= ADMIN: SORT PRODUCTS =========================
SORT_PROD PROC
    LEA DX,msg_sort_hdr
    MOV AH,9
    INT 21h
SPT_MENU:
    LEA DX,msg_sort_menu
    MOV AH,9
    INT 21h
    LEA DX,msg_choice
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE SPT_EXIT
    CMP AX,1
    JE SPT_P_ASC
    CMP AX,2
    JE SPT_P_DESC
    CMP AX,3
    JE SPT_Q_ASC
    CMP AX,4
    JE SPT_Q_DESC
    CMP AX,5
    JE SPT_EXIT
    JMP SPT_MENU

; Bubble sort by price asc
SPT_P_ASC:
    CALL BUBBLE_SORT_PRICE_ASC
    JMP SPT_SHOW
SPT_P_DESC:
    CALL BUBBLE_SORT_PRICE_DESC
    JMP SPT_SHOW
SPT_Q_ASC:
    CALL BUBBLE_SORT_QTY_ASC
    JMP SPT_SHOW
SPT_Q_DESC:
    CALL BUBBLE_SORT_QTY_DESC
    JMP SPT_SHOW

SPT_SHOW:
    ; Show full list
    CALL VIEW_PROD
    JMP SPT_MENU

SPT_EXIT:
    RET
SORT_PROD ENDP

; Bubble sort helpers
BUBBLE_SORT_PRICE_ASC PROC
    PUSH SI
    PUSH DI
    PUSH AX
    PUSH BX
    PUSH CX
    MOV CX,MAX_PROD
    DEC CX
BS1_O:
    MOV SI,0
    MOV DI,1
    MOV BX,CX
BS1_I:
    ; skip empty entries
    CMP prod_id[SI],0
    JE BS1_NEXT
    CMP prod_id[DI],0
    JE BS1_ADV
    ; compare
    PUSH SI
    SHL SI,1
    MOV AX,prod_price[SI]
    POP SI
    PUSH DI
    SHL DI,1
    CMP AX,prod_price[DI]
    JBE BS1_ADV2
    POP DI
    CALL SWAP_PRODUCTS
    JMP BS1_NEXT
BS1_ADV2:
    POP DI
BS1_ADV:
    INC SI
    INC DI
BS1_NEXT:
    DEC BX
    JNZ BS1_I
    LOOP BS1_O
    POP CX
    POP BX
    POP AX
    POP DI
    POP SI
    RET
BUBBLE_SORT_PRICE_ASC ENDP

BUBBLE_SORT_PRICE_DESC PROC
    PUSH SI
    PUSH DI
    PUSH AX
    PUSH BX
    PUSH CX
    MOV CX,MAX_PROD
    DEC CX
BD1_O:
    MOV SI,0
    MOV DI,1
    MOV BX,CX
BD1_I:
    CMP prod_id[SI],0
    JE BD1_NEXT
    CMP prod_id[DI],0
    JE BD1_ADV
    PUSH SI
    SHL SI,1
    MOV AX,prod_price[SI]
    POP SI
    PUSH DI
    SHL DI,1
    CMP AX,prod_price[DI]
    JAE BD1_ADV2
    POP DI
    CALL SWAP_PRODUCTS
    JMP BD1_NEXT
BD1_ADV2:
    POP DI
BD1_ADV:
    INC SI
    INC DI
BD1_NEXT:
    DEC BX
    JNZ BD1_I
    LOOP BD1_O
    POP CX
    POP BX
    POP AX
    POP DI
    POP SI
    RET
BUBBLE_SORT_PRICE_DESC ENDP

BUBBLE_SORT_QTY_ASC PROC
    PUSH SI
    PUSH DI
    PUSH AX
    PUSH BX
    PUSH CX
    MOV CX,MAX_PROD
    DEC CX
BQ1_O:
    MOV SI,0
    MOV DI,1
    MOV BX,CX
BQ1_I:
    CMP prod_id[SI],0
    JE BQ1_NEXT
    CMP prod_id[DI],0
    JE BQ1_ADV
    PUSH SI
    SHL SI,1
    MOV AX,prod_qty[SI]
    POP SI
    PUSH DI
    SHL DI,1
    CMP AX,prod_qty[DI]
    JBE BQ1_ADV2
    POP DI
    CALL SWAP_PRODUCTS
    JMP BQ1_NEXT
BQ1_ADV2:
    POP DI
BQ1_ADV:
    INC SI
    INC DI
BQ1_NEXT:
    DEC BX
    JNZ BQ1_I
    LOOP BQ1_O
    POP CX
    POP BX
    POP AX
    POP DI
    POP SI
    RET
BUBBLE_SORT_QTY_ASC ENDP

BUBBLE_SORT_QTY_DESC PROC
    PUSH SI
    PUSH DI
    PUSH AX
    PUSH BX
    PUSH CX
    MOV CX,MAX_PROD
    DEC CX
BDQ1_O:
    MOV SI,0
    MOV DI,1
    MOV BX,CX
BDQ1_I:
    CMP prod_id[SI],0
    JE BDQ1_NEXT
    CMP prod_id[DI],0
    JE BDQ1_ADV
    PUSH SI
    SHL SI,1
    MOV AX,prod_qty[SI]
    POP SI
    PUSH DI
    SHL DI,1
    CMP AX,prod_qty[DI]
    JAE BDQ1_ADV2
    POP DI
    CALL SWAP_PRODUCTS
    JMP BDQ1_NEXT
BDQ1_ADV2:
    POP DI
BDQ1_ADV:
    INC SI
    INC DI
BDQ1_NEXT:
    DEC BX
    JNZ BDQ1_I
    LOOP BDQ1_O
    POP CX
    POP BX
    POP AX
    POP DI
    POP SI
    RET
BUBBLE_SORT_QTY_DESC ENDP

; ========================= ADMIN: FILTER LOW STOCK =========================
FILTER_LOW_STOCK PROC
    LEA DX,msg_filter_hdr
    MOV AH,9
    INT 21h
    ; header
    LEA DX,table_header
    MOV AH,9
    INT 21h
    LEA DX,table_line
    MOV AH,9
    INT 21h
    MOV BL,0 ; found flag
    XOR SI,SI
    MOV CX,MAX_PROD
FLS_LOOP:
    CMP prod_id[SI],0
    JE FLS_NEXT
    PUSH SI
    MOV BX,SI
    SHL BX,1
    MOV AX,prod_qty[BX]
    CMP AX,20
    POP SI
    JA FLS_NEXT
    CALL DISPLAY_PRODUCT_AT_INDEX
    MOV BL,1
FLS_NEXT:
    INC SI
    LOOP FLS_LOOP
    CMP BL,1
    JE FLS_DONE
    LEA DX,msg_no_low_stock_prod
    MOV AH,9
    INT 21h
FLS_DONE:
    RET
FILTER_LOW_STOCK ENDP

; ========================= RESULTS HELPERS =========================
INIT_RESULTS PROC
    MOV result_count,0
    MOV DI,0
    MOV CX,MAX_PROD
IR_CLR:
    MOV BYTE PTR result_idx[DI],0
    INC DI
    LOOP IR_CLR
    RET
INIT_RESULTS ENDP

; Convert $-terminated (max 20) from SI to uppercase, write to DI, zero-terminated
STR_UPPER_TO PROC
    PUSH AX
    PUSH BX
    PUSH CX
    MOV CX,21
SUT_LOOP:
    MOV AL,[SI]
    MOV BL,AL
    CMP AL,'$'
    JE SUT_ZERO
    CMP AL,0
    JE SUT_ZERO
    CMP AL,'a'
    JB SUT_STORE
    CMP AL,'z'
    JA SUT_STORE
    SUB BL,20h
SUT_STORE:
    MOV [DI],BL
    INC SI
    INC DI
    LOOP SUT_LOOP
    JMP SUT_DONE
SUT_ZERO:
    MOV BYTE PTR [DI],0
SUT_DONE:
    ; guarantee 0 terminator
    MOV BYTE PTR [DI],0
    POP CX
    POP BX
    POP AX
    RET
STR_UPPER_TO ENDP

; Back-compat helper: uppercase from SI into tmp_upper_name
STR_TO_UPPER PROC
    PUSH DI
    LEA DI,tmp_upper_name
    CALL STR_UPPER_TO
    POP DI
    RET
STR_TO_UPPER ENDP

; Compare zero-terminated strings at SI and DI for equality (case-sensitive)
STR_EQ PROC
SE_LOOP:
    MOV AL,[SI]
    MOV BL,[DI]
    CMP AL,BL
    JNE SE_NE
    CMP AL,0
    JE SE_EQ
    INC SI
    INC DI
    JMP SE_LOOP
SE_EQ:
    MOV AL,1
    RET
SE_NE:
    MOV AL,0
    RET
STR_EQ ENDP

; Contains: needle at SI, haystack at DI, both zero-terminated, case-sensitive
STR_CONTAINS PROC
    PUSH SI
    PUSH DI
    PUSH BX
    PUSH CX
    ; If needle empty -> match
    MOV AL,[SI]
    CMP AL,0
    JE SC_YES
    ; Outer scan over haystack
SC_OUT:
    MOV AL,[DI]
    CMP AL,0
    JE SC_NO
    PUSH SI
    PUSH DI
SC_IN:
    MOV AL,[SI]
    MOV BL,[DI]
    CMP AL,0
    JE SC_MATCH
    CMP AL,BL
    JNE SC_BREAK
    INC SI
    INC DI
    JMP SC_IN
SC_MATCH:
    POP DI
    POP SI
    JMP SC_YES
SC_BREAK:
    POP DI
    POP SI
    INC DI
    JMP SC_OUT
SC_NO:
    MOV AL,0
    JMP SC_DONE
SC_YES:
    MOV AL,1
SC_DONE:
    POP CX
    POP BX
    POP DI
    POP SI
    RET
STR_CONTAINS ENDP

; Display table using indices from result_idx and count result_count
DISPLAY_RESULTS_TABLE PROC
    ; header
    LEA DX,table_header
    MOV AH,9
    INT 21h
    LEA DX,table_line
    MOV AH,9
    INT 21h
    ; iterate
    XOR SI,SI
    MOV CL,result_count
    XOR CH,CH
DRT_LOOP:
    CMP SI,CX
    JAE DRT_DONE
    ; fetch product index
    MOV BL,result_idx[SI]
    XOR BH,BH
    PUSH SI
    MOV SI,BX
    CALL DISPLAY_PRODUCT_AT_INDEX
    POP SI
    INC SI
    JMP DRT_LOOP
DRT_DONE:
    ; optional low stock warnings
    CMP low_stock_view_flag,1
    JNE DRT_EXIT
    XOR SI,SI
    MOV CL,result_count
    XOR CH,CH
DRT_W_LOOP:
    CMP SI,CX
    JAE DRT_EXIT
    MOV BL,result_idx[SI]
    XOR BH,BH
    SHL BX,1
    MOV AX,prod_qty[BX]
    CMP AX,LOW_STOCK_THRESHOLD
    JA DRT_W_NEXT
    LEA DX,msg_low_stock_pref
    MOV AH,9
    INT 21h
    ; print name
    MOV BX,SI
    MOV BL,result_idx[BX]
    XOR BH,BH
    MOV AX,BX
    MOV BX,20
    MUL BX
    LEA DI,prod_name
    ADD DI,AX
    MOV DX,DI
    MOV AH,9
    INT 21h
    LEA DX,msg_low_stock_suf
    MOV AH,9
    INT 21h
DRT_W_NEXT:
    INC SI
    JMP DRT_W_LOOP
DRT_EXIT:
    RET
DISPLAY_RESULTS_TABLE ENDP

; Sort result_idx using bubble sort and compare by mode in sort_mode
SORT_RESULTS PROC
    PUSH SI
    PUSH DI
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH BP
    
    ; Check if we have enough items to sort
    MOV AL,result_count
    CMP AL,2
    JB SRT_DONE                 ; Skip if less than 2 items
    
    ; Bubble sort on result_idx array
    ; Outer loop: i = 0 to result_count-2
    MOV CL,result_count
    DEC CL                      ; CL = result_count - 1
    XOR CH,CH                   ; CX = result_count - 1
    
SRT_OUTER_LOOP:
    PUSH CX                     ; Save outer loop counter
    
    ; Inner loop: j = 0 to result_count-2-i
    XOR SI,SI                   ; SI = j (inner loop counter)
    
SRT_INNER_LOOP:
    ; Compare result_idx[SI] with result_idx[SI+1]
    MOV DI,SI
    INC DI                      ; DI = SI + 1
    
    ; Get indices for comparison
    MOV AL,result_idx[SI]       ; AL = first product index
    MOV AH,result_idx[DI]       ; AH = second product index
    XOR BX,BX
    XOR BP,BP
    
    ; Convert to word indices for array access
    MOV BL,AL
    SHL BX,1                    ; BX = first_index * 2
    MOV BL,AH  
    MOV BP,BX                   ; BP = second_index * 2
    XOR BX,BX
    MOV BL,AL
    SHL BX,1                    ; BX = first_index * 2 (restore)
    
    ; Compare based on sort_mode
    MOV AL,sort_mode
    CMP AL,1
    JE SRT_PRICE_ASC
    CMP AL,2
    JE SRT_PRICE_DESC
    CMP AL,3
    JE SRT_QTY_ASC
    CMP AL,4
    JE SRT_QTY_DESC
    JMP SRT_NO_SWAP             ; Default: no swap
    
SRT_PRICE_ASC:
    ; Compare prod_price[first] with prod_price[second]
    MOV AX,prod_price[BX]       ; AX = price of first product
    PUSH AX                     ; Save first price
    MOV AX,prod_price[BP]       ; AX = price of second product
    POP CX                      ; CX = first price
    CMP CX,AX                   ; Compare first with second
    JA SRT_DO_SWAP              ; Swap if first > second
    JMP SRT_NO_SWAP
    
SRT_PRICE_DESC:
    ; Compare prod_price[first] with prod_price[second]
    MOV AX,prod_price[BX]       ; AX = price of first product
    PUSH AX                     ; Save first price
    MOV AX,prod_price[BP]       ; AX = price of second product
    POP CX                      ; CX = first price
    CMP CX,AX                   ; Compare first with second
    JB SRT_DO_SWAP              ; Swap if first < second
    JMP SRT_NO_SWAP
    
SRT_QTY_ASC:
    ; Compare prod_qty[first] with prod_qty[second]
    MOV AX,prod_qty[BX]         ; AX = qty of first product
    PUSH AX                     ; Save first qty
    MOV AX,prod_qty[BP]         ; AX = qty of second product
    POP CX                      ; CX = first qty
    CMP CX,AX                   ; Compare first with second
    JA SRT_DO_SWAP              ; Swap if first > second
    JMP SRT_NO_SWAP
    
SRT_QTY_DESC:
    ; Compare prod_qty[first] with prod_qty[second]
    MOV AX,prod_qty[BX]         ; AX = qty of first product
    PUSH AX                     ; Save first qty
    MOV AX,prod_qty[BP]         ; AX = qty of second product
    POP CX                      ; CX = first qty
    CMP CX,AX                   ; Compare first with second
    JB SRT_DO_SWAP              ; Swap if first < second
    JMP SRT_NO_SWAP
    
SRT_DO_SWAP:
    ; Swap result_idx[SI] and result_idx[DI]
    MOV AL,result_idx[SI]
    MOV AH,result_idx[DI]
    MOV result_idx[SI],AH
    MOV result_idx[DI],AL
    
SRT_NO_SWAP:
    ; Move to next pair
    INC SI
    MOV AL,result_count
    DEC AL
    CMP SI,AX                   ; Check if SI < result_count-1
    JB SRT_INNER_LOOP
    
    ; End of inner loop
    POP CX                      ; Restore outer loop counter
    LOOP SRT_OUTER_LOOP
    
SRT_DONE:
    POP BP
    POP DX
    POP CX
    POP BX
    POP AX
    POP DI
    POP SI
    RET
SORT_RESULTS ENDP

; ========================= SEARCH MENU (inline sort) =========================
SEARCH_MENU PROC
SM_TOP:
    CALL INIT_RESULTS
    MOV low_stock_view_flag,0
    LEA DX,msg_search_hdr2
    MOV AH,9
    INT 21h
    LEA DX,msg_search_menu2
    MOV AH,9
    INT 21h
    LEA DX,msg_choice
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE SM_BACK
    CMP AX,1
    JE SM_ID
    CMP AX,2
    JE SM_NAME
    CMP AX,3
    JE SM_LOW
    CMP AX,4
    JE SM_BACK
    JMP SM_TOP

SM_ID:
    LEA DX,msg_id
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE SM_TOP
    ; find first match by id
    MOV SI,0
    MOV CX,MAX_PROD
SM_ID_LOOP:
    CMP prod_id[SI],AL
    JE SM_ID_FOUND
    INC SI
    LOOP SM_ID_LOOP
    LEA DX,msg_nf
    MOV AH,9
    INT 21h
    JMP SM_TOP
SM_ID_FOUND:
    ; store low 8 bits of SI into result_idx[0]
    MOV DX,SI
    MOV result_idx[0],DL
    MOV result_count,1
    JMP SM_POST_SEARCH

SM_NAME:
    LEA DX,msg_item_name
    MOV AH,9
    INT 21h
    LEA DI,temp_name
    CALL GET_STRING_BACK
    CMP AL,0
    JE SM_TOP
    ; case-insensitive partial match: uppercase query into tmp_upper_query
    LEA SI,temp_name
    LEA DI,tmp_upper_query
    CALL STR_UPPER_TO
    ; tmp_upper_name for each product
    XOR SI,SI
    MOV CX,MAX_PROD
SM_CT_LOOP:
    CMP prod_id[SI],0
    JE SM_CT_NEXT
    PUSH SI
    MOV AX,SI
    MOV BX,20
    MUL BX
    LEA DI,prod_name
    ADD DI,AX
    ; uppercase product name into tmp_upper_name
    LEA SI,DI
    CALL STR_TO_UPPER
    ; now tmp_upper_name is haystack, tmp_upper_query is needle
    LEA DI,tmp_upper_name
    LEA SI,tmp_upper_query
    CALL STR_CONTAINS
    POP SI
    CMP AL,1
    JNE SM_CT_NEXT
    MOV BL,result_count
    CMP BL,MAX_PROD
    JAE SM_TRUNC
    ; result_idx[result_count] = low 8 bits of SI
    MOV BH,0
    MOV DX,SI
    MOV result_idx[BX],DL
    INC result_count
SM_CT_NEXT:
    INC SI
    LOOP SM_CT_LOOP
    JMP SM_POST_SEARCH

SM_LOW:
    CALL INIT_RESULTS
    MOV low_stock_view_flag,1
    XOR SI,SI
    MOV CX,MAX_PROD
SM_LOW_LOOP:
    CMP prod_id[SI],0
    JE SM_LOW_NEXT
    MOV BX,SI
    SHL BX,1
    MOV AX,prod_qty[BX]
    CMP AX,LOW_STOCK_THRESHOLD
    JA SM_LOW_NEXT
    MOV BL,result_count
    CMP BL,MAX_PROD
    JAE SM_TRUNC
    ; result_idx[result_count] = low 8 bits of SI
    MOV BH,0
    MOV DX,SI
    MOV result_idx[BX],DL
    INC result_count
SM_LOW_NEXT:
    INC SI
    LOOP SM_LOW_LOOP
    JMP SM_POST_SEARCH

SM_TRUNC:
    MOV warn_truncated_flag,1
    JMP SM_POST_SEARCH

SM_POST_SEARCH:
    ; If no results, inform and return to search menu
    CMP result_count,0
    JNE SM_SHOW_FIRST
    LEA DX,msg_no_matches
    MOV AH,9
    INT 21h
    JMP SM_TOP

; Always show results first (unsorted)
SM_SHOW_FIRST:
    CALL DISPLAY_RESULTS_TABLE
    ; If only 1 result, skip sort prompt as it's not useful
    CMP result_count,1
    JBE SM_SHOW_AFTER

    ; Ask if admin wants to sort the current results
    LEA DX,msg_sort_inline
    MOV AH,9
    INT 21h
    LEA DX,msg_choice
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    ; 1-4 => sort
    CMP AX,1
    JB SM_SHOW_AFTER        ; any other/invalid => keep current view
    CMP AX,4
    JBE SM_DO_SORT
    ; 5 => No (keep view)
    CMP AX,5
    JE SM_SHOW_AFTER
    ; 6 => Back to Search Menu
    CMP AX,6
    JE SM_TOP
    ; default => keep current view
    JMP SM_SHOW_AFTER

SM_DO_SORT:
    MOV AL,1
    CMP AX,1
    JE SM_SET
    MOV AL,2
    CMP AX,2
    JE SM_SET
    MOV AL,3
    CMP AX,3
    JE SM_SET
    MOV AL,4
SM_SET:
    MOV sort_mode,AL
    CALL SORT_RESULTS
SM_SHOW:
    ; After sorting, (re)display results
    CALL DISPLAY_RESULTS_TABLE
    LEA DX,msg_res_prompt
    MOV AH,9
    INT 21h
    LEA DX,msg_choice
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,1
    JE SM_TOP
    CMP AX,2
    JE SM_TOP
SM_BACK:
    RET
; After initial unsorted display without sorting
SM_SHOW_AFTER:
    LEA DX,msg_res_prompt
    MOV AH,9
    INT 21h
    LEA DX,msg_choice
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,1
    JE SM_TOP
    CMP AX,2
    JE SM_TOP
    JMP SM_BACK
SEARCH_MENU ENDP

; ========================= MARK LOW STOCK FOR REORDER =========================
MARK_LOW_STOCK_FOR_REORDER PROC
    PUSH SI
    PUSH BX
    PUSH AX
    PUSH CX
    
    ; Clear reorder queue first
    MOV reorder_count,0
    XOR DI,DI
    MOV CX,MAX_REORDER
MLSFR_CLEAR:
    MOV reorder_prod_id[DI],0
    INC DI
    LOOP MLSFR_CLEAR
    
    ; Scan for low stock products and add to reorder queue
    XOR SI,SI
    MOV CX,MAX_PROD
MLSFR_SCAN:
    CMP prod_id[SI],0
    JE MLSFR_NEXT
    
    ; Check if quantity < 20
    MOV BX,SI
    SHL BX,1
    MOV AX,prod_qty[BX]
    CMP AX,20
    JGE MLSFR_NEXT
    
    ; Add to reorder queue if there's space
    MOV AL,reorder_count
    CMP AL,MAX_REORDER
    JAE MLSFR_NEXT  ; Queue full
    
    XOR AH,AH
    MOV BX,AX
    MOV AL,prod_id[SI]
    MOV reorder_prod_id[BX],AL
    INC reorder_count
    
MLSFR_NEXT:
    INC SI
    LOOP MLSFR_SCAN
    
    POP CX
    POP AX
    POP BX
    POP SI
    RET
MARK_LOW_STOCK_FOR_REORDER ENDP

; ========================= MANAGE REORDER QUEUE =========================
MANAGE_REORDER_QUEUE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
MRQ_MENU:
    ; Clean queue first (remove products no longer low stock)
    CALL CLEAN_REORDER_QUEUE
    
    ; Show reorder queue header
    LEA DX,msg_reorder_queue_hdr
    MOV AH,9
    INT 21h
    
    ; Check if queue is empty
    MOV AL,reorder_count
    CMP AL,0
    JNE MRQ_SHOW_QUEUE
    
    LEA DX,msg_no_reorder
    MOV AH,9
    INT 21h
    JMP MRQ_EXIT
    
MRQ_SHOW_QUEUE:
    ; Display products in reorder queue
    CALL DISPLAY_REORDER_QUEUE
    
    ; Show reorder menu
    LEA DX,msg_reorder_menu
    MOV AH,9
    INT 21h
    LEA DX,msg_choice
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE MRQ_EXIT
    CMP AX,1
    JE MRQ_RESTOCK_SELECTED
    CMP AX,2
    JE MRQ_CLEAR_QUEUE
    CMP AX,3
    JE MRQ_EXIT
    JMP MRQ_MENU

MRQ_RESTOCK_SELECTED:
    CALL RESTOCK_SELECTED_FROM_QUEUE
    JMP MRQ_MENU

MRQ_CLEAR_QUEUE:
    MOV reorder_count,0
    ; Clear all entries
    XOR SI,SI
    MOV CX,MAX_REORDER
MRQ_CLEAR_LOOP:
    MOV reorder_prod_id[SI],0
    INC SI
    LOOP MRQ_CLEAR_LOOP
    
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_restock_cancel
    MOV AH,9
    INT 21h
    JMP MRQ_MENU

MRQ_EXIT:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
MANAGE_REORDER_QUEUE ENDP

; ========================= CLEAN REORDER QUEUE =========================
CLEAN_REORDER_QUEUE PROC
    ; Remove products from reorder queue that are no longer low stock (qty >= 20)
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    XOR SI,SI               ; SI = queue index
    MOV CL,reorder_count
    XOR CH,CH
    
CRQ_CHECK_LOOP:
    CMP SI,CX
    JAE CRQ_DONE
    
    ; Get product ID from queue
    MOV AL,reorder_prod_id[SI]
    CMP AL,0
    JE CRQ_NEXT
    
    ; Find product in inventory
    PUSH SI
    PUSH CX
    CALL FIND_PROD          ; Find product by ID in AL, result in SI
    CMP SI,255
    JE CRQ_REMOVE_INVALID   ; Product not found, remove from queue
    
    ; Check if quantity >= 20
    MOV BX,SI
    SHL BX,1
    MOV AX,prod_qty[BX]
    CMP AX,20
    JAE CRQ_REMOVE_RESTOCKED ; Product no longer low stock, remove from queue
    
    ; Product still low stock, keep in queue
    POP CX
    POP SI
    JMP CRQ_NEXT
    
CRQ_REMOVE_INVALID:
CRQ_REMOVE_RESTOCKED:
    POP CX
    POP SI
    ; Remove this product from queue by shifting remaining entries
    MOV DI,SI
    INC DI
CRQ_SHIFT:
    CMP DI,CX
    JAE CRQ_SHIFT_DONE
    MOV AL,reorder_prod_id[DI]
    MOV reorder_prod_id[SI],AL
    INC SI
    INC DI
    JMP CRQ_SHIFT
    
CRQ_SHIFT_DONE:
    ; Clear last entry and decrement count
    DEC reorder_count
    DEC CX
    MOV AL,reorder_count
    XOR AH,AH
    MOV DI,AX
    MOV reorder_prod_id[DI],0
    ; Don't increment SI since we shifted everything left
    JMP CRQ_CHECK_LOOP
    
CRQ_NEXT:
    INC SI
    JMP CRQ_CHECK_LOOP
    
CRQ_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CLEAN_REORDER_QUEUE ENDP

; ========================= DISPLAY REORDER QUEUE =========================
DISPLAY_REORDER_QUEUE PROC
    PUSH SI
    PUSH BX
    PUSH AX
    PUSH CX
    PUSH DX
    
    LEA DX,table_header
    MOV AH,9
    INT 21h
    LEA DX,table_line
    MOV AH,9
    INT 21h
    
    XOR SI,SI
    MOV CL,reorder_count
    XOR CH,CH
    
DRQ_LOOP:
    CMP SI,CX
    JAE DRQ_DONE
    
    ; Get product ID from reorder queue
    MOV AL,reorder_prod_id[SI]
    
    ; Find product index
    PUSH SI
    PUSH CX
    XOR DI,DI
    MOV CX,MAX_PROD
DRQ_FIND:
    CMP prod_id[DI],AL
    JE DRQ_FOUND
    INC DI
    LOOP DRQ_FIND
    JMP DRQ_NOT_FOUND
    
DRQ_FOUND:
    MOV SI,DI
    CALL DISPLAY_PRODUCT_AT_INDEX
    
DRQ_NOT_FOUND:
    POP CX
    POP SI
    INC SI
    JMP DRQ_LOOP
    
DRQ_DONE:
    POP DX
    POP CX
    POP AX
    POP BX
    POP SI
    RET
DISPLAY_REORDER_QUEUE ENDP

; ========================= RESTOCK ALL IN QUEUE =========================
RESTOCK_ALL_IN_QUEUE PROC
    PUSH SI
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AL,reorder_count
    CMP AL,0
    JE RAIQ_EMPTY_QUEUE
    
    XOR SI,SI
    MOV CL,reorder_count
    XOR CH,CH
    
RAIQ_LOOP:
    CMP SI,CX
    JAE RAIQ_DONE
    
    ; Get product ID and find product
    MOV AL,reorder_prod_id[SI]
    PUSH SI
    PUSH CX
    CALL FIND_PROD  ; Find product by ID in AL, result in SI
    CMP SI,255
    JE RAIQ_SKIP
    
    ; Add 50 units to inventory
    MOV BX,SI
    SHL BX,1
    ADD prod_qty[BX],50
    
RAIQ_SKIP:
    POP CX
    POP SI
    INC SI
    JMP RAIQ_LOOP
    
RAIQ_DONE:
    ; Clear entire reorder queue after restocking all
    MOV reorder_count,0
    XOR SI,SI
    MOV CX,MAX_REORDER
RAIQ_CLEAR_LOOP:
    MOV reorder_prod_id[SI],0
    INC SI
    LOOP RAIQ_CLEAR_LOOP
    
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_restocked
    MOV AH,9
    INT 21h
    LEA DX,nl
    MOV AH,9
    INT 21h
    JMP RAIQ_EXIT

RAIQ_EMPTY_QUEUE:
    LEA DX,msg_no_reorder
    MOV AH,9
    INT 21h

RAIQ_EXIT:
    POP DX
    POP CX
    POP BX
    POP AX
    POP SI
    RET
RESTOCK_ALL_IN_QUEUE ENDP

; ========================= RESTOCK SELECTED FROM QUEUE =========================
RESTOCK_SELECTED_FROM_QUEUE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Show products and ask for product ID
    LEA DX,msg_id
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE RSFQ_EXIT
    
    MOV BL,AL               ; Store product ID in BL
    CALL FIND_PROD          ; Find product by ID
    CMP SI,255
    JE RSFQ_NOT_FOUND
    
    ; Get restock quantity
    LEA DX,msg_restock
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE RSFQ_EXIT
    
    MOV CX,AX               ; Store restock quantity in CX
    
    ; Add to inventory
    MOV BX,SI
    SHL BX,1
    ADD prod_qty[BX],CX     ; Add restock quantity
    
    ; Check if product should be removed from reorder queue (qty >= 20)
    CMP prod_qty[BX],20
    JL RSFQ_KEEP_IN_QUEUE
    
    ; Remove from reorder queue since quantity is now >= 20
    MOV AL,prod_id[SI]      ; Get product ID
    CALL REMOVE_FROM_REORDER_QUEUE
    
RSFQ_KEEP_IN_QUEUE:
    ; Show success message with new quantity
    LEA DX,msg_restocked
    MOV AH,9
    INT 21h
    MOV AX,prod_qty[BX]
    CALL PRINT_NUM
    LEA DX,nl
    MOV AH,9
    INT 21h
    JMP RSFQ_EXIT

RSFQ_NOT_FOUND:
    LEA DX,msg_nf
    MOV AH,9
    INT 21h

RSFQ_EXIT:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
RESTOCK_SELECTED_FROM_QUEUE ENDP

; ========================= REMOVE FROM REORDER QUEUE =========================
REMOVE_FROM_REORDER_QUEUE PROC
    ; AL contains product ID to remove
    PUSH SI
    PUSH DI
    PUSH CX
    PUSH BX
    PUSH AX
    
    MOV BL,AL               ; Store product ID in BL
    XOR SI,SI
    MOV CL,reorder_count
    XOR CH,CH
    
RFRQ_FIND:
    CMP SI,CX
    JAE RFRQ_NOT_FOUND
    CMP reorder_prod_id[SI],BL
    JE RFRQ_FOUND
    INC SI
    JMP RFRQ_FIND
    
RFRQ_FOUND:
    ; Shift remaining entries left
    MOV DI,SI
    INC DI
RFRQ_SHIFT:
    CMP DI,CX
    JAE RFRQ_DONE_SHIFT
    MOV AL,reorder_prod_id[DI]
    MOV reorder_prod_id[SI],AL
    INC SI
    INC DI
    JMP RFRQ_SHIFT
    
RFRQ_DONE_SHIFT:
    ; Clear the last entry and decrement count
    DEC reorder_count
    MOV AL,reorder_count
    XOR AH,AH
    MOV SI,AX
    MOV reorder_prod_id[SI],0
    
RFRQ_NOT_FOUND:
    POP AX
    POP BX
    POP CX
    POP DI
    POP SI
    RET
REMOVE_FROM_REORDER_QUEUE ENDP

; ========================= UNDO LAST TRANSACTION =========================
UNDO_LAST_TRANSACTION PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Check if there are any sales
    MOV AL,sales_count
    CMP AL,0
    JE ULT_NO_SALES
    
    ; Get the last sale index (sales_count - 1)
    XOR BX,BX
    MOV BL,sales_count
    DEC BL                      ; BL = last sale index
    
    ; Get the invoice number of the last sale
    SHL BX,1                    ; BX = last sale index * 2 for word array
    MOV AX,sales_invoice_no[BX] ; AX = last invoice number
    
    ; Call UNDO_BY_INVOICE_NUMBER with the last invoice number
    CALL UNDO_BY_INVOICE_NUMBER
    JMP ULT_EXIT
    
ULT_NO_SALES:
    LEA DX,msg_no_undos
    MOV AH,9
    INT 21h
    
ULT_EXIT:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
UNDO_LAST_TRANSACTION ENDP

; ========================= UNDO BY INVOICE NUMBER =========================
UNDO_BY_INVOICE_NUMBER PROC
    ; AX contains invoice number to undo
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    MOV DI,AX                   ; Store invoice number in DI
    
    ; Search for all sales entries with this invoice number
    ; Start from the end and work backwards to avoid index shifting issues
    MOV CL,sales_count
    XOR CH,CH
    CMP CX,0                    ; Check if there are any sales
    JE UBIN_NOT_FOUND
    
    MOV SI,CX                   ; Start from sales_count
    DEC SI                      ; SI = sales_count - 1 (last index)
    MOV BL,0                    ; Found flag
    
UBIN_SEARCH:
    ; Check if this sales entry has the target invoice number
    MOV BX,SI
    SHL BX,1                    ; BX = SI * 2 for word array
    MOV AX,sales_invoice_no[BX]
    CMP AX,DI
    JNE UBIN_NEXT
    
    ; Found matching invoice - undo this sale
    CALL UNDO_SALE_AT_INDEX     ; SI contains the index
    MOV BL,1                    ; Set found flag
    
UBIN_NEXT:
    CMP SI,0                    ; Check if we've reached the beginning
    JE UBIN_CHECK_FOUND
    DEC SI                      ; Move to previous entry
    JMP UBIN_SEARCH
    
UBIN_CHECK_FOUND:
    CMP BL,1
    JE UBIN_SUCCESS
    
UBIN_NOT_FOUND:
    ; Invoice not found
    LEA DX,msg_invoice_not_found
    MOV AH,9
    INT 21h
    JMP UBIN_EXIT
    
UBIN_SUCCESS:
    LEA DX,msg_undo_success
    MOV AH,9
    INT 21h
    
UBIN_EXIT:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
UNDO_BY_INVOICE_NUMBER ENDP

; ========================= UNDO SALE AT INDEX =========================
UNDO_SALE_AT_INDEX PROC
    ; SI contains the sales index to undo
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    
    ; Get product ID and quantity from this sale
    MOV AL,sales_prod_id[SI]    ; AL = product ID
    MOV BX,SI
    SHL BX,1                    ; BX = SI * 2 for word array
    MOV DX,sales_qty[BX]        ; DX = quantity sold
    
    ; Find the product in inventory by ID
    PUSH SI                     ; Save sales index
    XOR DI,DI                   ; Start from product index 0
    MOV CX,MAX_PROD
USAI_FIND_PRODUCT:
    CMP prod_id[DI],AL          ; Compare with product ID
    JE USAI_PRODUCT_FOUND
    INC DI
    LOOP USAI_FIND_PRODUCT
    JMP USAI_CLEAR_ENTRY        ; Product not found, just clear entry
    
USAI_PRODUCT_FOUND:
    ; Add quantity back to product inventory
    MOV BX,DI                   ; BX = product index
    SHL BX,1                    ; BX = product index * 2 for word array
    ADD prod_qty[BX],DX         ; Add quantity back to inventory
    
USAI_CLEAR_ENTRY:
    POP SI                      ; Restore sales index
    
    ; Clear this sales entry by shifting remaining entries left
    MOV DI,SI                   ; DI = current index
    INC DI                      ; DI = next index
    MOV CL,sales_count
    XOR CH,CH
    
USAI_SHIFT:
    CMP DI,CX
    JAE USAI_DONE_SHIFT
    
    ; Shift sales_prod_id
    MOV AL,sales_prod_id[DI]
    MOV sales_prod_id[SI],AL
    
    ; Shift sales_qty and sales_invoice_no (word arrays)
    PUSH SI
    PUSH DI
    SHL SI,1                    ; SI = SI * 2
    SHL DI,1                    ; DI = DI * 2
    MOV AX,sales_qty[DI]
    MOV sales_qty[SI],AX
    MOV AX,sales_invoice_no[DI]
    MOV sales_invoice_no[SI],AX
    POP DI
    POP SI
    
    INC SI
    INC DI
    JMP USAI_SHIFT
    
USAI_DONE_SHIFT:
    ; Decrement sales count
    DEC sales_count
    
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
UNDO_SALE_AT_INDEX ENDP

; ========================= RESTOCK PRODUCT PROCEDURE =========================
RESTOCK_PROD PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_add
    MOV AH,9
    INT 21h
    
    ; Get product ID
    LEA DX,msg_id
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE RP_CANCEL
    
    MOV BL,AL           ; Store product ID
    CALL FIND_PROD      ; Find product by ID
    CMP SI,255
    JE RP_NOT_FOUND
    
    ; Show current quantity
    LEA DX,nl
    MOV AH,9
    INT 21h
    LEA DX,msg_qty
    MOV AH,9
    INT 21h
    MOV BX,SI
    SHL BX,1
    MOV AX,prod_qty[BX]
    CALL PRINT_NUM
    LEA DX,nl
    MOV AH,9
    INT 21h
    
    ; Get restock quantity
    LEA DX,msg_restock
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE RP_CANCEL
    
    ; Add to current quantity
    MOV BX,SI
    SHL BX,1
    ADD prod_qty[BX],AX
    
    ; Show success message with new quantity
    LEA DX,msg_restocked
    MOV AH,9
    INT 21h
    MOV AX,prod_qty[BX]
    CALL PRINT_NUM
    LEA DX,nl
    MOV AH,9
    INT 21h
    JMP RP_EXIT

RP_NOT_FOUND:
    LEA DX,msg_nf
    MOV AH,9
    INT 21h
    JMP RP_EXIT

RP_CANCEL:
    LEA DX,msg_restock_cancel
    MOV AH,9
    INT 21h

RP_EXIT:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
RESTOCK_PROD ENDP

; ========================= ENHANCED UNDO SALE PROCEDURE =========================
UNDO_LAST_SALE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    ; Show undo menu
    LEA DX,msg_undo_menu
    MOV AH,9
    INT 21h
    LEA DX,msg_choice
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE ULS_EXIT
    CMP AX,1
    JE ULS_UNDO_LAST
    CMP AX,2
    JE ULS_UNDO_BY_INVOICE
    CMP AX,3
    JE ULS_EXIT
    JMP ULS_EXIT

ULS_UNDO_LAST:
    ; Check if there are any sales to undo
    MOV AL,sales_count
    CMP AL,0
    JE ULS_NO_SALES
    
    ; Show confirmation prompt
    LEA DX,msg_confirm_undo
    MOV AH,9
    INT 21h
    
    ; Get user confirmation (Y/N)
    MOV AH,1
    INT 21h
    CMP AL,'y'
    JE ULS_CONFIRM_LAST
    CMP AL,'Y'
    JE ULS_CONFIRM_LAST
    JMP ULS_EXIT
    
ULS_CONFIRM_LAST:
    CALL UNDO_LAST_TRANSACTION
    JMP ULS_EXIT

ULS_UNDO_BY_INVOICE:
    ; Check if there are any sales
    MOV AL,sales_count
    CMP AL,0
    JE ULS_NO_SALES
    
    ; Get invoice number
    LEA DX,msg_invoice_prompt
    MOV AH,9
    INT 21h
    CALL GET_NUMBER_BACK
    CMP AX,0
    JE ULS_EXIT
    
    PUSH AX                     ; Save invoice number
    
    ; Confirm undo by invoice
    LEA DX,msg_confirm_undo
    MOV AH,9
    INT 21h
    MOV AH,1
    INT 21h
    CMP AL,'y'
    JE ULS_CONFIRM_INVOICE
    CMP AL,'Y'
    JE ULS_CONFIRM_INVOICE
    POP AX                      ; Clean up stack
    JMP ULS_EXIT

ULS_CONFIRM_INVOICE:
    POP AX                      ; Restore invoice number
    CALL UNDO_BY_INVOICE_NUMBER
    JMP ULS_EXIT
    
ULS_NO_SALES:
    LEA DX,msg_no_undos
    MOV AH,9
    INT 21h
    
ULS_EXIT:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
UNDO_LAST_SALE ENDP

    END MAIN
