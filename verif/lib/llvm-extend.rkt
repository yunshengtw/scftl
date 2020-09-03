#lang rosette

(require (rename-in serval/llvm [call llvm:call]))
(require serval/lib/core
         serval/lib/debug)
(require (only-in "./flash.rkt"
                  current-flash
                  current-pgsize
                  current-cellsize
                  current-npgs-per-blk
                  flash-read
                  flash-read-bulk
                  flash-program
                  flash-program-bulk
                  flash-erase
                  flash-erase-bulk
                  flash-sync))
(provide (except-out (all-from-out serval/llvm) llvm:call))
(provide (all-defined-out))

(struct tagcond (tag require cond desp))
(define (tagcond/desp tag req cond [desp "No description"])
  (tagcond tag req cond desp))

(struct loop (proc bodyproc inv exit condition havocs check))
(struct method (proc args precond postcond havocs check))

(define assumes (make-parameter null (lambda (x) (append x (assumes)))))
; assume accepts a list of tagged conditions
(define (assume tcs) (assumes (map (lambda (tc) (cons (tagcond-tag tc) (=> (pc) (tagcond-cond tc)))) tcs)))

(define current-abst (make-parameter #f))
(define current-mregions-saved (make-parameter #f))
(define current-havocs (make-parameter null))
; methods with specification
(define current-methods (make-parameter null))
(define current-loops (make-parameter null))

(define (save-state)
  (for ([name (map mregion-name (current-mregions))])
    (define mblk0 (find-block-by-name (current-mregions-saved) name))
    (define mblk1 (find-block-by-name (current-mregions) name))
    (cond
      [(marray? mblk1) (set-mcell-func! (marray-elements mblk0) (mcell-func (marray-elements mblk1)))]
      [(mcell? mblk1) (set-mcell-func! mblk0 (mcell-func mblk1))])))

(define (handle-method-with-spec m)
  (printf "Handle method with specification: ~e.\n" (object-name (method-proc m)))

  (save-state)

  ; raise an exception if the strongest postcondition
  ; does not imply the precondition of the invoked method
  (define-values (flag flag-asserted)
    (with-asserts 
      (begin
        (define pre
          ((method-precond m) (current-machine) (current-flash)
                              (current-mregions-saved) (current-abst)))
        (define assumed (apply && (map cdr (assumes))))
        ; (define assumed (&& (current-init) (apply && (assumes))))
        (define cex (verify (assert (=> assumed pre))))
        (unsat? cex))))
  (unless
    flag
    (printf "Method precondition violated\n")
    (assert #f))

  ; havoc modified variables
  (for/list ([name (method-havocs m)])
    (define mblock (find-block-by-name (current-mregions) name))
    ; (printf "havoc ~e\n" name)
    (mblock-init! mblock (list name)))

  ; add the postcondition of the invoked method to our assumption
  (define post ((method-postcond m)
    (current-machine) (current-flash)
    (current-mregions-saved) (current-abst)))
  (assume post))

(define (handle-loop-with-spec l)
  (printf "Handle loop with specification: ~e.\n" (object-name (loop-proc l)))

  (save-state)

  ; raise an exception if the strongest postcondition
  ; does not imply the precondition of the invoked loop
  (define-values (flag flag-asserted)
    (with-asserts 
      (begin
        ; requires loop body to be executed at least once,
        ; otherwise, verification fails.
        (define inv 
          ((loop-inv l) (current-machine) (current-flash)
                        (current-mregions-saved) (current-abst)))
        (define condition ((loop-condition l) (current-machine)))
        (define assumed (apply && (map cdr (assumes))))
        ; (define assumed (&& (current-init) (apply && (assumes))))
        (define cex (verify (assert (=> assumed (&& (apply && inv) condition)))))
        (when (sat? cex) (println cex))
        (unsat? cex))))
  (unless
    flag
    (printf "Loop precondition violated\n")
    (assert #f))

  ; havoc modified variables
  (for/list ([name (loop-havocs l)])
    (define mblock (find-block-by-name (current-mregions) name))
    ; (printf "havoc ~e\n" name)
    (mblock-init! mblock (list name)))

  ; add the loop exiting state to our assumption
  (define post ((loop-exit l)
    (current-machine) (current-flash)
    (current-mregions-saved) (current-abst)))
  (assume post))

; flash ops
(define (check-buf buf npgs)
  (define mblock (pointer-block buf))
  (define len (/ (current-pgsize) (current-cellsize)))
  (bug-on (not (marray? mblock))
          #:msg "buf is not a marray")
  (bug-on (not (mcell? (marray-elements mblock)))
          #:msg "buf element is not a mcell")
  (bug-on (not (equal? (mcell-size (marray-elements mblock)) (current-cellsize)))
          #:msg "buf element size is inconsistent with the flash cell size")
  (bug-on (not (equal? (marray-length mblock) (* len npgs)))
          #:msg "size mismatch between buf and flash")
  mblock)

(define (read blkid pgid data)
  (define mblock (check-buf data 1))
  (flash-read blkid pgid mblock))

(define (read-bulk blkid nblks data)
  (define mblock (check-buf data (* (bitvector->integer nblks) (current-npgs-per-blk))))
  (flash-read-bulk blkid nblks mblock))

(define (program blkid pgid data sync)
  (bug-on (term? sync) #:msg "symbolic sync flag")
  (define mblock (check-buf data 1))
  (flash-program blkid pgid mblock (! (bveq sync (bv 0 32)))))

(define (program-bulk blkid nblks data)
  (define mblock (check-buf data (* (bitvector->integer nblks) (current-npgs-per-blk))))
  (flash-program-bulk blkid nblks mblock))

(define (erase blkid sync)
  (bug-on (term? sync) #:msg "symbolic sync flag")
  (flash-erase blkid (! (bveq sync (bv 0 32)))))

(define (erase-bulk blkid nblks)
  (flash-erase-bulk blkid nblks))

(define (sync)
  (flash-sync))

(define (memset32 ptr val len)
  (define mblock (pointer-block ptr))
  (define offset (pointer-offset ptr))
  ; len is the number of bv32, we multiple len by 4 to get size
  (define size (bvshl len (bvpointer 2)))

  (bug-on (not (marray? mblock))
          #:msg "memset32: ptr is not an array")
  (bug-on (not (mcell? (marray-elements mblock)))
          #:msg "memset32: elements of ptr are not cells")
  (bug-on (not (equal? (mcell-size (marray-elements mblock)) 4))
          #:msg "memset32: ptr is not an 4-byte array")
  (bug-on (not (mblock-inbounds? mblock offset size))
          #:msg "memset32: ptr not in bounds")
  (bug-on (not ((bitvector 32) val))
          #:msg "memset32: val not a bv32")

  (define oldf (mcell-func (marray-elements mblock)))
  (define base (bvlshr offset (bvpointer 2)))
  (define newf (lambda (x) (if
    (&& (bvule base x) (bvult x (bvadd base len)))
    val
    (oldf x))))
  (set-mcell-func! (marray-elements mblock) newf)
  ptr)

(define (memcpy32 dst src len)
  (define mblock-dst (pointer-block dst))
  (define offset-dst (pointer-offset dst))
  (define mblock-src (pointer-block src))
  (define offset-src (pointer-offset src))
  ; len is the number of bv32, we multiple len by 4 to get size
  (define size (bvshl len (bvpointer 2)))

  (bug-on (not (marray? mblock-dst))
          #:msg "memcpy32: dst is not an array")
  (bug-on (not (mcell? (marray-elements mblock-dst)))
          #:msg "memcpy32: elements of dst are not cells")
  (bug-on (not (equal? (mcell-size (marray-elements mblock-dst)) 4))
          #:msg "memcpy32: dst is not an 4-byte array")
  (bug-on (not (mblock-inbounds? mblock-dst offset-dst size))
          #:msg "memcpy32: dst not in bounds")
  (bug-on (not (marray? mblock-src))
          #:msg "memcpy32: src is not an array")
  (bug-on (not (mcell? (marray-elements mblock-src)))
          #:msg "memcpy32: elements of src are not cells")
  (bug-on (not (equal? (mcell-size (marray-elements mblock-src)) 4))
          #:msg "memcpy32: src is not an 4-byte array")
  (bug-on (not (mblock-inbounds? mblock-src offset-src size))
          #:msg "memcpy32: src not in bounds")

  (define srcf (mcell-func (marray-elements mblock-src)))
  (define oldf (mcell-func (marray-elements mblock-dst)))
  (define base-dst (bvlshr offset-dst (bvpointer 2)))
  (define base-src (bvlshr offset-src (bvpointer 2)))
  (define newf (lambda (x) (if
    (&& (bvule base-dst x) (bvult x (bvadd base-dst len)))
    (srcf (bvadd (bvsub x base-dst) base-src))
    (oldf x))))
  (set-mcell-func! (marray-elements mblock-dst) newf)
  dst)

(define flash-ops (list
  (cons '@flash_read read)
  (cons '@flash_read_bulk read-bulk)
  (cons '@flash_program program)
  (cons '@flash_program_bulk program-bulk)
  (cons '@flash_erase erase)
  (cons '@flash_erase_bulk erase-bulk)
  (cons '@flash_sync sync)))

(define (handle-flash-op fop args)
  (apply (cdr fop) args))

(define mem-ops (list
  (cons '@memset32 memset32)
  (cons '@memcpy32 memcpy32)))

(define (handle-mem-op mop args)
  (apply (cdr mop) args))

; intercept llvm:call to support flash ops and methods with specification
(define (call func . args)
  (define fname (object-name func))
  (define method (findf (lambda (s) (equal? fname (object-name (method-proc s)))) (current-methods)))
  (define loop (findf (lambda (s) (equal? fname (object-name (loop-proc s)))) (current-loops)))
  (define fop (findf (lambda (f) (equal? fname (car f))) flash-ops))
  (define mop (findf (lambda (f) (equal? fname (car f))) mem-ops))
  (cond
    [method (handle-method-with-spec method)]
    [loop (handle-loop-with-spec loop)]
    [fop (handle-flash-op fop args)]
    [mop (handle-mem-op mop args)]
    [else (apply llvm:call (cons func args))]))
