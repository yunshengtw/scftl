#lang rosette

(require serval/lib/core)

(provide (all-defined-out))

(define (cell?) (bitvector (* (current-cellsize) 8)))
(define erased-val (bv -1 32))

(struct flash (erased synced content cfg) #:transparent #:mutable)
(struct flashcfg (nblks npgs-per-blk pgsize))

(define current-flash (make-parameter #f))
(define (current-flashcfg) (flash-cfg (current-flash)))
(define (current-nblks) (flashcfg-nblks (current-flashcfg)))
(define (current-npgs-per-blk) (flashcfg-npgs-per-blk (current-flashcfg)))
(define (current-pgsize) (flashcfg-pgsize (current-flashcfg)))
(define current-cellsize (make-parameter 4))
(define snapshots (make-parameter null (lambda (x) (append x (snapshots)))))
(define (snapshot x) (snapshots (list (cons (pc) x))))

(define (make-flash nblks npgs-per-blk pgsize)
  ; check pgsize is a multiple of cellsize
  (bug-on
    (not (zero? (remainder pgsize (current-cellsize))))
    #:msg "make-flash: page size must be a multiple of cell size")
  (bug-on
    (not (integer? (log npgs-per-blk 2)))
    #:msg "make-flash: number of pages per block is not a power of 2")
  (bug-on
    (not (integer? (log (/ pgsize (current-cellsize)) 2)))
    #:msg "make-flash: number of cells per page is not a power of 2")
  (define cfg (flashcfg nblks npgs-per-blk pgsize))
  (define-symbolic* erased (~> i32 i32 boolean?))
  (define-symbolic* synced (~> i32 i32 boolean?))
  (define-symbolic* init-content (~> i32 i32 (bvpointer?) (cell?)))
  (define content (lambda (b p o) (if
    (erased b p)
    erased-val
    (init-content b p o))))
  (flash erased synced content cfg))

(define (copy-flash f)
  (struct-copy flash f))

(define (retrieve-flash f)
  (values (flash-erased f) (flash-synced f) (flash-content f)))

(define (crash-flash f)
  (define erased (flash-erased f))
  (define synced (flash-synced f))
  (define content (flash-content f))
  (define-symbolic* any-content (~> i32 i32 (bvpointer?) (cell?)))
  (define crash-content (lambda (b p o) (cond
    [(! (synced b p)) (any-content b p o)]
    [else (content b p o)])))
  (set-flash-content! f crash-content)
  (define-symbolic* any-erased (~> i32 i32 boolean?))
  (define crash-erased (lambda (b p) (cond
    [(! (synced b p)) (any-erased b p)]
    [else (erased b p)])))
  (set-flash-erased! f crash-erased))

(define (flash-snapshot)
  (define f (struct-copy flash (current-flash)))
  (snapshot f))

(define (flash-program blkid pgid data sync)
  (define flash (current-flash))
  (define mcell-data (marray-elements data))
  (define dataf (mcell-func mcell-data))
  (define synced (flash-synced flash))
  (define erased (flash-erased flash))
  (define-symbolic b p i32)
  (bug-on
    (! (erased blkid pgid))
    #:msg "flash-program: violate erase-before-write constraint"
    #:key 'flash)
  (bug-on
    (exists
      (list p)
      (&&
        (bvult p pgid)
        (erased blkid p)))
    #:msg "flash-program: violate sequential program constraint"
    #:key 'flash)

  (when sync (flash-snapshot))
  (define old-erased (flash-erased flash))
  (define new-erased (lambda (b p) (if 
    (&& (bveq blkid b) (bveq pgid p))
    #f
    (old-erased b p))))
  (set-flash-erased! flash new-erased)
  (define old-synced (flash-synced flash))
  (define new-synced (lambda (b p) (if
    (&& (bveq blkid b) (bveq pgid p))
    sync
    (old-synced b p))))
  (set-flash-synced! flash new-synced)
  (define old-content (flash-content flash))
  (define new-content (lambda (b p o) (if
    (&& (bveq blkid b) (bveq pgid p))
    (dataf o)
    (old-content b p o))))
  (set-flash-content! flash new-content))

(define (flash-program-bulk blkid nblks data)
  (define flash (current-flash))
  (define mcell-data (marray-elements data))
  (define dataf (mcell-func mcell-data))
  (define synced (flash-synced flash))
  (define erased (flash-erased flash))
  (define blk-base blkid)
  (define blk-end (bvadd blk-base nblks))
  (define-symbolic b p i32)
  (bug-on
    (exists
      (list b p)
      (&&
        (bvule blk-base b)
        (bvult b blk-end)
        (bvult p (bv (current-npgs-per-blk) i32))
        (! (erased b p))))
    #:msg "flash-program-bulk: violate erase-before-write constraint"
    #:key 'flash)

  (define old-erased (flash-erased flash))
  (define new-erased (lambda (b p) (if 
    (&& (bvule blk-base b) (bvult b blk-end))
    #f
    (old-erased b p))))
  (set-flash-erased! flash new-erased)
  (define old-synced (flash-synced flash))
  (define new-synced (lambda (b p) (if
    (&& (bvule blk-base b) (bvult b blk-end))
    #f
    (old-synced b p))))
  (set-flash-synced! flash new-synced)
  (define old-content (flash-content flash))
  (define new-content (lambda (b p o) (if
    (&& (bvule blk-base b) (bvult b blk-end))
    (dataf (hier->flat (bvsub b blk-base) p o))
    (old-content b p o))))
  (set-flash-content! flash new-content))

(define (flash-read blkid pgid data)
  (define flash (current-flash))
  (define mcell-data (marray-elements data))
  (define content (flash-content flash))
  (define newf (lambda (x) (content blkid pgid x)))
  (set-mcell-func! mcell-data newf))

(define (flash-read-bulk blkid nblks data)
  (define flash (current-flash))
  (define mcell-data (marray-elements data))
  (define content (flash-content flash))
  (define (newf x)
    (define-values (blk-offset pg offset) (flat->hier x))
    (content (bvadd blkid blk-offset) pg offset))
  (set-mcell-func! mcell-data newf))

(define (flash-erase blkid sync)
  (define flash (current-flash))
  (when sync (flash-snapshot))
  (define-symbolic b p i32)
  (define old-erased (flash-erased flash))
  (define new-erased (lambda (b p) (if 
    (bveq blkid b)
    #t
    (old-erased b p))))
  (set-flash-erased! flash new-erased)
  (define old-synced (flash-synced flash))
  (define new-synced (lambda (b p) (if
    (bveq blkid b)
    sync
    (old-synced b p))))
  (set-flash-synced! flash new-synced)
  (define old-content (flash-content flash))
  (define new-content (lambda (b p o) (if
    (bveq blkid b)
    erased-val
    (old-content b p o))))
  (set-flash-content! flash new-content))

(define (flash-erase-bulk blkid nblks)
  (define flash (current-flash))
  (define blk-base blkid)
  (define blk-end (bvadd blk-base nblks))

  (define-symbolic b p i32)
  (define old-erased (flash-erased flash))
  (define new-erased (lambda (b p) (if 
    (&& (bvule blk-base b) (bvult b blk-end))
    #t
    (old-erased b p))))
  (set-flash-erased! flash new-erased)
  (define old-synced (flash-synced flash))
  (define new-synced (lambda (b p) (if
    (&& (bvule blk-base b) (bvult b blk-end))
    #f
    (old-synced b p))))
  (set-flash-synced! flash new-synced)
  (define old-content (flash-content flash))
  (define new-content (lambda (b p o) (if
    (&& (bvule blk-base b) (bvult b blk-end))
    erased-val
    (old-content b p o))))
  (set-flash-content! flash new-content))

(define (flash-sync)
  (define flash (current-flash))
  (flash-snapshot)
  (define new-synced (lambda (b p) #t))
  (set-flash-synced! flash new-synced))

(define (hier->flat blk pg offset)
  (define nbits-offset (inexact->exact (log (/ (current-pgsize) (current-cellsize)) 2)))
  (define nbits-pg (inexact->exact (log (current-npgs-per-blk) 2)))
  (define nbits-blk (inexact->exact (- 32 (+ nbits-offset nbits-pg))))
  (define b (extract (- nbits-blk 1) 0 blk))
  (define p (extract (- nbits-pg 1) 0 pg))
  (define o (extract (- nbits-offset 1) 0 offset))
  (zero-extend (concat b p o) (bvpointer?)))

(define (flat->hier x)
  (define nbits-offset (inexact->exact (log (/ (current-pgsize) (current-cellsize)) 2)))
  (define nbits-pg (inexact->exact (log (current-npgs-per-blk) 2)))
  (define b (extract 31 0 (bvashr x (bv (+ nbits-pg nbits-offset) (bvpointer?)))))
  (define p (zero-extend (extract (- (+ nbits-pg nbits-offset) 1) nbits-offset x) i32))
  (define o (zero-extend (extract (- nbits-offset 1) 0 x) (bvpointer?)))
  (values b p o))
