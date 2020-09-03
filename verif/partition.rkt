#lang rosette

(require "./misc.rkt"
         "./util.rkt"
         "./const.rkt")

(provide (all-defined-out))

(define (cr-partition-flush mrs)
  (list
    (list
      (cons 1 (&&
        (! (pc-delta-region-almost-full mrs))
        (pc-delta-block-full mrs)))
      (cons 2 (&&
        (! (pc-delta-region-almost-full mrs))
        (! (pc-delta-block-full mrs))))
      (cons 4 (&&
        (pc-delta-region-almost-full mrs))))
    (list
      (cons 3 #t))
    (list
      (cons 3 #t))
    (list
      (cons 1 (pc-delta-block-full mrs))
      (cons 2 (! (pc-delta-block-full mrs))))
    (list
      (cons 1 (pc-delta-block-full mrs))
      (cons 2 (! (pc-delta-block-full mrs))))
    (list
      (cons 1 (pc-delta-block-full mrs))
      (cons 2 (! (pc-delta-block-full mrs))))
    (list
      (cons 1 (pc-delta-block-full mrs))
      (cons 2 (! (pc-delta-block-full mrs))))
    (list
      (cons 0 #t))
    (list
      (cons 0 #t))
    (list
      (cons 0 #t))))

(define (cr-partition-write mrs)
  (list
    (list (cons 0 #t))
    (list (cons 0 #t))
    (list (cons 0 #t))))

(define (cr-partition-gc_copy mrs)
  (list
    (list (cons 0 #t))
    (list (cons 0 #t))
    (list (cons 0 #t))))

(define (cr-partition-gc_erase mrs)
  (list
    (list (cons 0 #t))))

(define (cr-partition-recovery mrs)
  (list
    (list (cons 2 #t))
    (list (cons 1 #t))
    (list (cons 1 #t))
    (list (cons 0 #t))
    (list (cons 0 #t))
    (list (cons 0 #t))
    (list (cons 0 #t))
    (list (cons 0 #t))
    (list (cons 0 #t))))

(define (pc-delta-block-full mrs)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active ipa_gc pba_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-mregions mrs))
  (bveq ipa_delta (bv32 PAGES_PER_BLOCK)))

(define (pc-delta-block-not-full mrs)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active ipa_gc pba_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-mregions mrs))
  (! (bveq ipa_delta (bv32 PAGES_PER_BLOCK))))

(define (pc-delta-region-almost-full mrs)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active ipa_gc pba_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-mregions mrs))
  (||
    (bvuge pba_delta (bv32 THRESHOLD_DELTA_WB))
    (&&
      (bveq (bvadd pba_delta (bv32 1)) (bv32 THRESHOLD_DELTA_WB))
      (bveq ipa_delta (bv32 PAGES_PER_BLOCK)))))