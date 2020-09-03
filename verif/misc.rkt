#lang rosette

(require serval/lib/core
         "./const.rkt")

(provide (all-defined-out))

(define (make-bv32)
  (define-symbolic* bv32 (bitvector 32))
  bv32)

(define (bv16 x)
  (bv x (bitvector 16)))

(define (bv32 x)
  (bv x (bitvector 32)))

(define (bv64 x)
  (bv x (bitvector 64)))

(define (zext32 x)
  (zero-extend x (bitvector 32)))

(define (zext64 x)
  (zero-extend x (bitvector 64)))

(define (psa->pba psa)
  (define nbits-sect (inexact->exact (log SECTORS_PER_PAGE 2)))
  (define nbits-pg (inexact->exact (log PAGES_PER_BLOCK 2)))
  (define pba (bvashr psa (bv32 (+ nbits-sect nbits-pg))))
  pba)

(define (psa->ipa psa)
  (define nbits-sect (inexact->exact (log SECTORS_PER_PAGE 2)))
  (define nbits-pg (inexact->exact (log PAGES_PER_BLOCK 2)))
  (define ipa (zext32 (extract (- (+ nbits-sect nbits-pg) 1) nbits-sect psa)))
  ipa)

(define (psa->isa psa)
  (define nbits-sect (inexact->exact (log SECTORS_PER_PAGE 2)))
  (define isa (zext32 (extract (- nbits-sect 1) 0 psa)))
  isa)

(define (psa->pba-ipa psa)
  (define nbits-sect (inexact->exact (log SECTORS_PER_PAGE 2)))
  (define nbits-pg (inexact->exact (log PAGES_PER_BLOCK 2)))
  (define pba (bvashr psa (bv32 (+ nbits-sect nbits-pg))))
  (define ipa (zext32 (extract (- (+ nbits-sect nbits-pg) 1) nbits-sect psa)))
  (list pba ipa))

(define (psa->pba-ipa-isa psa)
  (define nbits-sect (inexact->exact (log SECTORS_PER_PAGE 2)))
  (define nbits-pg (inexact->exact (log PAGES_PER_BLOCK 2)))
  (define pba (bvashr psa (bv32 (+ nbits-sect nbits-pg))))
  (define ipa (zext32 (extract (- (+ nbits-sect nbits-pg) 1) nbits-sect psa)))
  (define isa (zext32 (extract (- nbits-sect 1) 0 psa)))
  (list pba ipa isa))

(define (psa->pba-ipa-isa64 psa)
  (define nbits-sect (inexact->exact (log SECTORS_PER_PAGE 2)))
  (define nbits-pg (inexact->exact (log PAGES_PER_BLOCK 2)))
  (define pba (bvashr psa (bv32 (+ nbits-sect nbits-pg))))
  (define ipa (zext32 (extract (- (+ nbits-sect nbits-pg) 1) nbits-sect psa)))
  (define isa (zext64 (extract (- nbits-sect 1) 0 psa)))
  (list pba ipa isa))

(define (pba-ipa-isa->psa pba ipa isa)
  (define nbits-sect (inexact->exact (log SECTORS_PER_PAGE 2)))
  (define nbits-pg (inexact->exact (log PAGES_PER_BLOCK 2)))
  (bvadd
    (bvshl pba (bv32 (+ nbits-sect nbits-pg)))
    (bvshl ipa (bv32 nbits-sect))
    isa))

(define (pba-isa->psa pba isa)
  (define nbits-sect (inexact->exact (log SECTORS_PER_PAGE 2)))
  (define nbits-pg (inexact->exact (log PAGES_PER_BLOCK 2)))
  (bvadd
    (bvshl pba (bv32 (+ nbits-sect nbits-pg)))
    isa))

(define (isa64->offset isa)
  (define nbits-offset (inexact->exact (log N_ENTRIES_PER_SECTOR 2)))
  (bvshl isa (bv nbits-offset (bvpointer?))))

(define (nblks->nsects nblks)
  (define nbits-sect (inexact->exact (log SECTORS_PER_PAGE 2)))
  (define nbits-pg (inexact->exact (log PAGES_PER_BLOCK 2)))
  (bvshl nblks (bv32 (+ nbits-pg nbits-sect))))

(define (npgs->nsects npgs)
  (define nbits-sect (inexact->exact (log SECTORS_PER_PAGE 2)))
  (bvshl npgs (bv32 nbits-sect)))

(define (n-usable-blks usable erasable)
  (cond
    [(bvule usable erasable) (bvsub erasable usable)]
    [else (bvsub (bvadd erasable (bvpointer BLOCKS_DATA)) usable)]))

(define (n-usable-and-erasable-blks usable invalid)
  (cond
    [(bvule usable invalid) (bvsub invalid usable)]
    [else (bvsub (bvadd invalid (bvpointer BLOCKS_DATA)) usable)]))

(define (n-used-blks used active)
  (cond
    [(bvule used active) (bvsub active used)]
    [else (bvsub (bvadd active (bvpointer BLOCKS_DATA)) used)]))

; A ready block is a usable | erasable | invalid block
(define (n-ready-blks usable used)
  (cond
    [(bvule usable used) (bvsub used usable)]
    [else (bvsub (bvadd used (bvpointer BLOCKS_DATA)) usable)]))

(define (n-avail-sects isa_active ipa_active usable invalid)
  (bvadd
    (bvsub (bv32 SECTORS_PER_PAGE) isa_active)
    (npgs->nsects (bvsub (bv32 (- PAGES_PER_BLOCK 1)) ipa_active))
    (nblks->nsects (extract 31 0 (n-usable-and-erasable-blks usable invalid)))))

(define (offset-las n)
  (bvadd n (bv OFFSET_LAS 64)))

(define (offset-pas n)
  (bvadd n (bv OFFSET_PAS 64)))
